package Pcore::Handle::pgsql;

use Pcore -class, -const, -res, -export;
use Pcore::Handle::DBI::Const qw[:CONST];
use Pcore::Util::Scalar qw[is_bool looks_like_number is_plain_arrayref is_blessed_arrayref];
use Pcore::Util::UUID qw[uuid_v1mc_str];
use Pcore::Util::Data qw[to_json];
use Pcore::Util::Hash::HashArray;

with qw[Pcore::Handle::DBI];

our $EXPORT = {
    STATE     => [qw[$STATE_CONNECT $STATE_READY $STATE_BUSY $STATE_ERROR $STATE_CONNECT_ERROR $STATE_REMOVED]],
    TX_STATUS => [qw[$TX_STATUS_IDLE $TX_STATUS_TRANS $TX_STATUS_ERROR]],
};

const our $STATE_CONNECT       => 1;
const our $STATE_READY         => 2;
const our $STATE_BUSY          => 3;
const our $STATE_ERROR         => 4;
const our $STATE_CONNECT_ERROR => 5;
const our $STATE_REMOVED       => 6;

const our $TX_STATUS_IDLE  => 'I';    # idle (not in a transaction block)
const our $TX_STATUS_TRANS => 'T';    # in a transaction block
const our $TX_STATUS_ERROR => 'E';    # in a failed transaction block (queries will be rejected until block is ended)

require Pcore::Handle::pgsql::DBH;

has max_dbh         => 3;             # PositiveInt
has backlog         => 1_000;         # Maybe [PositiveInt]
has on_notification => ();            # CodeRef->( $self, $pid, $channel, $payload )

has is_pgsql   => 1, init_arg => undef;
has active_dbh => 0, init_arg => undef;
has _dbh_pool      => sub { Pcore::Util::Hash::HashArray->new }, init_arg => undef;
has _get_dbh_queue => sub { [] }, init_arg => undef;                                  # ArrayRef

# DBH POOL METHODS
sub get_dbh ( $self ) {
    my $dbh = pop $self->{_dbh_pool}->@*;

    return res(200), $dbh if defined $dbh;

    # backlog is full
    if ( $self->{backlog} && $self->{_get_dbh_queue}->@* > $self->{backlog} ) {
        warn 'DBI: backlog queue is full';

        return res [ 500, 'backlog queue is full' ];
    }

    my $cv = P->cv;

    # push callback to the backlog queue
    push $self->{_get_dbh_queue}->@*, $cv;

    # create dbh if limit is not reached
    $self->_create_dbh if $self->{active_dbh} < $self->{max_dbh};

    # block thread
    return $cv->recv;
}

sub push_dbh ( $self, $dbh ) {
    my $state = $dbh->{state};

    # handle is already removed
    return if $state == $STATE_REMOVED;

    if ( $state >= $STATE_ERROR ) {
        $dbh->{state} = $STATE_REMOVED;

        delete $self->{_dbh_pool}->{ $dbh->{id} };

        $self->{active_dbh}--;

        if ( $state == $STATE_CONNECT_ERROR ) {
            while ( my $cb = shift $self->{_get_dbh_queue}->@* ) {
                $cb->( $dbh->{error_status} );
            }
        }
    }

    # dbh is ready for query
    elsif ( $state == $STATE_READY && $dbh->{tx_status} eq $TX_STATUS_IDLE ) {
        if ( my $cb = shift $self->{_get_dbh_queue}->@* ) {
            $cb->( res(200), $dbh );
        }
        else {
            $self->{_dbh_pool}->{ $dbh->{id} } = $dbh;
        }

    }

    # dbh is not ready or in the transaction state
    else {
        $dbh->_on_fatal_error(q[DBH is not ready for query or is in the transaction state (you need to finish transaction)]);

        return;
    }

    return;
}

sub _create_dbh ($self) {
    $self->{active_dbh}++;

    Pcore::Handle::pgsql::DBH->new( pool => $self, );

    return;
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

    # perl Array -> encode to postgres array
    elsif ( is_plain_arrayref $var) {

        # encode and quote
        $var = $self->encode_array($var);

        $var->$* =~ s/'/''/smg;

        return q['] . $var->$* . q['];
    }

    # known boolean objects
    elsif ( is_bool $var ) {
        return $var ? 'TRUE' : 'FALSE';
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
    return \to_json $var;
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

# DBI METHODS
for my $method (qw[do selectall selectall_arrayref selectrow selectrow_arrayref selectcol]) {
    *$method = eval <<"PERL";    ## no critic qw[BuiltinFunctions::ProhibitStringyEval]
        sub ( \$self, \@args ) {
            my ( \$res, \$dbh ) = \$self->get_dbh;

            if ( !\$res ) {
                return \$res;
            }
            else {
                return \$dbh->$method(\@args);
            }
        }
PERL
}

sub in_transaction ($self) {
    return 0;
}

1;
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
