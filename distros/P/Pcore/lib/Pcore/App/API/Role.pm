package Pcore::App::API::Role;

use Pcore -role, -const;
use Pcore::Util::Scalar qw[is_plain_arrayref];

requires qw[_build_api_map];

has app => ( is => 'ro', isa => ConsumerOf ['Pcore::App'], required => 1 );

has api_map => ( is => 'lazy', isa => HashRef, init_arg => undef );

const our $SQL_FILTER_OPERATOR => {
    '<'     => '<',
    '<='    => '<=',
    '='     => '=',
    '>='    => '>=',
    '>'     => '>',
    '!='    => '!=',
    'in'    => 'IN',
    'notin' => 'NOT IN',
    'like'  => 'LIKE',
};

const our $SQL_SORT_ORDER => {
    'asc'  => 'ASC',
    'desc' => 'DESC',
};

sub _create_sql_filter ( $self, $dbh, $filter ) {
    return if !exists $SQL_FILTER_OPERATOR->{ lc $filter->[1] };

    my $op = $SQL_FILTER_OPERATOR->{ lc $filter->[1] };

    my $sql = $dbh->quote_id( $filter->[0] ) . ' ' . $op . ' ';
    my $bind;

    if ( $op eq 'IN' || $op eq 'NOT IN' ) {
        if ( is_plain_arrayref $filter->[2] ) {
            $sql = '(' . join( ', ', ('?') x $filter->[2]->@* ) . ')';

            $bind = $filter->[2];
        }
        else {
            $sql = '(?)';

            push $bind->@*, $filter->[2];
        }
    }
    else {
        $sql .= '?';

        push $bind->@*, $filter->[2];
    }

    return $sql, $bind;
}

sub _create_sql_order ( $self, $dbh, $order ) {
    my @order;

    for my $sort ( $order->@* ) {
        return if !exists $SQL_SORT_ORDER->{ lc $sort->[1] };

        push @order, $dbh->quote_id( $sort->[0] ) . ' ' . $SQL_SORT_ORDER->{ lc $sort->[1] };
    }

    return 'ORDER BY ' . join q[, ], @order;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 |                      | Subroutines::ProhibitUnusedPrivateSubroutines                                                                  |
## |      | 29                   | * Private subroutine/method '_create_sql_filter' declared but not used                                         |
## |      | 58                   | * Private subroutine/method '_create_sql_order' declared but not used                                          |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 34, 64               | ValuesAndExpressions::ProhibitEmptyQuotes - Quotes used with a string containing no non-whitespace characters  |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::App::API::Role

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
