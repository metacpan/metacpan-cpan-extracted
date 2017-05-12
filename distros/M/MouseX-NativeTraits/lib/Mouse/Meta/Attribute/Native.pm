package Mouse::Meta::Attribute::Native;
use strict;

our $VERSION = '1.09';

1;
__END__

=head1 NAME

Mouse::Meta::Attribute::Native - Extend your attribute interfaces

=head1 SYNOPSIS

    # In your Makefile.PL
    # you can say:
    requires 'Mouse::Meta::Attribute::Native';
    # just like as 'Moose::Meta::Attribute::Native'

=head1 DESCRIPTION

This module is just a hook to set C<Mouse::Meta::Attribute::Native> to
prerequisites.

=head1 SEE ALSO

L<MouseX::NativeTraits>

L<Moose::Meta::Attribute::Native>

=cut
