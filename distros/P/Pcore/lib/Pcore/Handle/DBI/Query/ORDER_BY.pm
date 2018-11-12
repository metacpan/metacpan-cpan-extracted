package Pcore::Handle::DBI::Query::ORDER_BY;

use Pcore -const, -class;
use Pcore::Util::Scalar qw[is_ref is_plain_arrayref];

has _buf => ( required => 1 );    # ArrayRef

const our $SQL_SORT_ORDER => {
    asc  => 'ASC',
    desc => 'DESC',
};

sub get_query ( $self, $dbh, $final, $i ) {
    my @sql;

    for my $token ( $self->{_buf}->@* ) {

        # skip undefined values
        next if !defined $token;

        # Scalar value is processed as SQL
        if ( !is_ref $token) {
            push @sql, $dbh->quote_id($token);
        }

        # ArrayRef value is processed as [$field, $order]
        elsif ( is_plain_arrayref $token) {
            my $sort_order = $SQL_SORT_ORDER->{ lc $token->[1] } or die qq[SQL sort order "$token->[1]" is invalid];

            push @sql, $dbh->quote_id( $token->[0] ) . q[ ] . $sort_order;
        }
        else {
            die 'Unsupported ref type';
        }
    }

    return @sql ? ( 'ORDER BY ' . join( q[, ], @sql ), undef ) : ( undef, undef );
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Handle::DBI::Query::ORDER_BY

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
