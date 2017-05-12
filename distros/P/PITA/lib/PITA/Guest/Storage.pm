package PITA::Guest::Storage;

=pod

=head1 NAME

PITA::Guest::Storage - Guest Storage Engine base class

=head1 DESCRIPTION

Looking after Guest images is a full time job.

And so L<PITA::Guest::Storage> provides a dedicated API for locating,
verifying, storing, managing and serving the many gigabytes worth of
image data that is typically stored in a Guest image library.

=head1 METHODS

=cut

use 5.008;
use strict;
use Carp         ();
use Data::GUID   ();
use Params::Util ();

our $VERSION = '0.60';





#####################################################################
# Constructor and Accessors

=pod

=head2 new

  my $store = My::Storage->new(
  	param1 => 'value1',
  	param2 => 'value2',
  	paramN => 'valueN',
  	);

The C<new> constructor (regardless of the subclass) takes a set of
key/value params and returns a new B<PITA::Guest::Storage> object.

Note the B<PITA::Guest::Storage> class itself cannot be instantiated
directly. You can only create objects of subclasses.

Returns a new B<PITA::Guest::Storage> object, or throws an exception
on error.

=cut

sub new {
	my $class = shift;
	if ( $class eq __PACKAGE__ ) {
		Carp::croak('Cannot instantiate PITA::Guest::Storage directly');
	}
	return bless { @_ }, $class;
}





#####################################################################
# Guest Management

=pod

=head2 add_guest

  $store->add_guest( $pita_xml_guest );

The C<add_guest> method takes a single L<PITA::XML::Guest> object, does
significant testing to validate that the guest object is actually a valid
testing guest image, probes it to determine the testing platforms within
the guest image, and then adds it to the Guest Storage.

As you can imagine, the C<add_guest> method may take some time to run.

Returns the modified, fully resolved, version of the L<PITA::XML::Guest>
object if the guest is ok and was added, or throws an exception on error.

=cut

sub add_guest {
	my $self  = shift;
	my $guest = Params::Util::_INSTANCE(shift, 'PITA::XML::Guest')
		or Carp::croak('Did not provide a PITA::XML::Guest to add_guest');
	Carp::croak( ref($self) . ' has not implemented the add_guest method' );
}

=pod

=head2 guest

  my $guest = $store->guest( $guid );

The C<guest> method takes a GUID param, locates and returns the Guest
image metadata for the GUID.

Returns a L<PITA::XML::Guest> if found, false if the GUID does not exist
in the Guest storage, or throws an exception on error.

=cut

sub guest {
	my $self = shift;
	my $guid  = _GUID(shift)
		or Carp::croak('Did not provide a GUID to guest');
	Carp::croak( ref($self) . ' has not implemented the guest method' );
}

=pod

=head2 guests

The C<guests> method returns the Guest image metadata for all of the
Guest images in the Guest Storage object.

Returns a list of L<PITA::XML::Guest> objects, or throws an exception
on error.

=cut

sub guests {
	my $self = shift;
	Carp::croak( ref($self) . ' has not implemented the guests method' );
}

=pod

=head2 platform

  my $platform = $self->platform( $guid );

The C<platform> method locates a single testing L<PITA::XML::Platform>
within some guest, within the Guest Storage.

Returns a L<PITA::XML::Platform> object, false if the GUID does not exist
in the storage, or throws an exception on error.

=cut

sub platform {
	my $self = shift;
	my $id   = shift;
	my @plat = grep { $_->id eq $id } $self->platforms;
	if ( @plat == 1 ) {
		return $plat[0];
	}
	if ( @plat ) {
		Carp::croak("Fond more than 1 platform with id $id");
	}
	return '';
}

=pod

=head2 platforms

The C<platforms> method returns the Testing Platform metadata for all
of the platforms in the Guest Storage.

Returns a list of L<PITA::XML::Platform> objects, or throws an exception
on error.

=cut

sub platforms {
	map { $_->platforms } $_[0]->guests;
}





#####################################################################
# Support Methods

sub _GUID {
	my $guid = eval {
		Data::GUID->from_any_string(shift);
	};
	$@ ? undef : $guid;
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PITA>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<PITA>, L<http://ali.as/pita/>

=head1 COPYRIGHT

Copyright 2005 - 2011 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
