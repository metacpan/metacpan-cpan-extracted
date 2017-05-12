package PITA::Guest::Driver::Local;

=pod

=head1 NAME

PITA::Guest::Driver::Local - PITA Guest Driver for Local images

=head1 DESCRIPTION

The author is an idiot

=cut

use 5.006;
use strict;
use version             ();
use Carp                ();
use File::Spec          ();
use File::Copy          ();
use File::Temp          ();
use File::Which         ();
use Data::GUID          ();
use Storable            ();
use Params::Util        ();
use PITA::XML           ();
use PITA::Scheme        ();
use PITA::Guest::Driver ();

our $VERSION = '0.60';
our @ISA     = 'PITA::Guest::Driver';

# SHOULD be tested, but recheck on load
my $workarea = File::Spec->tmpdir;
unless ( -d $workarea and -r _ and -w _ ) {
	Carp::croak('Workarea does no exist or insufficient permissions');
}





#####################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);

	# Get ourselves a fresh tmp directory for the scheme workarea
	unless ( $self->workarea ) {
		$self->{workarea} = File::Temp::tempdir();
	}
	unless ( -d $self->workarea and -w _ ) {
		die("Working directory " . $self->workarea . " is not writable");
	}

	### Not used, for now
	# Locate the perl binary
	$self->{local_bin} = File::Which::which('perl') unless $self->local_bin;
	unless ( $self->local_bin ) {
		Carp::croak("Cannot locate perl, requires explicit param");
	}
	unless ( -x $self->local_bin ) {
		Carp::croak("Insufficient permissions to run perl");
	}

	# Find the install perl version
	my $local_bin = $self->local_bin;
	my $lines = `$local_bin -v`;
	unless ( $lines =~ /^This is perl[^\n]+v([\d\.]+)[^\n]+built for/m ) {
		Carp::croak("Failed to locate Perl version");
	}
	$self->{local_version} = version->new("$1");

	# Check the local version
	unless ( $self->local_version >= version->new('5.6.1') ) {
		Carp::croak("Currently only supports perl 5.6.1 or newer");
	}

	$self;
}

# Scheme workarea
sub workarea {
	$_[0]->{workarea};
}

sub local_bin {
	$_[0]->{local_bin};
}

sub local_version {
	$_[0]->{local_version};
}





#####################################################################
# PITA::Guest::Driver Main Methods

# We are running now, of course we are here
sub ping {
	1;
}

# Only implements the current Perl
sub discover {
	my $self = shift;
	$self->guest->discovered and return 1;
	$self->guest->add_platform(
		PITA::XML::Platform->autodetect_perl5,
	);
}

# Execute a test
sub test {
	my $self    = shift;
	my $request = $self->_REQUEST(shift)
		or Carp::croak('Did not provide a request');
	my $platform = Params::Util::_INSTANCE(shift, 'PITA::XML::Platform')
		or Carp::croak('Did not provide a platform');

	# Set the tarball filename to be relative to current
	my $file         = $request->file;
	my $filename     = File::Basename::basename( $file->filename );
	my $tarball_from = $file->filename;
	my $tarball_to   = File::Spec->catfile(
		$self->injector_dir, $filename,
	);
	$request = Storable::dclone( $request );
	$request->file->{filename} = $filename;

	# Copy the tarball into the injector
	unless ( File::Copy::copy( $tarball_from, $tarball_to ) ) {
		Carp::croak("Failed to copy in test package: $!");
	}

	# Create the testing scheme
	my $driver = PITA::Scheme->_DRIVER($request->scheme);
	my $scheme = $driver->new(
		injector   => $self->injector_dir,
		workarea   => $self->workarea,
		scheme     => $request->scheme,
		path       => $platform->path,
		request    => $request,
		request_id => 1234,
	);

	# Execute the testing scheme
	$scheme->prepare_all;
	$scheme->execute_all;
	unless ( $scheme->report ) {
		Carp::croak('Executing test scheme failed to generate a report');
	}

	$scheme->report;
}





#####################################################################
# Support Methods

sub DESTROY {
	$_[0]->SUPER::DESTROY();
	if ( $_[0]->{workarea} and -d $_[0]->{workarea} ) {
		File::Remove::remove( \1, $_[0]->{workarea} );
	}
}

1;
