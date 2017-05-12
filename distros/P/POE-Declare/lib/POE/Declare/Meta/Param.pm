package POE::Declare::Meta::Param;

=pod

=head1 NAME

POE::Declare::Meta::Param - A named attribute passed to the constructor
as a parameter.

=head1 DESCRIPTION

B<POE::Declare::Meta::Param> is a sub-class of
L<POE::Declare::Meta::Attribute>. It defines an attribute for which the
initial value will be passed by name to the constructor.

The declaration does not concern itself with issues of type or
whether the param is required. These types of issues are left as a concern
for the implementation.

After the object has been created, the parameter will be read-only.

Any values that should be controllable after object creation should be
changed via a custom method or event that understands the statefulness of
the object, and will make the actual change to the attribute at the correct
time, and in the correct manner.

By default, every class is assigned a default C<Alias> parameter.

This parameter represents the name of the object, which should be unique at
a process level for the duration of the entire process and persist across
multiple starting and stopping of the object (if it supports stopping and
restarting).

By default, each object is assigned a name based on the class and an
incrementing number. A typical Alias might be "Class::Name.123".

If you wish to override this with your own name for an object, you are free
to do so.

=cut

use 5.008007;
use strict;
use warnings;
use POE::Declare::Meta::Attribute ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.59';
	@ISA     = 'POE::Declare::Meta::Attribute';
}

1;

=pod

=head1 SUPPORT

Bugs should be always be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Declare>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<POE>, L<POE::Declare>

=head1 COPYRIGHT

Copyright 2006 - 2012 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
