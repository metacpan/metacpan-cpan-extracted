package Mouse::Meta::Attribute::Custom::Trait::Code;

use strict;

sub register_implementation { 'MouseX::NativeTraits::CodeRef' }

1;
__END__

=head1 NAME

Mouse::Meta::Attribute::Custom::Trait::Code - Shortcut for CodeRef trait

=head1 DESCRIPTION

This module is an alias to MouseX::NativeTraits::CodeRef, which allows
you to refer the trait as C<Code>.

=head1 SEE ALSO

L<MouseX::NativeTraits::CodeRef>

L<MouseX::NativeTraits>

=cut
