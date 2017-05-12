package PITA::Image;

=pod

=head1 NAME

PITA::Image - PITA Guest Manager for inside system images

=head1 SYNOPSIS

A typical startup script

  #!/usr/bin/perl
  
  use strict;
  use IPC::Run3;
  use PITA::Image;
  
  # Wrap the main actions in an eval to catch errors
  eval {
      # Configure the image manager
      my $manager = PITA::Image->new(
          injector => '/mnt/hbd1',
          workarea => '/tmp',
      );
      $manager->add_platform(
          scheme => 'perl5',
          path   => '', # Default system Perl
      );
      $manager->add_platform(
          scheme => 'perl5',
          path   => '/opt/perl5-6-1/bin/perl'
      );
  
      # Run the tasks
      $manager->run;
  
      # Report the results
      $manager->report;
  };
  
  # Shut down the computer on completion or failure
  run3( [ 'shutdown', '-h', '0' ], \undef );
  
  exit(0);

And a typical configuration image.conf

  class=PITA::Image
  version=0.10
  support=http://10.0.2.2/
  
  [ task ]
  task=Test
  scheme=perl5.make
  path=/usr/bin/perl
  request=request-512311.conf

=head1 DESCRIPTION

While most of the PITA system exists outside the guest images and
tries to have as little interaction with them as possible, there is one
part that needs to be run from inside it.

The C<PITA::Image> class lives inside the image and has the
responsibility of accepting the injector directory at startup, executing
the requested tasks, and then shutting down the (virtual) computer.

=head1 Setting up a Testing Image

Each image that will be set up will require a bit of customization,
as the entire point of this type of testing is that every environment
is different.

However, by keeping most of the functionality in the
C<PITA::Image> and L<PITA::Scheme> classes, all you should need
to do is to arrange for a relatively simple Perl script to be launched,
that feeds some initial configuration to to a new
C<PITA::Image> object.

And it should do the rest.

=head1 METHODS

=cut

use 5.006;
use strict;
use Carp                  ();
use URI              1.57 ();
use Process          0.29 ();
use File::Temp       0.22 ();
use File::Spec       0.80 ();
use File::Spec::Unix      ();
use File::Which      0.05 ();
use File::Remove     1.51 ();
use Config::Tiny     2.00 ();
use Params::Util     1.00 ();
use HTTP::Tiny      0.014 ();
use PITA::Image::Platform ();
use PITA::Image::Task     ();
use PITA::Image::Discover ();
use PITA::Image::Test     ();

use vars qw{$VERSION @ISA $NOSERVER};
BEGIN {
	$VERSION = '0.60';
	@ISA     = 'Process';
}





#####################################################################
# Constructor and Accessors

=pod

=head2 new

  my $manager = PITA::Image->new(
      injector => '/mnt/hdb1',
      workarea => '/tmp',
  );

The C<new> creates a new image manager. It takes two named parameters.

=over 4

=item injector

The required C<injector> param is a platform-specific path to the
root of the already-mounted F</dev/hdb1> partition (or the equivalent
on your operating system). The image configuration is expected to
exist at F<image.conf> within this directory.

=item workarea

The optional C<workarea> param provides a directory writable by the
current user that can be used to hold any files and do any processing
in during the running of the image tasks.

If you do not provide a value, C<File::Temp::tempdir()> will be used
to find a default usable directory.

=back

Returns a new C<PITA::Image> object, or dies on error.

=cut

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Create some lists
	$self->{platforms} = [];
	$self->{tasks}     = [];

	# Normalize boolean params
	$self->{cleanup}    = !! $self->{cleanup};

	# Check some params
	unless ( $self->injector ) {
		Carp::croak("Image 'injector' was not provided");
	}
	unless ( -d $self->injector ) {
		Carp::croak("Image 'injector' does not exist");
	}
	unless ( -r $self->injector ) {
		Carp::croak("Image 'injector' cannot be read, insufficient permissions");
	}

	# Find a temporary directory to use for the testing
	unless ( $self->workarea ) {
		$self->{workarea} = File::Temp::tempdir();
	}
	unless ( $self->workarea ) {
		Carp::croak("Image 'workarea' not provided and automatic detection failed");
	}
	unless ( -d $self->workarea ) {
		Carp::croak("Image 'workarea' directory does not exist");
	}
	unless ( -r $self->workarea and -w _ ) {
		Carp::croak("Image 'workarea' insufficient permissions");
	}

	# Find the main config file
	unless ( $self->image_conf ) {
		$self->{image_conf} = File::Spec->catfile(
			$self->injector, 'image.conf',
		);
	}
	unless ( $self->image_conf ) {
		Carp::croak("Did not get an image.conf location");
	}
	unless ( -f $self->image_conf ) {
		Carp::croak("Failed to find image.conf in the injector");
	}
	unless ( -r $self->image_conf ) {
		Carp::croak("No permissions to read scheme.conf");
	}

	$self;
}

sub cleanup {
	$_[0]->{cleanup};
}

sub injector {
	$_[0]->{injector};
}

sub workarea {
	$_[0]->{workarea};
}

sub image_conf {
	$_[0]->{image_conf};
}

sub config {
	$_[0]->{config};
}

sub perl5lib {
	$_[0]->{perl5lib};
}

sub server_uri {
	$_[0]->{server_uri};
}





#####################################################################
# Configuration Methods

sub add_platform {
	my $self     = shift;
	my $platform = PITA::Image::Platform->new( @_ );
	push @{$self->{platforms}}, $platform;
	1;
}

sub add_task {
	my $self = shift;
	my $task = Params::Util::_INSTANCE($_[0], 'PITA::Image::Task')
		or die("Passed bad param to add_task");
	push @{$self->{tasks}}, $task;
	1;
}

sub platforms {
	@{$_[0]->{platforms}};
}

sub tasks {
	@{$_[0]->{tasks}};
}





#####################################################################
# Process Methods

sub prepare {
	my $self  = shift;
	my $class = ref($self);

	# Load the main config file
	unless ( $self->config ) {
		$self->{config} = Config::Tiny->read( $self->image_conf );
	}
	unless ( Params::Util::_INSTANCE($self->config, 'Config::Tiny') ) {
		Carp::croak("Failed to load scheme.conf config file");
	}

	# Verify that we can use this config file
	my $config = $self->config->{_};
	unless ( $config->{class} and $config->{class} eq $class ) {
		Carp::croak("Config file is incompatible with PITA::Image");
	}
	unless ( $config->{version} and $config->{version} eq $VERSION ) {
		Carp::croak("Config file is incompatible with this version of PITA::Image");
	}

	# If provided, apply the optional lib path so some libraries
	# can be upgraded in a pince without upgrading all the images
	if ( $config->{perl5lib} ) {
		$self->{perl5lib} = File::Spec->catdir(
			$self->injector, split( /\//, $config->{perl5lib} ),
		);
		unless ( -d $self->perl5lib ) {
			Carp::croak("Injector lib directory does not exist");
		}
		unless ( -r $self->perl5lib ) {
			Carp::croak("Injector lib directory has no read permissions");
		}
		require lib;
		lib->import( $self->perl5lib );
	}

	# Check the support server
	unless ( $self->server_uri ) {
		$self->{server_uri} = URI->new($config->{server_uri});
	}
	unless ( $self->server_uri ) {
		Carp::croak("Missing 'server_uri' param in image.conf");
	}
	unless ( Params::Util::_INSTANCE($self->server_uri, 'URI::http') ) {
		Carp::croak("The 'server_uri' is not a HTTP(S) URI");
	}
	unless ( $NOSERVER ) {
		my $response = HTTP::Tiny->new( timeout => 5 )->get( $self->server_uri );
		unless ( $response and $response->{success} ) {
			Carp::croak("Failed to contact SupportServer at $config->{server_uri}");
		}
	}

	# We expect a task at [ task ]
	unless ( $self->config->{task} ) {
		Carp::croak("Missing [task] section in image.conf");
	}
	unless ( $self->config->{task}->{task} ) {
		Carp::croak("Missing task.task value in image.conf");
	}

	# The ping task is a nullop
	my $taskname = $self->config->{task}->{task};
	if ( $taskname eq 'Ping' ) {
		# Do nothing

	} elsif ( $taskname eq 'Discover' ) {
		# Add a discovery task
		$self->add_task( 
			PITA::Image::Discover->new(
				%{$self->config->{task}},
				platforms => [ $self->platforms ],
			),
		);

	} elsif ( $taskname eq 'Test' ) {
		# Add the testing task
		$self->add_task(
			PITA::Image::Test->new(
				%{$self->config->{task}},
				injector => $self->injector,
				workarea => $self->workarea,
			),
		);

	} else {
		Carp::croak("Unknown task.task value in image.conf");
	}

	$self;
}

sub run {
	my $self = shift;

	# Auto-prepare
	$self->prepare unless $self->config;

	# Test each scheme
	foreach my $task ( $self->tasks ) {
		$task->run;
	}

	1;
}





#####################################################################
# Task Methods

sub report {
	my $self = shift;

	# Test each scheme
	foreach my $task ( $self->tasks ) {
		$self->report_task( $task );
	}

	1;
}

sub report_task {
	my $self    = shift;
	my $task    = shift;
	my $request = $self->report_task_request($task);
	unless ( ref($request) eq 'ARRAY' ) {
		die "Did not generate proper report request";
	}
	unless ( $NOSERVER ) {
		my $response = HTTP::Tiny->new( timeout => 5 )->request(@$request);
		unless ( $response and $response->{success} ) {
			die "Failed to send result report to server";
		}
	}

	1;
}

sub report_task_request {
	my $self = shift;
	my $task = shift;
	unless ( $task->result ) {
		Carp::croak("No Result Report created to PUT");
	}

	# Serialize the data for sending
	my $xml = '';
	$task->result->write( \$xml );
	unless ( length($xml) ) {
		Carp::croak("Failed to serialize report");
	}

	# Send the file
	return [
		'PUT' => $self->report_task_uri($task),
		{
			headers => {
				content_type => 'application/xml',
				content_length => length($xml),
			},
			content => $xml,
		},
	];
}

# The location to put to
sub report_task_uri {
	my $self = shift;
	my $task = shift;
	my $uri  = $self->server_uri;
	my $job  = $task->job_id;
	my $path = File::Spec::Unix->catfile( $uri->path || '/', $job );
	$uri->path( $path );
	$uri;
}





#####################################################################
# Support Methods

sub DESTROY {
	# Delete our tasks and platforms in reverse order
	### Mostly paranoia, some actual problems if we do not
	### do it as strictly correct as this
	if ( defined $_[0]->{tasks} ) {
		foreach my $i ( reverse 0 .. $#{$_[0]->{tasks}} ) {
			undef $_[0]->{tasks}->[$i];
		}
		delete $_[0]->{tasks};
	}
	if ( defined $_[0]->{platforms} ) {
		foreach my $i ( reverse 0 .. $#{$_[0]->{platforms}} ) {
			undef $_[0]->{platforms}->[$i];
		}
		delete $_[0]->{platforms};
	}

	# Now remove the workarea directory
	if ( $_[0]->{cleanup} and $_[0]->{workarea} and -d $_[0]->{workarea} ) {
		File::Remove::remove( \1, $_[0]->{workarea} );
	}
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PITA-Image>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>, L<http://ali.as/>

=head1 SEE ALSO

The Perl Image Testing Architecture (L<http://ali.as/pita/>)

L<PITA>, L<PITA::XML>, L<PITA::Scheme>

=head1 COPYRIGHT

Copyright 2005 - 2011 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
