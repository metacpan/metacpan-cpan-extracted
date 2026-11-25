package Ancestor;

# A class that documents a hook, which Descendant overrides without documenting it again.

use 5.036;
use warnings FATAL => q{all};

=head1 METHODS

=head2 hook(record)

=over 4

=item record - HashRef - what the hook works on

=back

Returns nothing.

    $object->hook( {} );

=cut

sub hook {
    my ( $self, $record ) = @_;
    return;
}

1;
