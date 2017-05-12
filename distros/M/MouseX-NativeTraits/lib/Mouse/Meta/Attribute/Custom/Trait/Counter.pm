package Mouse::Meta::Attribute::Custom::Trait::Counter;

use strict;

sub register_implementation { 'MouseX::NativeTraits::Counter' }

1;
__END__

=head1 NAME

Mouse::Meta::Attribute::Custom::Trait::Counter - Shortcut for Counter trait

=head1 DESCRIPTION

This module is an alias to MouseX::NativeTraits::Counter, which allows
you to refer the trait as C<Counter>.

=head1 SEE ALSO

L<MouseX::NativeTraits::Counter>

L<MouseX::NativeTraits>

=cut
