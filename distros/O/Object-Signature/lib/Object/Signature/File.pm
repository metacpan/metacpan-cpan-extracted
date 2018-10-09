package Object::Signature::File;

use strict;
use warnings;

our $VERSION = '1.08';
use base 'Object::Signature';


#####################################################################
# Main Methods

sub signature_ext {
	undef;
}

sub signature_name {
	undef;
}

1;

__END__

=pod

=head1 NAME

Object::Signature::File - Extended signature API for storing objects in file

=head1 DESCRIPTION

Whereas the basic L<Object::Signature> class provides for only a raw
cryptographic signature, B<Object::Signature::File> extends the
signature method to add specialised information for objects that want
some control over how they are stored as files.

For example, some objects may want the cached object to have a matching
file extension (for example a gif image) so that web-accessible cache
path could be used in a web page.

The image would then be sent out to the browser with the correct mime
type.

=head1 METHODS

=head2 signature_ext

The C<signature_ext> method indicates the preferable file extension
for the content of the object, if applicable.

If the method returns a string, it indicates the object should be stored
in a file with a specific extension.

If the method returns a null string, it indicates that the file should
be stored with no extension.

If the method return C<undef> (the default value), it indicates no
preference for the extension of the file.

=head2 signature_name

This B<signature_name> method is the least-useful part of this extended
API, and is rarely used. It is included mostly for completeness.

If the method returns a string, it indicates the name part of a file
name that the object should be stored in, if possible.

If the method return a null string, it explicitly indicates there is
no file name or a file name is not possible.

If the method returns C<undef> (the default value), it indicates no
preference for the name of the file.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2004 - 2007 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
