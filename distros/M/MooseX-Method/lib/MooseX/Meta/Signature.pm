package MooseX::Meta::Signature;

use Moose::Role;

requires qw/validate/;

our $VERSION = '0.01';

our $AUTHORITY = 'cpan:BERLE';

1;

__END__

=pod

=head1 NAME

MooseX::Meta::Signature - Signature API role

=head1 WARNING

This API is unstable, it may change at any time. This should not
affect ordinary L<MooseX::Method> usage.

=head1 DESCRIPTION

Ensures that the class importing the role conforms to the
MooseX::Method signature API.

=head1 BUGS

Most software has bugs. This module probably isn't an exception.
If you find a bug please either email me, or add the bug to cpan-RT.

=head1 AUTHOR

Anders Nor Berle E<lt>debolaz@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 by Anders Nor Berle.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

