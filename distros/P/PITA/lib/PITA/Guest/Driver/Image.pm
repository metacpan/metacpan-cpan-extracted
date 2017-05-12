package PITA::Guest::Driver::Image;

# Provides a base class for PITA Guests that are system images.
# For example, Qemu, VMWare, etc

use 5.008;
use strict;
use Carp                         ();
use File::Path                   ();
use File::Temp                   ();
use File::Copy                   ();
use File::Remove                 ();
use File::Basename               ();
use Storable                     ();
use Params::Util                 ();
use Config::Tiny                 ();
use Class::Inspector             ();
use PITA::Guest::Driver          ();
use PITA::Guest::Server::Process ();

our $VERSION = '0.60';
our @ISA     = 'PITA::Guest::Driver';





#####################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);

	# Check we got an image.
	unless ( $self->image ) {
		# Pull the filename from the XML file, mapping it relative
		# to the original filename and saving as an absolute path
		if ( $self->{absimage} ) {
			$self->{image} = delete $self->{absimage};
		} else {
			$self->{image} = ($self->guest->files)[0]->filename;
		}
	}
	unless ( $self->image ) {
		Carp::croak("Did not provide the location of the image_file");
	}
	unless ( -f $self->image and -r _ ) {
		Carp::croak($self->image . ": image does not exist, or cannot be read");
	}

	# How much memory to use
	$self->{memory} = 256 unless $self->memory;
	unless ( Params::Util::_POSINT($self->memory) ) {
		Carp::croak("Invalid memory amount (in meg) '" . $self->memory . "'");
	}

	# Snapshot should be a binary value, defaulting to true.
	# This might not be the most ACCURATE, but by always defaulting
	# to snapshot mode we prevent accidental harm to the image.
	$self->{snapshot} = 1 unless defined $self->snapshot;

	# Unless we have a support server directory, create a new one
	unless ( $self->support_server_dir ) {
		$self->{support_server_dir} = File::Temp::tempdir();
	}

	# Create the support server result files to expect
	$self->{support_server_pinged}   = 0;
	$self->{support_server_mirrored} = [ ];
	$self->{support_server_results}  = [ ];

	$self;
}

sub image {
	$_[0]->{image};
}

sub memory {
	defined $_[0]->{memory}
		? $_[0]->{memory}
		: $_[0]->guest->config->{memory};
}

sub snapshot {
	defined $_[0]->{snapshot}
		? $_[0]->{snapshot}
		: $_[0]->guest->config->{memory};
}

sub support_server {
	$_[0]->{support_server};
}

sub support_server_addr {
	$_[0]->{support_server_addr};
}

sub support_server_port {
	$_[0]->{support_server_port};
}

sub support_server_dir {
	$_[0]->{support_server_dir};
}

sub support_server_pinged {
	$_[0]->{support_server_pinged};
}

sub support_server_mirrored {
	$_[0]->{support_server_mirrored};
}

sub support_server_results {
	$_[0]->{support_server_results};
}

# Provide a default implementation.
# Many subclasses will need to override this though.
sub support_server_uri {
	my $self = shift;
	URI->new( "http://"
		. $self->support_server_addr . ':'
		. $self->support_server_port . '/'
	);
}

sub perl5lib_dir {
	File::Spec->catdir( $_[0]->injector_dir, 'perl5lib' );
}

sub perl5lib_classes { qw{
	PITA::Scheme
	PITA::Scheme::Perl
	PITA::Scheme::Perl5
	PITA::Scheme::Perl5::Make
	PITA::Scheme::Perl5::Build
} }





#####################################################################
# PITA::Guest::Driver Methods

sub ping {
	$_[0]->clean_injector;
	$_[0]->ping_prepare;
	$_[0]->ping_execute;
	$_[0]->ping_cleanup;
	return 1;
}

sub ping_prepare {
	my $self = shift;

	# Generate the image.conf
	$self->prepare_task('ping');

	# Create the support server
	$self->{support_server} = $self->support_server_new;

	return 1;
}

sub ping_execute {
	my $self = shift;

	# By default, launch the support server
	$self->support_server->prepare
	and
	$self->support_server->run
	or
	Carp::croak("Failed to execute support server");

	return 1;
}

sub ping_cleanup {
	my $self = shift;

	# Capture results from the support server
	$self->support_server->finish;
	$self->{support_server_pinged}   = $self->support_server->pinged;
	$self->{support_server_mirrored} = $self->support_server->mirrored;
	$self->{support_server_results}  = $self->support_server->uploaded;

	# Delete the support server
	delete $self->{support_server};

	return 1;
}

sub discover {
	my $self = shift;
	$self->clean_injector;
	$self->discover_prepare;
	$self->discover_execute;
	$self->discover_cleanup;
	return 1;
}

sub discover_prepare {
	my $self = shift;

	# Copy in the perl5lib modules
	$self->prepare_perl5lib;

	# Generate the image.conf
	$self->prepare_task('discover');

	# Create the support server
	$self->{support_server} = $self->support_server_new;

	return 1;
}

sub discover_execute {
	my $self = shift;

	# By default, launch the support server
	$self->support_server->prepare
	and
	$self->support_server->run
	or
	Carp::croak("Failed to execute support server");

	return 1;
}

sub discover_cleanup {
	my $self = shift;

	# Capture results from the support server
	$self->support_server->finish;
	$self->{support_server_pinged}   = $self->support_server->pinged;
	$self->{support_server_mirrored} = $self->support_server->mirrored;
	$self->{support_server_results}  = $self->support_server->uploaded;

	# Get the report file contents
	my $string = $self->support_server->upload('/1');
	unless ( Params::Util::_SCALAR($string) ) {
		die "Discovery report was not uploaded to the support server";
	}

	# Parse into a report
	my $report = PITA::XML::Guest->read($string);
	unless ( $report->platforms ) {
		die "Discovery report did not contain any platforms";
	}

	# Add the detected platforms to the configured guest
	foreach my $platform ( $report->platforms ) {
		$self->guest->add_platform( $platform );
	}

	# Cleanup the support server
	delete $self->{support_server};

	return 1;
}

sub test {
	my $self = shift;
	$self->clean_injector;
	$self->test_prepare(@_);
	$self->test_execute(@_);
	my $report = $self->test_cleanup(@_);
	return $report;
}

sub test_prepare {
	my $self = shift;

	# Copy in the perl5lib modules
	$self->prepare_perl5lib(@_);

	# Generate the scheme.conf into the injector
	$self->prepare_task(@_);

	# Create the support server
	$self->{support_server} = $self->support_server_new;

	return 1;
}

sub test_execute {
	my $self = shift;

	# By default, launch the support server
	$self->support_server->prepare
	and
	$self->support_server->run
	or
	Carp::croak("Failed to execute support server");

	return 1;
}

sub test_cleanup {
	my $self    = shift;
	my $request = shift;

	# Capture results from the support server
	$self->support_server->finish;
	$self->{support_server_pinged}   = $self->support_server->pinged;
	$self->{support_server_mirrored} = $self->support_server->mirrored;
	$self->{support_server_results}  = $self->support_server->uploaded;

	# Get the report
	my $string = $self->support_server->upload('/' . $request->id);
	unless ( $string ) {
		Carp::croak("Failed to get report " . $request->id . " from support server");
	}

	# Parse into a report
	my $report = PITA::XML::Report->read($string);
	unless ( $report ) {
		Carp::croak("Discovery report did not contain any platforms");
	}

	# Cleanup the support server
	delete $self->{support_server};

	# Return the report
	return $report;
}





#####################################################################
# PITA::Guest:Driver::Image Methods

# The command used to execute the guest
sub execute_cmd {
	my $class = ref $_[0] || $_[0];
	die "The guest driver class $class does not implement execute_cmd";
}

sub prepare_task {
	my $self = shift;
	my $task = shift;

	# Create the image.conf config file
	my $image_conf = Config::Tiny->new;
	$image_conf->{_} = {
		class      => 'PITA::Image',
		version    => '0.60',
		server_uri => $self->support_server_uri,
	};
	if ( -d $self->perl5lib_dir ) {
		$image_conf->{_}->{perl5lib} = 'perl5lib';
	}

	# Add the tasks
	if ( Params::Util::_STRING($task) and $task eq 'ping' ) {
		$image_conf->{task} = {
			task   => 'Ping',
			job_id => 1,
		};

	} elsif ( Params::Util::_STRING($task) and $task eq 'discover' ) {
		# Discovery always uses the job_id 1 (for now)
		$image_conf->{task} = {
			task   => 'Discover',
			job_id => 1,
		};

		# Tell the support server to expect the report
		$self->{support_server_results} = '/1';

	} elsif ( $self->_REQUEST($task) ) {
		# Copy the request, because we need to alter it
		my $request  = Storable::dclone( $task );

		# Which testing context will we run in
		### Don't check for error, we WANT to be undef if not a platform
		my $platform = Params::Util::_INSTANCE(shift, 'PITA::XML::Platform');

		# Set the tarball filename to be relative to current
		my $filename     = File::Basename::basename( $request->file->filename );
		my $tarball_from = $request->file->filename;
		my $tarball_to   = File::Spec->catfile(
			$self->injector_dir, $filename,
		);
		$request->file->{filename} = $filename;

		# Copy the tarball into the injector
		unless ( File::Copy::copy( $tarball_from, $tarball_to ) ) {
			Carp::croak("Failed to copy in test package: $!");
		}

		# Save the request file to the injector
		my $request_file = 'request-' . $request->id . '.pita';
		my $request_path = File::Spec->catfile( $self->injector_dir, $request_file );
		$request->write( $request_path );

		# Save the details of the above to the task section
		$image_conf->{task} = {
			task   => 'Test',
			job_id => $request->id,
			scheme => $request->scheme,
			path   => $platform ? $platform->path : '', # '' is default
			config => $request_file,
		};

		# Tell the support server to expect the report
		$self->{support_server_results} = [ "/" . $request->id ];

	} else {
		Carp::croak("Unexpected or invalid task param to prepare_task");
	}

	# Save the image.conf file
	my $image_file = File::Spec->catfile( $self->injector_dir, 'image.conf' );
	unless ( $image_conf->write( $image_file ) ) {
		Carp::croak("Failed to write config to $image_file");
	}

	return 1;
}

# Copy in the perl5lib modules
sub prepare_perl5lib {
	my $self     = shift;
	my $perl5lib = $self->perl5lib_dir;
	unless ( -d $perl5lib ) {
		mkdir( $perl5lib ) or Carp::croak("Failed to create perl5lib dir");
	}

	# Locate and copy in various classes
	foreach my $c ( $self->perl5lib_classes ) {
		my $from  = Class::Inspector->loaded_filename($c)
		         || Class::Inspector->resolved_filename($c)
		         or die "$c is not available to copy to perl5lib";
		my $to = File::Spec->catfile(
			$self->perl5lib_dir,
			Class::Inspector->filename( $c ),
			);
		File::Path::mkpath( File::Basename::dirname( $to ) ); # Croaks on error
		File::Copy::copy( $from, $to )
			or die "Failed to copy $from to $to";
	}

	return 1;
}

sub clean_injector {
	my $self = shift;

	# Scan for stuff in the injector
	my $injector = $self->injector_dir;
	# unless ( -d $injector ) {
		# File::Path::mkpath( $injector ) or die "mkpath($injector): $!";
	# }
	opendir( INJECTOR, $injector ) or die "opendir($injector): $!";
	my @files = readdir( INJECTOR );
	closedir( INJECTOR );

	# Delete it all
	foreach my $f ( File::Spec->no_upwards(@files) ) {
		my $path = File::Spec->catfile( $injector, $f );
		File::Remove::remove( \1, $path ) and next;
		die "Failed to remove $f from injector directory";
	}

	return 1;
}





#####################################################################
# Support Methods

sub DESTROY {
	$_[0]->SUPER::DESTROY();
	if ( $_[0]->{support_server_dir} and -d $_[0]->{support_server_dir} ) {
		File::Remove::remove( \1, $_[0]->{support_server_dir} );
		delete $_[0]->{support_server_dir};
	}
}

1;
