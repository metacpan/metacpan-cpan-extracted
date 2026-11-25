package Mistyped;

# POD that disagrees with its subs, for t/Pod-Coverage-More.t to read the failures back from.

use 5.036;
use warnings FATAL => q{all};

=head1 FUNCTIONS

=head2 wrong_type(count,label)

=over 4

=item count - HASH - the sub takes one value

=item label - STRING

=back

=cut

sub wrong_type {
    my ( $count, $label ) = @_;
    return "$label: $count";
}

=head2 untyped(size)

=over 4

=item size - how big it is, with no type

=back

=cut

sub untyped {
    my ($size) = @_;
    return $size;
}

=head2 missing_item(first,second)

=over 4

=item first - SCALAR

=back

=cut

sub missing_item {
    my ( $first, $second ) = @_;
    return $first . $second;
}

=head2 wrong_sigil(@items)

=cut

sub wrong_sigil {
    my ($items) = @_;
    return $items;
}

=head2 wrong_name(colour)

=cut

sub wrong_name {
    my ($color) = @_;
    return $color;
}

1;
