package POE::Declare::Meta::Slot;

=pod

=head1 NAME

POE::Declare::Meta::Slot - Abstract base class for named class elements

=head1 DESCRIPTION

In L<POE::Declare>, each class is a simple controlled structure with a set
of named elements within it, known as "slots".

Each slot uniquely occupies a name (just like in a HASH) except that in the
L<POE::Declare> model, that name is reserved across all resources (the
method name, the HASH key, and in some cases certain method names below the
root name as well).

For example, a slot named "foo" of type C<Param> will consume the HASH key
"foo", have an accessor method "foo", and take a "foo" parameter in the 
object constructor.

A slot named "mytimeout" filled with a C<Timeout> will consume the
"mytimeout" HASH key, and may have methods such as C<mytimeout_alarm>,
C<mytimeout_keepalive> and C<mytimeout_clear>.

=head1 METHODS

=head2 new

  # You cannot create a Slot directly
  my $object = POE::Declare::Meta::Attribute->new(
      name => 'foo',
  );

The default slot constructor takes a list of named parameters, and creates
a C<HASH>-based object using them. The default implementation does not
check its parameters, as it expects them to be provided by other functions
which themselves will have already checked params.

=cut

use 5.008007;
use strict;
use warnings;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.59';
}

use Class::XSAccessor {
	constructor => 'new',
	getters     => {
		name => 'name',
	},
};

# By default, a slot contains nothing
sub as_perl { '' }

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
