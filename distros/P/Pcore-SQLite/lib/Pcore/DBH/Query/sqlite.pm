package Pcore::DBH::Query::sqlite;

use Pcore -class;

extends qw[Pcore::DBH::Query];

has _values => ( is => 'rw', isa => ArrayRef, predicate => 1, init_arg => undef );
has _max_rows_allowed => ( is => 'rw', isa => Int, init_arg => undef );

sub _sql_values {
    my $self    = shift;
    my $args    = shift;
    my $sql_ref = shift;

    my ( $cols, $rows ) = $self->_prepare_values($args);

    my $sql;

    # add columns
    if ( $cols->@* ) {
        $sql .= q[( ] . join( q[, ], map { $self->dbh->quote_id($_) } $cols->@* ) . q[ ) ];
    }

    # add values
    $sql .= 'VALUES ';

    my $total_rows = $rows->@*;

    my $params_in_row = $rows->[0]->@*;

    my $bind;

    if ( $total_rows > 500 || $params_in_row * $total_rows > 999 ) {    # sqlite limits, can't insert in one query
        $self->_values($rows);

        $self->_max_rows_allowed( int 500 / $params_in_row );

        $sql .= '__VALUES__';
    }
    else {
        my $row_values_mask = q[(] . join( q[, ], map {q[?]} ( 0 .. $rows->[0]->$#* ) ) . q[)];

        my $rows_mask = [];

        for my $row ( $rows->@* ) {
            push $bind->@*, $row->@*;

            push $rows_mask->@*, $row_values_mask;
        }

        $sql .= join q[, ], $rows_mask->@*;
    }

    $sql_ref->$* =~ s/VALUES.*\z/$sql/smi;

    return ( undef, $bind );
}

sub do {    ## no critic qw[Subroutines::ProhibitBuiltinHomonyms]
    my $self = shift;

    if ( $self->_has_values ) {
        my $total_inserted = 0;

        my $sth_cache = {};

        my $row_values_mask = q[(] . join( q[, ], map {q[?]} ( 0 .. $self->_values->[0]->$#* ) ) . q[)];

        while ( my @bind = splice $self->_values->@*, 0, $self->_max_rows_allowed ) {
            my $id = scalar @bind;

            if ( !$sth_cache->{$id} ) {
                my $values_mask = join q[, ], map {$row_values_mask} ( 0 .. $#bind );

                my $sql = $self->sql =~ s/__VALUES__/$values_mask/smr;

                $sth_cache->{$id} = $self->{dbh}->{_dbh}->prepare($sql);
            }

            my $sth = $sth_cache->{$id};

            $total_inserted += $sth_cache->{ scalar @bind }->execute( map { $_->@* } @bind );
        }

        return $total_inserted;
    }
    else {
        return $self->_execute_dbi_method( 'do', @_ );
    }
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 10                   | Subroutines::ProhibitUnusedPrivateSubroutines - Private subroutine/method '_sql_values' declared but not used  |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::DBH::Query::sqlite

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut
