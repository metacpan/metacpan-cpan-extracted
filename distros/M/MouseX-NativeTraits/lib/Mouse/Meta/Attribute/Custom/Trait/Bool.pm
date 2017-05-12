package Mouse::Meta::Attribute::Custom::Trait::Bool;

use strict;

sub register_implementation { 'MouseX::NativeTraits::Bool' }

1;
__END__

=head1 NAME

Mouse::Meta::Attribute::Custom::Trait::Bool - Shortcut for Bool trait

=head1 DESCRIPTION

This module is an alias to MouseX::NativeTraits::Bool, which allows
you to refer the trait as C<Bool>.

=head1 SEE ALSO

L<MouseX::NativeTraits::BoolRef>

L<MouseX::NativeTraits>

=cut
