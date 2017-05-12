package PITA::Guest::Storage::Simple;

=pod

=head1 NAME

PITA::Guest::Storage::Simple - A (relatively) simple Guest Storage object

=head1 DESCRIPTION

The L<PITA::Guest::Storage> class provides an API for cataloguing and
retrieving Guest images, with all the data stored on the filesystem using
the native XML file formats.

B<PITA::Guest::Storage::Simple> implements a very simple version of
the L<PITA::Guest::Storage> API.

Guest image location and searching is done the long way, with no indexing.

=head1 METHODS

=cut

use 5.008;
use strict;
use Carp                 ();
use File::Spec           ();
use File::Path           ();
use Params::Util         ();
use Data::GUID           ();
use PITA::XML::Guest     ();
use PITA::Guest::Storage ();

our $VERSION  = '0.60';
our @ISA      = 'PITA::Guest::Storage';
our $LOCKFILE = 'PITA-Guest-Storage-Simple.lock';





#####################################################################
# Constructor and Accessors

=pod

=head2 new

  my $store = PITA::Guest::Storage::Simple->new(
  	storage_dir => '/var/PITA-Guest-Storable-Simple',
  	);

The C<new> method creates a new simple storage object. It takes a single
named param

Returns a C<PITA::Guest::Storage::Simple> object, or throws an exception
on error.

=cut

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);

	# Check params
	unless ( $self->storage_dir and -d $self->storage_dir and -w _ ) {
		Carp::croak('The storage_dir is not a writable directory');
	}

	$self;
}

=pod

=head2 storage_dir

The C<storage_dir> accessor returns the location of the directory that
serves as the root of the data store.

=cut

sub storage_dir {
	$_[0]->{storage_dir};
}





#####################################################################
# PITA::Guest::Storage::Simple Methods

=pod

=head2 create

  my $store = PITA::Guest::Storage::Simple->new(
  	storage_dir => '/var/PITA-Guest-Storable-Simple',
  	);

The C<create> constructor creates a new C<PITA::Guest::Storage::Simple>
repository.

=cut

sub create {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# The storage_dir should not exist, we will create it
	my $storage_dir = $self->storage_dir;
	unless ( $storage_dir ) { 
		Carp::croak("The storage_dir param was not provided");
	}
	if ( -d $storage_dir ) {
		Carp::croak("The storage_dir '$storage_dir' already exists");
	}
	eval { File::Path::mkpath( $storage_dir, 1, 0711 ) };
	if ( $@ ) {
		Carp::croak("Failed to create the storage_dir '$storage_dir': $@");
	}

	$self;
}

=pod

=head2 storage_lock

The C<storage_lock> method takes a lock on the C<storage_lock> file,
creating it if needed (in the C<create> method case).

It does not wait to take the lock, failing immediately if the lock
cannot be taken.

Returns true if the lock is taken, false if the lock cannot be taken,
or throws an exception on error.

=cut

sub storage_lock {
	return 1 if $^O eq 'MSWin32';

	# Only lock on Unix
	require File::Flock;
	File::Flock->new(
		File::Spec->catfile( $_[0]->storage_dir, $LOCKFILE ),
	);
}





#####################################################################
# PITA::Guest::Storage Methods

sub add_guest {
	my $self = shift;
	my $xml  = Params::Util::_INSTANCE(shift, 'PITA::XML::Guest')
		or Carp::croak('Did not provide a PITA::XML::Guest to add_guest');

	# Is the driver available for this guest
	unless ( $xml->driver_available ) {
		Carp::croak("The guest driver " . $xml->driver . " is not available");
	}

	# Does the guest have a guid...
	$xml->set_id( Data::GUID->new->as_string ) unless $xml->id;

	# Does the GUID match an existing one
	if ( $self->guest( $xml->id ) ) {
		Carp::croak("The guest " . $xml->id . " already exists");
	}

	# Load a full PITA::Guest object from the file
	my $guest = PITA::Guest->new( $xml )
		or die "Failed to load PITA::Guest";

	# Can we ping the guest
	unless ( $guest->ping ) {
		Carp::croak("Ping failed, not a valid guest image");
	}

	# Run discovery if needed
	unless ( $guest->discovered ) {
		$guest->discover or Carp::croak("Failed to discover platforms in guest");
	}

	# Store the guest
	my $lock = $self->storage_lock;
	my $file = File::Spec->catfile( $self->storage_dir, $xml->id . '.pita' );
	$xml->write($file) or Carp::croak("Failed to save guest XML file");

	return $xml;
}

# Each guest has a matching directory name
sub guest {
	my $self = shift;
	my $id   = shift;

	# Find the file
	my $file = $self->guest_file($id);
	unless ( -f $file ) {
		return undef;
	}

	# Load the guest metadata object
	my $guest = PITA::XML::Guest->read($file);
	unless ( $guest->id ) {
		Carp::croak("Guest id mismatch for $file");
	}

	return $guest;
}

sub guest_exists {
	-f shift->guest_file(shift);
}

sub guest_file {
	File::Spec->catfile(
		$_[0]->storage_dir, "$_[1].pita",
	);
}

sub guests {
	my $self = shift;

	# Find all *.pita files in the storage directory
	opendir( STORAGE, $self->storage_dir ) or Carp::croak("opendir: $!");
	my @files = readdir(STORAGE)           or Carp::croak("readdir: $!");
	closedir( STORAGE )                    or Carp::croak("closedir: $!");

	# Load and check the metadata files
	my @guests = ();
	foreach my $file ( @files ) {
		# Filter out unwanted things
		next if $file =~ /^\./;
		next unless -f $file;
		next unless $file =~ /^(.+)\.pita$/;

		# Load the object
		my $id    = $1;
		my $path  = File::Spec->catfile( $self->storage_dir, $file );
		my $guest = PITA::XML::Guest->read( $path );
		unless ( $guest->id eq $id ) {
			Carp::croak("Guest id mismatch for $path");
		}

		push @guests, $guest;
	}

	return @guests;
}

sub platform {
	my $self = shift;
	die 'CODE INCOMPLETE';
}

sub platforms {
	my $self = shift;
	die 'CODE INCOMPLETE';
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

L<PITA::Guest::Storage>, L<PITA>, L<http://ali.as/pita/>

=head1 COPYRIGHT

Copyright 2005 - 2011 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
