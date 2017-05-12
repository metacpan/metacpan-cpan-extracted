package Pcore::Handle::sqlite;

use Pcore -class, -const;
use DBD::SQLite;
use DBD::SQLite::Constants qw[:file_open];
use Pcore::DBH::SQLite;

# NOTE http://habrahabr.ru/post/149635/
# для вставки данных в цикле надо использовать h->begin_work ... h->commit

with qw[Pcore::DBH];

const our $SQLITE_OPEN_FLAGS => {
    RO  => SQLITE_OPEN_READONLY | SQLITE_OPEN_SHAREDCACHE,
    RW  => SQLITE_OPEN_READWRITE | SQLITE_OPEN_SHAREDCACHE,
    RWC => SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_SHAREDCACHE,
};

has mode => ( is => 'ro', isa => Enum [ keys $SQLITE_OPEN_FLAGS->%* ], default => 'RWC' );
has busy_timeout => ( is => 'ro', isa => PositiveOrZeroInt, default => 1_000 * 3 );    # milliseconds, set to 0 to disable timeout, default - 3 seconds

# SQLITE PRAGMAS
has temp_store   => ( is => 'ro', isa => Enum [qw[FILE MEMORY]],                            default => 'MEMORY' );
has journal_mode => ( is => 'ro', isa => Enum [qw[DELETE TRUNCATE PERSIST MEMORY WAL OFF]], default => 'WAL' );      # WAL is the best
has synchronous  => ( is => 'ro', isa => Enum [qw[FULL NORMAL OFF]],                        default => 'OFF' );      # OFF - data integrity on app failure, NORMAL - data integrity on app and OS failures, FULL - full data integrity on app or OS failures, slower
has cache_size   => ( is => 'ro', isa => Int,  default => -1_048_576 );                                              # 0+ - pages,  -kilobytes, default 1G
has foreign_keys => ( is => 'ro', isa => Bool, default => 1 );

sub BUILD ( $self, $args ) {
    my $attr = P->hash->merge(
        $self->default_dbi_attr,
        {   sqlite_open_flags                => $SQLITE_OPEN_FLAGS->{ $self->mode },
            sqlite_unicode                   => 1,
            sqlite_allow_multiple_statements => 1,
            sqlite_use_immediate_transaction => 1,
            sqlite_see_if_its_a_number       => 1,
        }
    );

    my $dbname = $self->uri->path->to_string || ':memory:';

    $self->{_dbh} = DBI->connect( "dbi:SQLite:dbname=$dbname", q[], q[], $attr );

    $self->{_dbh}->do('PRAGMA encoding = "UTF-8"');
    $self->{_dbh}->do( 'PRAGMA temp_store = ' . $self->temp_store );
    $self->{_dbh}->do( 'PRAGMA journal_mode = ' . $self->journal_mode );
    $self->{_dbh}->do( 'PRAGMA synchronous = ' . $self->synchronous );
    $self->{_dbh}->do( 'PRAGMA cache_size = ' . $self->cache_size );
    $self->{_dbh}->do( 'PRAGMA foreign_keys = ' . $self->foreign_keys );

    $self->_on_connect($self);

    return;
}

sub _on_connect ( $self, $dbh ) {
    $dbh->{_dbh}->sqlite_busy_timeout( $self->busy_timeout );

    $self->on_connect->($dbh) if $self->on_connect;

    return;
}

sub attach ( $self, $name, $path = undef ) {
    $path //= ':memory:';

    $self->do(qq[ATTACH DATABASE '$path' AS `$name`]);

    $self->do(qq[PRAGMA $name.encoding = "UTF-8"]);
    $self->do( qq[PRAGMA $name.temp_store = ] . $self->temp_store );
    $self->do( qq[PRAGMA $name.journal_mode = ] . $self->journal_mode );
    $self->do( qq[PRAGMA $name.synchronous = ] . $self->synchronous );
    $self->do( qq[PRAGMA $name.cache_size = ] . $self->cache_size );
    $self->do( qq[PRAGMA $name.foreign_keys = ] . $self->foreign_keys );

    return;
}

sub version ($self) {
    return $self->{_dbh}->{sqlite_version};
}

sub do {    ## no critic qw[Subroutines::ProhibitBuiltinHomonyms]
    my ( $self, $query ) = splice @_, 0, 2, ();
    my $bind = ref $_[0] eq 'ARRAY' ? shift : undef;
    my $cb   = ref $_[-1] eq 'CODE' ? pop   : undef;
    my %args = (
        cache => undef,
        @_,
        cb => $cb,
    );

    my $dbh = $self;

    # prepare query
    my $query_ref = ref $query;

    if ( !$query_ref ) {
        $args{cache} //= 0;
    }
    elsif ( $query_ref eq 'ARRAY' ) {
        $args{cache} //= 0;

        $query = $self->query( $query->@* );

        $bind //= $query->bind;
    }
    elsif ( $query_ref eq 'DBI::st' ) {
        $args{cache} //= 0;
    }
    else {

        # query object
        if ( !$bind && $query->bind->@* ) {

            # do not cache query by default, when query bind params are used
            $args{cache} //= 0;

            $bind = $query->bind;
        }
        else {
            $args{cache} //= 1;
        }
    }

    my $rows = 0;

    if ( !$bind ) {

        # execute query directly without prepare and bind params
        my $sql = $query_ref eq 'DBI::st' ? $query->{Statement} : "$query";

        $rows = DBD::SQLite::db::_do( $dbh->{_dbh}, $sql ) or die $dbh->{_dbh}->errstr;

        $rows = 0 if $rows == 0;    # convert "0E0" to "0"
    }
    elsif ( $query_ref eq 'DBI::st' ) {
        my $sth;

        # prepare sth
        if ( $args{cache} ) {
            $sth = $dbh->{_dbh}->prepare_cached( $query->{Statement} );
        }
        else {
            $sth = $query;
        }

        $sth->execute( $bind ? $bind->@* : () ) or die $sth->errstr;

        $rows = $sth->rows;
    }
    else {
        my @copy = $bind->@*;

        my $sql = "$query";

        while ($sql) {
            my $sth;

            # prepare sth
            if ( $args{cache} ) {
                $sth = $dbh->{_dbh}->prepare_cached($sql);
            }
            else {
                $sth = $dbh->{_dbh}->prepare("$sql");
            }

            $sth->execute( splice @copy, 0, $sth->{NUM_OF_PARAMS} ) or die $sth->errstr;

            $rows += $sth->rows;

            $sql = $sth->{sqlite_unprepared_statements};
        }
    }

    $args{cb}->($rows) if $args{cb};

    return $rows;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 83                   | Subroutines::ProhibitExcessComplexity - Subroutine "do" with high complexity score (25)                        |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 133                  | Subroutines::ProtectPrivateSubs - Private subroutine/method used                                               |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Handle::sqlite

=head1 SYNOPSIS

    my $dbh = P->handle(
        "sqlite:db.sqlite",
        max_conn   => 10,
        on_connect => sub ($dbh) {
            $dbh->attach( 'db1', 'db1.sqlite' );

            return;
        }
    );

=head1 DESCRIPTION

=cut
