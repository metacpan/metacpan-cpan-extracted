package Pcore::Handle::pgsql;

use Pcore -class, -const, -res, -export;
use Pcore::Handle::DBI::Const qw[:CONST];
use Pcore::Util::Scalar qw[looks_like_number is_plain_arrayref is_blessed_arrayref is_plain_coderef];
use Pcore::Util::UUID qw[uuid_v1mc_str];
use Pcore::Util::Data qw[to_json];

with qw[Pcore::Handle::DBI];

our $EXPORT = {
    STATE     => [qw[$STATE_CONNECT $STATE_READY $STATE_BUSY $STATE_DISCONNECTED]],
    TX_STATUS => [qw[$TX_STATUS_IDLE $TX_STATUS_TRANS $TX_STATUS_ERROR]],
};

const our $STATE_CONNECT      => 1;
const our $STATE_READY        => 2;
const our $STATE_BUSY         => 3;
const our $STATE_DISCONNECTED => 4;

const our $TX_STATUS_IDLE  => 'I';    # idle (not in a transaction block)
const our $TX_STATUS_TRANS => 'T';    # in a transaction block
const our $TX_STATUS_ERROR => 'E';    # in a failed transaction block (queries will be rejected until block is ended)

require Pcore::Handle::pgsql::DBH;

has max_dbh  => 3;                    # PositiveInt
has backlog  => 1_000;                # Maybe [PositiveInt]
has host     => ( is => 'lazy' );     # Str
has port     => 5432;                 # PositiveOrZeroInt
has username => ( is => 'lazy' );     # Str
has password => ( is => 'lazy' );     # Str
has database => ( is => 'lazy' );     # Str

has is_pgsql   => 1, init_arg => undef;
has active_dbh => 0, init_arg => undef;
has _dbh_pool      => ( init_arg => undef );            # ArrayRef
has _get_dbh_queue => sub { [] }, init_arg => undef;    # ArrayRef

sub _build_host ($self) {
    return $self->{uri}->{path} eq '/' ? "$self->{uri}->{host}" : "$self->{uri}->{path}";
}

sub _build_username ($self) {
    return $self->{uri}->{username};
}

sub _build_password ($self) {
    return $self->{uri}->{password} // $EMPTY;
}

sub _build_database ($self) {
    return $self->{uri}->query_params->{db};
}

# DBH POOL METHODS
sub _create_dbh ($self) {
    $self->{active_dbh}++;

    Pcore::Handle::pgsql::DBH->connect(
        handle     => $self,
        on_connect => sub ( $dbh, $res ) {
            if ( !$res ) {
                $self->{active_dbh}--;

                # throw connection error for all pending requests
                while ( my $cb = shift $self->{_get_dbh_queue}->@* ) {
                    $cb->( $res, undef );
                }
            }
            else {
                $self->{on_connect}->($dbh) if $self->{on_connect};

                $self->push_dbh($dbh);
            }

            return;
        }
    );

    return;
}

sub _get_dbh ( $self, $cb ) {
    while ( my $dbh = shift $self->{_dbh_pool}->@* ) {
        if ( $dbh->{state} == $STATE_READY && $dbh->{tx_status} eq $TX_STATUS_IDLE ) {
            $cb->( res(200), $dbh );

            return;
        }
        else {
            $self->{active_dbh}--;
        }
    }

    if ( $self->{backlog} && $self->{_get_dbh_queue}->@* > $self->{backlog} ) {
        warn 'DBI: backlog queue is full';

        $cb->( res( [ 500, 'backlog queue is full' ] ), undef );

        return;
    }

    push $self->{_get_dbh_queue}->@*, $cb;

    $self->_create_dbh if $self->{active_dbh} < $self->{max_dbh};

    return;
}

sub push_dbh ( $self, $dbh ) {

    # dbh is ready for query
    if ( $dbh->{state} == $STATE_READY && $dbh->{tx_status} eq $TX_STATUS_IDLE ) {
        if ( my $cb = shift $self->{_get_dbh_queue}->@* ) {
            $cb->( res(200), $dbh );
        }
        else {
            push $self->{_dbh_pool}->@*, $dbh;
        }

    }

    # dbh is disconnected or in transaction state
    else {
        $self->{active_dbh}--;

        $self->_create_dbh if $self->{_get_dbh_queue}->@* && $self->{active_dbh} < $self->{max_dbh};
    }

    return;
}

# STH
sub prepare ( $self, $query ) {
    utf8::encode $query if utf8::is_utf8 $query;

    # convert "?" placeholders to "$1" style
    if ( index( $query, '?' ) != -1 ) {
        my $i;

        $query =~ s/[?]/'$' . ++$i/smge;
    }

    my $sth = bless {
        id    => uuid_v1mc_str,
        query => $query,
      },
      'Pcore::Handle::DBI::STH';

    return $sth;
}

# SCHEMA PATCH
sub _get_schema_patch_table_query ( $self, $table_name ) {
    return <<"SQL";
        CREATE TABLE IF NOT EXISTS "$table_name" (
            "id" INT NOT NULL,
            "timestamp" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
            PRIMARY KEY ("id")
        )
SQL
}

# QUOTE
sub quote ( $self, $var ) {
    return 'NULL' if !defined $var;

    if ( is_blessed_arrayref $var) {
        return 'NULL' if !defined $var->[1];

        # https://www.postgresql.org/docs/current/static/datatype-binary.html
        if ( $var->[0] == $SQL_BYTEA ) {
            $var = $var->[1];

            # encode
            utf8::encode $var if utf8::is_utf8 $var;

            # quote
            $var = q[E'\\\\x] . unpack( 'H*', $var ) . q['];

            return $var;
        }
        elsif ( $var->[0] == $SQL_BOOL ) {
            return $var->[1] ? q['1'] : q['0'];
        }
        elsif ( $var->[0] == $SQL_UUID ) {
            $var = $var->[1];

            # encode
            utf8::encode $var if utf8::is_utf8 $var;

            # escape
            $var =~ s/'/''/smg;

            # quote
            return qq['$var'];
        }
        elsif ( $var->[0] == $SQL_JSON ) {

            # encode and quote
            $var = $self->encode_json( $var->[1] );

            $var->$* =~ s/'/''/smg;

            return q['] . $var->$* . q['];
        }
        else {
            die 'Unsupported SQL type';
        }
    }
    elsif ( is_plain_arrayref $var) {

        # encode and quote
        $var = $self->encode_array($var);

        $var->$* =~ s/'/''/smg;

        return q['] . $var->$* . q['];
    }

    # NUMBER
    # elsif ( looks_like_number $var) {
    #     return $var;
    # }

    # TEXT
    else {

        # encode
        utf8::encode $var if utf8::is_utf8 $var;

        # escape
        $var =~ s/'/''/smg;

        # quote
        return qq['$var'];
    }
}

sub encode_json ( $self, $var ) {

    # encode
    return to_json $var;
}

sub encode_array ( $self, $var ) {
    my @buf;

    for my $el ( $var->@* ) {
        if ( is_plain_arrayref $el) {
            push @buf, $self->encode_array($el)->$*;
        }
        else {

            # copy and escape
            my $var = $el =~ s/"/\\"/smgr;

            # quote
            push @buf, qq["$var"];
        }
    }

    return \( '{' . join( q[,], @buf ) . '}' );
}

sub dbh ($self) {
    my $cv = P->cv;

    $self->_get_dbh($cv);

    return $cv->recv;
}

# DBI METHODS
for my $method (qw[do selectall selectall_arrayref selectrow selectrow_arrayref selectcol]) {
    *$method = eval <<"PERL";    ## no critic qw[BuiltinFunctions::ProhibitStringyEval]
        sub ( \$self, \@args ) {
            my \$cb = is_plain_coderef \$args[-1] ? \$args[-1] : undef;

            if ( defined wantarray ) {
                my ( \$res, \$dbh ) = \$self->dbh;

                if ( !\$res ) {
                    return \$cb ? \$cb->(\$res) : \$res;
                }
                else {
                    return \$dbh->$method(\@args);
                }
            }
            else {
                \$self->_get_dbh(
                    sub ( \$res, \$dbh ) {
                        if ( !\$res ) {
                            \$cb->( \$res ) if \$cb;
                        }
                        else {
                            \$dbh->$method(\@args);
                        }

                        return;
                    }
                );

                return;
            }
        }
PERL
}

# TRANSACTIONS
sub begin_work ( $self, @args ) {
    my $cb = is_plain_coderef $args[-1] ? $args[-1] : undef;

    if ( defined wantarray ) {
        my ( $res, $dbh ) = $self->dbh;

        if ( !$res ) {
            return $cb ? $cb->($res) : $res;
        }
        else {
            return $dbh->begin_work(@args);
        }
    }
    else {
        $self->_get_dbh(
            sub ( $res, $dbh ) {
                if ( !$res ) {
                    $cb->( undef, $res ) if $cb;
                }
                else {
                    $dbh->begin_work(@args);
                }

                return;
            }
        );

        return;
    }
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 155                  | Subroutines::ProhibitUnusedPrivateSubroutines - Private subroutine/method '_get_schema_patch_table_query'      |
## |      |                      | declared but not used                                                                                          |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Handle::pgsql

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
