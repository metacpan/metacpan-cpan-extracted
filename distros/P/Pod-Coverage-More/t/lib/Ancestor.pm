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

=head2 template_files(@loaded_recipes)

=over 4

=item @loaded_recipes - Str - the recipes that the caller loaded

=back

Returns nothing.

    $object->template_files('mail');

=cut

sub template_files {
    my ( $self, @loaded_recipes ) = @_;
    $self->{recipes} = \@loaded_recipes;
    return;
}

1;
