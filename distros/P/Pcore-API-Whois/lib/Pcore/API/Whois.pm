package Pcore::API::Whois v0.5.4;

use Pcore -dist, -class;
use Pcore::API::Whois::Server;
use Pcore::API::Whois::Response qw[:CONST];
use Net::Whois::Raw::Data qw[];

has cfg           => ( is => 'lazy', isa => HashRef );
has proxy_pool    => ( is => 'ro',   isa => InstanceOf ['Pcore::API::ProxyPool'] );
has cache         => ( is => 'ro',   isa => Str );                                     # path to whois cache db
has cache_timeout => ( is => 'ro',   isa => PositiveInt, default => 60 * 60 * 24 );    # in seconds

has dbh => ( is => 'lazy', isa => Maybe [ InstanceOf ['Pcore::Handle::sqlite'] ], init_arg => undef );

sub _build_cfg ($self) {
    my $cfg;

    my $db = P->cfg->load( $ENV->share->get('/data/whois.perl') );

    # pub. suffix server
    for my $pub_suffix ( keys %Net::Whois::Raw::Data::servers ) {
        $cfg->{pub_suffix_server}->{ lc $pub_suffix } = $Net::Whois::Raw::Data::servers{$pub_suffix};
    }

    for my $pub_suffix ( keys $db->{pub_suffix_server}->%* ) {
        if ( !$db->{pub_suffix_server}->{$pub_suffix} ) {
            delete $cfg->{pub_suffix_server}->{ P->host($pub_suffix)->name };
        }
        else {
            $cfg->{pub_suffix_server}->{ P->host($pub_suffix)->name } = $db->{pub_suffix_server}->{$pub_suffix};
        }
    }

    # whois server
    for my $server ( values $cfg->{pub_suffix_server}->%* ) {
        next if exists $cfg->{server}->{$server};

        # query
        $cfg->{server}->{$server}->{query} = $db->{server_query}->{$server} // ( $Net::Whois::Raw::Data::query_prefix{$server} ? $Net::Whois::Raw::Data::query_prefix{$server} . '<: $DOMAIN :>' . $CRLF : undef ) // '<: $DOMAIN :>' . $CRLF;

        # exceed
        $cfg->{server}->{$server}->{exceed_re} = $db->{exceed}->{$server} // $Net::Whois::Raw::Data::exceed{$server};

        # not found
        $cfg->{server}->{$server}->{notfound_re} = $db->{notfound}->{$server} // $Net::Whois::Raw::Data::notfound{$server};
    }

    return $cfg;
}

sub _build_dbh ($self) {
    return if !$self->cache;

    my $dbh = P->handle( 'sqlite:' . $self->cache );

    # DDL
    my $ddl = $dbh->ddl;

    $ddl->add_changeset(
        id  => 1,
        sql => <<'SQL'
                CREATE TABLE IF NOT EXISTS `whois` (
                    `domain` TEXT PRIMARY KEY NOT NULL,
                    `last_checked` INTEGER NULL,
                    `status` INTEGER NOT NULL
                );

                CREATE INDEX IF NOT EXISTS `idx_whois_domain_last_checked` ON `whois` (`domain` ASC, `last_checked` ASC);
SQL
    );

    $ddl->upgrade;

    return $dbh;
}

sub search ( $self, $domain, $cb = undef ) {
    my $blocking_cv = defined wantarray ? AE::cv : undef;

    state $q1 = $self->cache ? $self->dbh->query('SELECT status FROM whois WHERE domain = ? AND last_checked > ?') : undef;

    my @label = split /[.]/sm, P->host($domain)->canon;

    my $query;    # domain ascii

    my $server_host;

    my $cfg = $self->cfg;

    my $pub_suffixes = Pcore::Util::URI::Host->pub_suffixes;

    my $response;

    $response = sub ( $query, $status, $is_cached = 0 ) {
        my $res = Pcore::API::Whois::Response->new(
            {   query     => $query,
                is_cached => $is_cached,
                status    => $status,
                reason    => $Pcore::API::Whois::Response::STATUS_REASON->{$status},
            }
        );

        $cb->($res) if $cb;

        $blocking_cv->($res) if $blocking_cv;

        undef $response;

        return;
    };

    # determine whois query and server
    if ( @label == 1 ) {

        # TLD is always found
        $response->( $label[-1], $WHOIS_FOUND );
    }
    elsif ( @label == 2 ) {
        if ( exists $pub_suffixes->{"$label[-2].$label[-1]"} ) {

            # pub. suffix is always found
            $response->( "$label[-2].$label[-1]", $WHOIS_FOUND );
        }
        else {

            # 1-labels server is exists, use 2-labels as query
            if ( exists $cfg->{pub_suffix_server}->{ $label[-1] } ) {
                $server_host = $cfg->{pub_suffix_server}->{ $label[-1] };

                $query = "$label[-2].$label[-1]";
            }
            else {
                $response->( "$label[-2].$label[-1]", $WHOIS_NOT_SUPPORTED );
            }
        }
    }
    else {
        if ( exists $pub_suffixes->{"$label[-3].$label[-2].$label[-1]"} ) {

            # pub. suffix is always found
            $response->( "$label[-3].$label[-2].$label[-1]", $WHOIS_FOUND );
        }
        else {

            # 2-labels server is exists
            if ( exists $cfg->{pub_suffix_server}->{"$label[-2].$label[-1]"} ) {
                $server_host = $cfg->{pub_suffix_server}->{"$label[-2].$label[-1]"};

                $query = "$label[-3].$label[-2].$label[-1]";
            }

            # 1-labels server is exists
            elsif ( exists $cfg->{pub_suffix_server}->{ $label[-1] } ) {
                $server_host = $cfg->{pub_suffix_server}->{ $label[-1] };

                if ( exists $pub_suffixes->{"$label[-2].$label[-1]"} ) {

                    # 2-labels is pub. suffix, use 3-labels as query
                    $query = "$label[-3].$label[-2].$label[-1]";
                }
                else {

                    # 2-labels is NOT pub. suffix, use 2-labels as query
                    $query = "$label[-2].$label[-1]";
                }
            }
            else {
                $response->( "$label[-3].$label[-2].$label[-1]", $WHOIS_NOT_SUPPORTED );
            }
        }
    }

    if ($response) {
        if ( !$server_host ) {
            $response->( $query, $WHOIS_NOT_SUPPORTED );
        }
        else {
            if ( !$cfg->{server}->{$server_host}->{notfound_re} ) {

                # server is not configured
                $response->( $query, $WHOIS_NOT_SUPPORTED );
            }
            elsif ( $self->cache && ( my $status = $q1->selectval( [ $query, time - $self->cache_timeout ] ) ) ) {

                # return cached response
                $response->( $query, $status->$*, 1 );
            }
            else {
                Pcore::API::Whois::Server->new(
                    {   host        => $server_host,
                        proxy_pool  => $self->proxy_pool,
                        query       => $cfg->{server}->{$server_host}->{query},
                        exceed_re   => $cfg->{server}->{$server_host}->{exceed_re},
                        notfound_re => $cfg->{server}->{$server_host}->{notfound_re},
                        cb          => sub($server) {
                            if ( !$server ) {

                                # server is not resolved
                                $response->( $query, $WHOIS_NOT_SUPPORTED );
                            }
                            else {

                                # perform whois request
                                $self->_request(
                                    $server, $query,
                                    sub ($res) {
                                        $cb->($res) if $cb;

                                        $blocking_cv->($res) if $blocking_cv;

                                        return;
                                    }
                                );
                            }

                            return;
                        }
                    }
                );
            }
        }
    }

    return $blocking_cv ? $blocking_cv->recv : ();
}

sub _request ( $self, $server, $query, $cb ) {
    state $q1 = $self->cache ? $self->dbh->query('INSERT OR IGNORE INTO whois (last_checked, status, domain) VALUES (?, ?, ?)') : undef;

    state $q2 = $self->cache ? $self->dbh->query('UPDATE whois SET last_checked = ?, status = ? WHERE domain = ?') : undef;

    state $pool = {};

    push $pool->{$query}->@*, $cb;

    return if $pool->{$query}->@* > 1;

    $server->request(
        $query,
        sub ($res) {
            if ( $res->status == 200 ) {
                my $recognized;

                if ( my $re = $server->exceed_re ) {
                    if ( $res->content->$* =~ $re ) {
                        $recognized = 1;

                        $res->set_status( $WHOIS_BANNED, $Pcore::API::Whois::Response::STATUS_REASON->{$WHOIS_BANNED} );
                    }
                }

                if ( !$recognized && ( my $re = $server->notfound_re ) ) {
                    if ( $res->content->$* =~ $re ) {
                        $recognized = 1;

                        $res->set_status( $WHOIS_NOT_FOUND, $Pcore::API::Whois::Response::STATUS_REASON->{$WHOIS_NOT_FOUND} );
                    }
                }

                # cache results for successful query
                $q1->do( [ time, $res->status, $query ] ) || $q2->do( [ time, $res->status, $query ] ) if $self->cache && $res->is_success;
            }

            while ( my $cb = shift $pool->{$query}->@* ) {
                $cb->($res);
            }

            delete $pool->{$query};

            return;
        }
    );

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 77                   | Subroutines::ProhibitExcessComplexity - Subroutine "search" with high complexity score (31)                    |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 39                   | ValuesAndExpressions::RequireInterpolationOfMetachars - String *may* require interpolation                     |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::Whois

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=head1 AUTHOR

zdm <zdm@softvisio.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by zdm.

=cut
