package Mouse::Meta::Attribute::Custom::Trait::Array;

use strict;

sub register_implementation { 'MouseX::NativeTraits::ArrayRef' }

1;
__END__

=head1 NAME

Mouse::Meta::Attribute::Custom::Trait::Array - Shortcut for ArrayRef trait

=head1 DESCRIPTION

This module is an alias to MouseX::NativeTraits::ArrayRef, which allows
you to refer the trait as C<Array>.

=head1 SEE ALSO

L<MouseX::NativeTraits::ArrayRef>

L<MouseX::NativeTraits>

=cut
