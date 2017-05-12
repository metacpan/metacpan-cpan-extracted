package PITA::Scheme;

=pod

=head1 NAME

PITA::Scheme - PITA Testing Schemes

=head1 SYNOPSIS

  # Have the scheme load up from the provided config
  my $scheme = PITA::Scheme->new(
      injector => $injector,
      workarea => $workarea,
  );
  
  # Prepare to run the tests
  $scheme->prepare_all;
  
  # Run the tests
  $scheme->execute_all;

=head1 DESCRIPTION

While most of the L<PITA> system exists outside the guest testing images and
tries to have as little interaction with them as possible, there is one
part that needs to be run from inside it.

PITA::Scheme objects live inside the image and does three main tasks.

1. Unpack the package and prepare the testing environment

2. Run the sequence of commands to execute the tests and capture
the results.

3. Package the results as a L<PITA::XML::Report> and send it to the
L<PITA::Host::ResultServer>.

This functionality is implemented in a module structure that is highly
subclassable. In this way, L<PITA> can support multiple different
testing schemes for multiple different languages and installer types.

=head1 Setting up a Testing Image

Each image that will be set up will require a bit of customisation,
as the entire point of this type of testing is that every environment
is different.

However, by keeping most of the functionality in the L<PITA::Scheme>
objects, all you should need to do is to arrange for a simple Perl
script to be launched, that feeds some initial configuration to the
L<PITA::Scheme> object.

And it should do the rest. Or die... but we'll cover that later.

=head1 METHODS

Please excuse the lack of details for now...

TO BE COMPLETED

=cut

use 5.006;
use strict;
use Carp         ();
use IPC::Run3    ();
use File::Spec   ();
use Data::GUID   ();
use Params::Util qw{ _INSTANCE _POSINT _STRING _ARRAY _CLASS };
use PITA::XML    ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.43';
}





#####################################################################
# Constructor

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Apply the default path if needed
	unless ( $self->path ) {
		$self->{path} = $self->default_path;
	}

	# Cursory checking for compulsory params
	foreach my $param ( qw{ injector workarea scheme path } ) {
		next if $self->$param();
		Carp::croak("Missing compulsory param '$param'");
	}

	# Load the request from a file if needed
	unless ( $self->request ) {
		$self->{request_xml} = File::Spec->catfile( $self->injector, $self->request_xml );
		unless ( -f $self->request_xml and -r _ ) {
			Carp::croak('Missing request file, or no permissions');
		}
		$self->{request} = PITA::XML::Request->read( $self->request_xml );
	}
	unless ( _INSTANCE($self->request, 'PITA::XML::Request') ) {
		Carp::croak(
			"Bad report Request or failed to load one from "
			. $self->request_xml
		);
	}
	unless ( $self->request->scheme eq $self->scheme ) {
		Carp::croak("Test scheme in image.conf does not match Request scheme");
	}

	# Check the request identifier
	unless ( _GUID($self->request_id) ) {
		Carp::croak("Missing or bad request_id for this test instance");
	}

	$self;
}





#####################################################################
# Accessors and convience methods

sub injector {
	$_[0]->{injector};
}

sub workarea {
	$_[0]->{workarea};
}

sub scheme {
	$_[0]->{scheme};
}

sub path {
	$_[0]->{path};
}

sub request_xml {
	$_[0]->{request_xml};
}

sub request {
	$_[0]->{request};
}

sub request_id {
	my $self = shift;
	if ( $self->request and $self->request->id ) {
		# New style request with an id
		return $self->request->id;
	} else {
		# Manually passed request_id
		return $self->{request_id};
	}

	undef;
}

sub platform {
	$_[0]->{platform};
}

sub install {
	$_[0]->{install};
}

sub report {
	$_[0]->{report};
}





#####################################################################
# PITA::Scheme Methods

sub load_config {
	my $self = shift;

	# Load the config file
	$self->{config} = Config::Tiny->new( $self->{config_file} );
	unless ( $self->{config} ) {
		Carp::croak("Failed to load config file: " . Config::Tiny->errstr);
	}

	# Validate some basics

	1;
}

# Do the various preparations
sub prepare_all {
	my $self = shift;
	return 1 if $self->install;

	# Prepare the package
	$self->prepare_package;

	# Prepare the environment
	$self->prepare_environment;

	# Prepare the report
	$self->prepare_report;

	1;
}

# Nothing, yet
sub prepare_package {
	my $self = shift;
	1;
}

sub prepare_report {
	my $self = shift;
	return 1 if $self->install;

	# Create the install object
	$self->{install} = PITA::XML::Install->new(
		request  => $self->request,
		platform => $self->platform,
	);

	# Create the main report object
	$self->{report} ||= PITA::XML::Report->new;
	$self->report->add_install( $self->install );

	1;
}

sub execute_command {
	my $self = shift;
	my $cmd  = _ARRAY( [ @_ ] ) or Carp::croak(
		"execute_command not passed an ARRAY ref as command"
	);

	# Execute the command
	my $stdout  = '';
	my $stderr  = '';
	my $success = IPC::Run3::run3( $cmd, \undef, \$stdout, \$stderr );

	# Turn the results into a Command object
	my $command = PITA::XML::Command->new(
		cmd    => join( ' ', @$cmd ),
		stdout => \$stdout,
		stderr => \$stderr,
	);
	unless ( _INSTANCE($command, 'PITA::XML::Command') ) {
		Carp::croak("Error creating ::Command");
	}

	# If we have a PITA::XML::Install object available,
	# automatically add to it.
	if ( $self->install ) {
		$self->install->add_command( $command );
	}

	$command;
}





#####################################################################
# Support Methods

# Validate a usable scheme, returning a (loaded) driver class
sub _DRIVER {
	my $class  = shift;

	# Resolve the specific testing scheme class for this run
	my $scheme = shift;
	unless ( _STRING($scheme) ) {
		Carp::croak("Missing or invalid scheme");
	}
	my $driver = join( '::', 'PITA', 'Scheme', map { ucfirst $_ } split /\./, lc($scheme || '') );
	unless ( _CLASS($driver) ) {
		Carp::croak("Invalid scheme '$scheme'");
	}

	# Load the scheme class
	eval "require $driver;";
	if ( $@ =~ /^Can\'t locate PITA/ ) {
		Carp::croak("Scheme '$scheme' is unsupported on this Guest");
	} elsif ( $@ ) {
		Carp::croak("Error loading scheme '$scheme' driver $driver: $@");
	}

	$driver;
}

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

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PITA-Scheme>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>, L<http://ali.as/>

=head1 SEE ALSO

The Perl Image Testing Architecture (L<http://ali.as/pita/>)

L<PITA>, L<PITA::XML>, L<PITA::Host::ResultServer>

=head1 COPYRIGHT

Copyright 2005 - 2011 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
