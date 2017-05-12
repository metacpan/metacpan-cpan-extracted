package Mouse::Meta::Attribute::Custom::Trait::Number;

use strict;

sub register_implementation { 'MouseX::NativeTraits::Num' }

1;
__END__

=head1 NAME

Mouse::Meta::Attribute::Custom::Trait::Number - Shortcut for Number trait

=head1 DESCRIPTION

This module is an alias to MouseX::NativeTraits::Number, which allows
you to refer the trait as C<Number>.

=head1 SEE ALSO

L<MouseX::NativeTraits::Number>

L<MouseX::NativeTraits>

=cut
