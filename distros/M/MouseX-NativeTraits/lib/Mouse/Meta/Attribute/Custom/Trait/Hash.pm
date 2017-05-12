package Mouse::Meta::Attribute::Custom::Trait::Hash;

use strict;

sub register_implementation { 'MouseX::NativeTraits::HashRef' }

1;
__END__

=head1 NAME

Mouse::Meta::Attribute::Custom::Trait::Hash - Shortcut for HashRef trait

=head1 DESCRIPTION

This module is an alias to MouseX::NativeTraits::HashRef, which allows
you to refer the trait as C<Hash>.

=head1 SEE ALSO

L<MouseX::NativeTraits::HashRef>

L<MouseX::NativeTraits>

=cut
