package Pcore::DBH::SQLite;

use Pcore -class;
use DBD::SQLite;

with qw[Pcore::DBH::DBI];

has '+_dbh' => ( is => 'ro', isa => InstanceOf ['DBI::db'], required => 1, init_arg => '_dbh' );
has _parent_dbh => ( is => 'ro', isa => InstanceOf ['Pcore::Handle::sqlite'], required => 1 );

sub DEMOLISH ( $self, $global ) {
    if ( !$global ) {
        $self->{_parent_dbh}->push_dbh($self);
    }

    return;
}

sub dbh ($self) {
    return $self;
}

sub attach ( $self, $name, $path = undef ) {
    $path //= ':memory:';

    $self->do(qq[ATTACH DATABASE '$path' AS `$name`]);

    $self->do(qq[PRAGMA $name.encoding = "UTF-8"]);
    $self->do( qq[PRAGMA $name.temp_store = ] . $self->{_parent_dbh}->temp_store );
    $self->do( qq[PRAGMA $name.journal_mode = ] . $self->{_parent_dbh}->journal_mode );
    $self->do( qq[PRAGMA $name.synchronous = ] . $self->{_parent_dbh}->synchronous );
    $self->do( qq[PRAGMA $name.cache_size = ] . $self->{_parent_dbh}->cache_size );
    $self->do( qq[PRAGMA $name.foreign_keys = ] . $self->{_parent_dbh}->foreign_keys );

    return;
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
## |    3 | 38                   | Subroutines::ProhibitExcessComplexity - Subroutine "do" with high complexity score (25)                        |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 88                   | Subroutines::ProtectPrivateSubs - Private subroutine/method used                                               |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::DBH::SQLite

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
