package Pcore::API::Whois::Server;

use Pcore -class;
use Pcore::API::Whois::Response qw[:CONST];
use Pcore::AE::Handle;
use Pcore::Util::Text qw[decode_eol];
use Net::Whois::Raw::Data qw[];

has host  => ( is => 'ro', isa => Str, required => 1 );
has query => ( is => 'ro', isa => Str, required => 1 );
has exceed_re   => ( is => 'ro', isa => Maybe [RegexpRef], required => 1 );
has notfound_re => ( is => 'ro', isa => Maybe [RegexpRef], required => 1 );

has proxy_pool => ( is => 'ro', isa => Maybe [ InstanceOf ['Pcore::API::ProxyPool'] ] );
has max_threads => ( is => 'ro', isa => PositiveInt, default => 1 );

has id => ( is => 'ro', isa => Str, init_arg => undef );

has _threads => ( is => 'ro', isa => PositiveOrZeroInt, default => 0, init_arg => undef );
has _pool => ( is => 'ro', isa => ArrayRef, default => sub { [] }, init_arg => undef );

our $CACHE_TIMEOUT = 60 * 60;    # 1 hour

our $CACHE_DOMAIN;

our $CACHE_ID;

around new => sub ( $orig, $self, $args ) {
    if ( $CACHE_DOMAIN->{ $args->{host} } && $CACHE_DOMAIN->{ $args->{host} }->[0] + $CACHE_TIMEOUT < time ) {

        # cache is expired
        delete $CACHE_DOMAIN->{ $args->{host} };
    }

    if ( $CACHE_DOMAIN->{ $args->{host} } ) {

        # return cached object
        $args->{cb}->( $CACHE_ID->{ $CACHE_DOMAIN->{ $args->{host} }->[1] } );
    }
    else {
        state $dns_req_cache = {};

        push $dns_req_cache->{ $args->{host} }->@*, $args;

        return if $dns_req_cache->{ $args->{host} }->@* > 1;

        # get server id - first sorted ipv4 addr
        AnyEvent::DNS::a $args->{host}, sub {
            my $server;

            if (@_) {
                my $id = ( sort @_ )[0];

                $CACHE_DOMAIN->{ $args->{host} } = [ time, $id ];

                if ( !$CACHE_ID->{$id} ) {
                    $args->{exceed_re} = qr/$args->{exceed_re}/sm if $args->{exceed_re};

                    $args->{notfound_re} = qr/$args->{notfound_re}/sm if $args->{notfound_re};

                    my $obj = $self->$orig($args);

                    $obj->{id} = $id;

                    $CACHE_ID->{$id} = $obj;
                }

                $server = $CACHE_ID->{$id};
            }

            while ( my $req = shift $dns_req_cache->{ $args->{host} }->@* ) {
                $req->{cb}->($server);
            }

            delete $dns_req_cache->{ $args->{host} };

            return;
        };
    }

    return;
};

sub request ( $self, $domain_ascii, @ ) {
    if ( $self->{_threads} >= $self->max_threads ) {
        push $self->{_pool}->@*, [ splice @_, 1 ];

        return;
    }

    my %args = (
        timeout => 10,
        splice @_, 2, -1
    );

    my $cb = $_[-1];

    $self->{_threads}++;

    my $start = sub($proxy) {
        Pcore::AE::Handle->new(
            connect         => [ $self->host, 43,     'whois' ],
            connect_timeout => $args{timeout},
            timeout         => $args{timeout},
            persistent      => 0,
            proxy           => $proxy,
            on_error        => sub ( $h,      $fatal, $reason ) {
                $h->destroy;

                $self->{_threads}--;

                # start cached threads
                while ( $self->{_threads} < $self->max_threads ) {
                    if ( my $req = shift $self->{_pool}->@* ) {
                        $self->request( $req->@* );
                    }
                    else {
                        last;
                    }
                }

                $cb->(
                    Pcore::API::Whois::Response->new(
                        {   server => $self,
                            query  => $domain_ascii,
                            status => $WHOIS_NETWORK_ERROR,
                            reason => $reason,
                        }
                    )
                );

                return;
            },
            on_connect => sub ( $h, $host, $port, $retry ) {
                $h->push_write( $self->query =~ s/<: \$DOMAIN :>/$domain_ascii/smr );

                # read all data until server close socket
                $h->read_eof(
                    sub ( $h, $buf_ref, $total_bytes_readed, $error ) {
                        $h->destroy;

                        $self->{_threads}--;

                        # start cached threads
                        while ( $self->{_threads} < $self->max_threads ) {
                            if ( my $req = shift $self->{_pool}->@* ) {
                                $self->request( $req->@* );
                            }
                            else {
                                last;
                            }
                        }

                        my $res;

                        # empty content = network error
                        if ( !defined $buf_ref->$* ) {
                            $res = Pcore::API::Whois::Response->new(
                                {   server => $self,
                                    query  => $domain_ascii,
                                    status => $WHOIS_NO_CONTENT,
                                    reason => $Pcore::API::Whois::Response::STATUS_REASON->{$WHOIS_NO_CONTENT},
                                }
                            );
                        }
                        else {
                            decode_eol( $buf_ref->$* );

                            $res = Pcore::API::Whois::Response->new(
                                {   server  => $self,
                                    query   => $domain_ascii,
                                    status  => 200,
                                    content => $buf_ref
                                }
                            );
                        }

                        $cb->($res);

                        return;
                    }
                );

                return;
            }
        );

        return;
    };

    if ( $self->proxy_pool ) {
        $self->proxy_pool->get_slot( [ 'whois://', 43 ], $start );
    }
    else {
        $start->(undef);
    }

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    1 | 91                   | CodeLayout::RequireTrailingCommas - List declaration without trailing comma                                    |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::Whois::Server

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
