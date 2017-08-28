package Pcore::Handle::pgsql;

use Pcore -class, -const, -result, -sql,
  -export => {
    STATE     => [qw[$STATE_CONNECT $STATE_READY $STATE_BUSY $STATE_DISCONNECTED]],
    TX_STATUS => [qw[$TX_STATUS_IDLE $TX_STATUS_TRANS $TX_STATUS_ERROR]],
  };
use Pcore::Util::Scalar qw[looks_like_number is_plain_arrayref];
use Pcore::Util::UUID qw[uuid_str];

with qw[Pcore::Handle::DBI];

const our $STATE_CONNECT      => 1;
const our $STATE_READY        => 2;
const our $STATE_BUSY         => 3;
const our $STATE_DISCONNECTED => 4;

const our $TX_STATUS_IDLE  => 'I';    # idle (not in a transaction block)
const our $TX_STATUS_TRANS => 'T';    # in a transaction block
const our $TX_STATUS_ERROR => 'E';    # in a failed transaction block (queries will be rejected until block is ended)

require Pcore::PgSQL::DBH;

has max_dbh => ( is => 'ro', isa => PositiveInt, default => 3 );
has backlog => ( is => 'ro', isa => Maybe [PositiveInt], default => 1_000 );
has host     => ( is => 'lazy', isa => Str );
has port     => ( is => 'ro',   isa => PositiveOrZeroInt, default => 5432 );
has username => ( is => 'lazy', isa => Str );
has password => ( is => 'lazy', isa => Str );
has database => ( is => 'lazy', isa => Str );

has is_pgsql   => ( is => 'ro', isa => Bool, default => 1, init_arg => undef );
has active_dbh => ( is => 'ro', isa => Int,  default => 0, init_arg => undef );
has _dbh_pool => ( is => 'ro', isa => ArrayRef, init_arg => undef );
has _get_dbh_queue => ( is => 'ro', isa => ArrayRef, default => sub { [] }, init_arg => undef );

sub _build_host ($self) {
    return $self->{uri}->path eq q[/] ? q[] . $self->{uri}->host : q[] . $self->{uri}->path;
}

sub _build_username ($self) {
    return $self->{uri}->username;
}

sub _build_password ($self) {
    return $self->{uri}->password // q[];
}

sub _build_database ($self) {
    return $self->{uri}->query_params->{db};
}

# DBH POOL METHODS
sub _create_dbh ($self) {
    $self->{active_dbh}++;

    Pcore::PgSQL::DBH->connect(
        handle     => $self,
        on_connect => sub ( $dbh, $status ) {
            if ( !$status ) {
                $self->{active_dbh}--;

                # throw connection error for all pending requests
                while ( my $cb = shift $self->{_get_dbh_queue}->@* ) {
                    $cb->( $status, undef );
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
            $cb->( $dbh, result 200 );

            return;
        }
        else {
            $self->{active_dbh}--;
        }
    }

    if ( $self->{backlog} && $self->{_get_dbh_queue}->@* > $self->{backlog} ) {
        warn 'DBI: backlog queue is full';

        $cb->( undef, result [ 500, 'backlog queue is full' ] );

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
            $cb->( $dbh, result 200 );
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
        id    => uuid_str,
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
sub quote ( $self, $var, $type = undef ) {
    return 'NULL' if !defined $var;

    if ( defined $type ) {

        # https://www.postgresql.org/docs/current/static/datatype-binary.html
        if ( $type == $SQL_BYTEA ) {
            utf8::encode $var if utf8::is_utf8 $var;

            $var = q[E'\\\\x] . unpack( 'H*', $var ) . q['];

            return $var;
        }
        else {
            die 'Unsupported SQL type';
        }
    }

    # elsif ( looks_like_number $var) {
    #     return $var;
    # }
    elsif ( is_plain_arrayref $var) {
        my @els;

        for my $el ( $var->@* ) {
            push @els, $self->quote( $el, $type );
        }

        return 'ARRAY[' . join( ', ', @els ) . ']';
    }
    else {
        utf8::encode $var if utf8::is_utf8 $var;

        $var =~ s/'/''/smg;

        return qq['$var'];
    }
}

# DBI METHODS
for my $method (qw[do selectall selectall_arrayref selectrow selectrow_arrayref selectcol]) {
    eval <<"PERL";    ## no critic qw[BuiltinFunctions::ProhibitStringyEval]
        *$method = sub ( \$self, \@args ) {
            \$self->_get_dbh(
                sub ( \$dbh, \$status ) {
                    if (!\$status) {
                        \$args[-1]->( undef, \$status, undef );
                    }
                    else {
                        \$dbh->$method(\@args);
                    }

                    return;
                }
            );

            return;
        }
PERL
}

# TRANSACTIONS
for my $method (qw[begin_work commit rollback]) {
    eval <<"PERL";    ## no critic qw[BuiltinFunctions::ProhibitStringyEval]
        *$method = sub ( \$self, \@args ) {
            \$self->_get_dbh(
                sub ( \$dbh, \$status ) {
                    if (!\$status) {
                        \$args[-1]->( undef, \$status );
                    }
                    else {
                        \$dbh->$method(\@args);
                    }

                    return;
                }
            );

            return;
        }
PERL
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 |                      | Subroutines::ProhibitUnusedPrivateSubroutines                                                                  |
## |      | 81                   | * Private subroutine/method '_get_dbh' declared but not used                                                   |
## |      | 152                  | * Private subroutine/method '_get_schema_patch_table_query' declared but not used                              |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 204, 226             | ErrorHandling::RequireCheckingReturnValueOfEval - Return value of eval not tested                              |
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
