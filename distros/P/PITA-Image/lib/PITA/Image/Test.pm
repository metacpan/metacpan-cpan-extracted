package PITA::Image::Test;

use 5.006;
use strict;
use Data::GUID        ();
use Params::Util      ();
use PITA::Image::Task ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.60';
	@ISA     = 'PITA::Image::Task';
}

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Got somewhere to report this to?
	unless ( $self->job_id ) {
		Carp::croak("Task does not have a job_id");
	}

	# Resolve the specific schema class for this test run
	my $scheme = $self->scheme; # A convenience
	unless ( $scheme ) {
		Carp::croak("Missing option 'task.scheme' in image.conf");
	}
	my $driver = join( '::', 'PITA', 'Scheme', map { ucfirst $_ } split /\./, lc $scheme );
	unless ( Params::Util::_CLASS($driver) ) {
		Carp::croak("Invalid scheme '$scheme' for task.scheme in in image.conf");
	}

	# Load the scheme class
	eval "require $driver;";
	if ( $@ =~ /^Can\'t locate PITA/ ) {
		Carp::croak("Scheme '$scheme' is unsupported on this Guest");
	} elsif ( $@ ) {
		Carp::croak("Error loading scheme '$scheme' driver $driver: $@");
	}

	# Did we get a path
	unless ( defined $self->path ) {
		Carp::croak("Missing option task.path in image.conf");
	}

	# Did we get a config file
	unless ( $self->config ) {
		Carp::croak("Missing option task.config in image.conf");
	}

	# Did we get a job_id?
	unless ( _GUID($self->job_id) ) {
		Carp::croak("Missing option task.job_id in image.conf");
	}

	# Did we get a request?
	# Create the task object from it
	$self->{driver} = $driver->new(
		injector    => $self->{injector},
		workarea    => $self->{workarea},
		scheme      => $self->scheme,
		path        => $self->path,
		request_xml => $self->config,
		request_id  => $self->job_id,
	);

	$self;
}

sub job_id {
	$_[0]->{job_id};
}

sub scheme {
	$_[0]->{scheme};
}

sub path {
	$_[0]->{path};
}

sub config {
	$_[0]->{config};
}

sub driver {
	$_[0]->{driver};
}





#####################################################################
# Run the test

sub run {
	my $self = shift;
	$self->driver->prepare_all;
	$self->driver->execute_all;
	1;
}

sub result {
	$_[0]->report;
}





#####################################################################
# Return the resulting data

sub report {
	$_[0]->driver->report;
}

sub install {
	$_[0]->driver->install;
}





#####################################################################
# Support Methods

sub _GUID {
	my $guid = eval {
		Data::GUID->from_any_string(shift);
	};
	$@ ? undef : $guid;
}

#sub DESTROY {
#	# Clean up our driver early
#	if ( $_[0]->{driver} ) {
#		undef $_[0]->{driver};
#	}
#}

1;
