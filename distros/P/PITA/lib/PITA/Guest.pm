package PITA::Guest;

=pod

=head1 NAME

PITA::Guest - The PITA Guest abstract, a container for running tests

=head1 DESCRIPTION

All testing is run inside a Guest, a container object usually involving
a system image and a configuration.

This class implements the Guest abstraction.

=head1 METHODS

=cut

use 5.008;
use strict;
use Process        ();
use File::Spec     ();
use File::Basename ();
use Params::Util   ();
use PITA::XML      ();

our $VERSION = '0.60';
our @ISA     = 'Process';





#####################################################################
# Constructors

=pod

=head2 new

  $guest = PITA::Guest->new( 'guest-51231.pita' );
  $guest = PITA::Guest->new( \$file_content     );
  $guest = PITA::Guest->new( $guest_xml_object  );

The C<new> constructor creates a new B<PITA::Guest> object from an XML
description. It takes a single param of either a L<PITA::XML::Guest>
object, a string which is the name of a PITA file containing the XML
description, or a SCALAR reference (which may be a constant SCALAR ref)
containing the XML.

Returns a new C<PITA::Guest> object, or dies on error.

=cut

sub new {
	my $class = shift;

	# Handle the param
	my $file      = undef;
	my $guest_xml = undef;
	if ( Params::Util::_INSTANCE($_[0], 'PITA::XML::Guest') ) {
		$guest_xml = shift;

	} elsif ( Params::Util::_STRING($_[0]) ) {
		$file = shift;
		unless ( -f $file ) {
			Carp::croak('Did not provide a valid filename');
		}
		$guest_xml = PITA::XML::Guest->read($file);

	} else {
		Carp::croak("Invalid param provided to PITA::Guest::new");
	}

	# Create the object
	my $self = bless {
		file     => $file,
		guestxml => $guest_xml,
		driver   => undef,
	}, $class;

	# If and only if the Guest has an image, save its absolute path
	if ( $self->guestxml->files ) {
		my $filexml  = ($self->guestxml->files)[0];
		my $filename = $filexml->filename;
		if ( File::Spec->file_name_is_absolute( $filename ) ) {
			$self->{absimage} = $filename;
		} elsif ( defined $file ) {
			$filename = File::Spec->catfile(
				File::Basename::dirname($file),
				$filename,
			);
			unless ( File::Spec->file_name_is_absolute( $filename ) ){
				$filename = File::Spec->rel2abs( $filename );
			}
			$self->{absimage} = $filename;
		} elsif ( defined $guest_xml->base ) {
			$filename = File::Spec->catfile(
				$guest_xml->base,
				$filename,
			);
			unless ( File::Spec->file_name_is_absolute( $filename ) ){
				$filename = File::Spec->rel2abs( $filename );
			}
			$self->{absimage} = $filename;
		} else {
			die "Unable to locate image file for guest";
		}
	}

	# Create the driver
	my $driver = 'PITA::Guest::Driver::' . $self->guestxml->driver;
	eval "require $driver"; die $@ if $@;
	my %params = ( guest => $self->guestxml );
	if ( $self->{absimage} ) {
		$params{absimage} = $self->{absimage};
	}
	if ( $self->{minicpan} ) {
		$params{minicpan} = $self->{minicpan};
	}
	if ( $driver->isa('PITA::Guest::Driver::Image') ) {
		$params{support_server_addr} = '127.0.0.1';
		$params{support_server_port} = 12345;
	}
	$self->{driver} = $driver->new( %params );

	$self;
}





#####################################################################
# Accessors

=pod

=head2 file

The C<file> accessor returns the name of the file the Guest object was
created from.

=cut

sub file {
	$_[0]->{file};
}

=pod

=head2 guestxml

The L<PITA::XML> file loads to a L<PITA::XML::Guest> object which is
held internally.

The C<guestxml> accessor returns the L<PITA::XML::Guest> object.

=cut

sub guestxml {
	$_[0]->{guestxml};
}

=pod

=head2 discovered

The C<discovered> method returns true if the Guest has gone through the
discovery process that identifies testing platforms in the Guest, or false
if not.

=cut

sub discovered {
	$_[0]->guestxml->discovered;
}

=pod

=head2 driver

The C<driver> method returns the L<PITA::Driver> object within the
L<PITA::Guest> that the tests are run through.

=cut

sub driver {
	$_[0]->{driver};
}





#####################################################################
# Main Methods

=pod

=head2 ping

All guests are required to identify themselves.

The C<ping> method is dispatched to the driver and does whatever is
necesary to determine if the guest is live (and actually a
C<PITA::Guest>)

Returns true (may take up to 5 minutes) or false if not.

=cut

sub ping {
	$_[0]->driver->ping;
}

=pod

=head2 discover

Most often the detailed of a Guest are provided without identifying
what is set up inside them.

The C<discover> method is dispatched to the driver, loading the Guest
and interrogating it to determine the testing platforms available from
it.

Returns true (may take up to 5 minutes) if the testing platforms are
correctly discovered, or dies if not.

=cut

sub discover {
	$_[0]->driver->discover;
}

=pod

=head2 test

  $response = $guest->test( 'request.pita' );

The C<test> method executes a single testing request.

It takes as argument the name of a L<PITA::XML> file with a
E<lt>requestE<gt> at the root. Loads the request and dispatches
it to the driver, which will load the Guest, inject the test
request and package, and then hand back the response once it is
completed.

Depending on the package, this could take from minutes to hours to
run.

Returns a L<PITA::XML::Report> object, or dies on error.

=cut

sub test {
	my $self     = shift;
	my $filename = Params::Util::_STRING(shift);
	unless ( $filename and -f $filename and -r _ ) {
		Carp::croak('Did not provide a request file');
	}

	# Load the request object
	my $request = PITA::XML::Request->read($filename);
	unless ( $request ) {
		Carp::croak('Failed to load request file');
	}

	# Locate the archive file, converting the request
	# filename to absolute if needed.
	### FIXME: If the <filename> tag can contain anything
	###        other than a raw filename, this code is not
	###        portable, and needs improving to split the
	###        <filename> first before appending.
	my $archive = File::Basename::dirname($filename);
	$archive = File::Spec->catfile( $archive, $request->file->filename );
	unless ( $archive and -f $archive and -r _ ) {
		Carp::croak('Failed to find archive, or insufficient permissions');
	}
	unless ( File::Spec->file_name_is_absolute( $archive ) ) {
		$archive = File::Spec->rel2abs( $archive );
	}
	$request->file->{filename} = $archive;

	# Just use the first platform until we write a selection method
	my $platform = ($self->guestxml->platforms)[0];
	unless ( Params::Util::_INSTANCE($platform, 'PITA::XML::Platform') ) {
		Carp::croak('Could not autoselect a platform');
	}

	# Hand off the testing request to the driver
	$self->driver->test( $request, $platform );
}

=pod

=head2 save

The L<PITA::Guest> object remembers the name of the file it was loaded from.

If you run C<discover>, then afterwards your can run C<save> to save the
now-discovered Guest back to a file.

Returns true or dies on error.

=cut

sub save {
	my $self = shift;
	unless ( defined $self->file ) {
		Carp::croak("No file to save to");
	}
	$self->guestxml->write( $self->file );
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

The Practical Image Testing Architecture (L<http://ali.as/pita/>)

L<PITA::XML>, L<PITA::Scheme>

=head1 COPYRIGHT

Copyright 2005 - 2011 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
