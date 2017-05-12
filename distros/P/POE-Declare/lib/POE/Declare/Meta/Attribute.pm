package POE::Declare::Meta::Attribute;

=pod

=head1 NAME

POE::Declare::Meta::Attribute - Named accessor with read-only accessor

=head1 SYNOPSIS

  declare status => 'Attribute';
  
  my $object = My::Class->new;
  
  print $object->status . "\n";

=head1 DESCRIPTION

A B<POE::Declare::Meta::Attribute> is a L<POE::Declare::Meta::Slot> subclass
that represents the simplest possible slot, a named attribute with a data
storage element in the object HASH, and a readonly accessor.

These methods are intended for use outside of the object, allowing parents
and others to read publically visible state advertised by the object.

=cut

use 5.008007;
use strict;
use warnings;
use POE::Declare::Meta::Slot ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.59';
	@ISA     = 'POE::Declare::Meta::Slot';
}





#####################################################################
# Main Methods

sub as_perl { <<"END_PERL" }
use Class::XSAccessor {
	getters => {
		$_[0]->{name} => '$_[0]->{name}',
	},
};
END_PERL

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
