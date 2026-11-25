package FullyDocumented;

# A module whose POD passes every check.

use 5.036;
use warnings FATAL => q{all};

=head1 FUNCTIONS

=head2 double(count)

=over 4

=item count - Num - what to double

=back

Returns Num.

    my $four = FullyDocumented::double(2);

=cut

sub double {
    my ($count) = @_;
    return $count * 2;
}

1;
