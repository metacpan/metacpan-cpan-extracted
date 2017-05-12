package PITA::Image::Discover;

use 5.006;
use strict;
use PITA::XML                     ();
use Params::Util                  ();
use PITA::Image::Task             ();
use PITA::Scheme::Perl::Discovery ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.60';
	@ISA     = 'PITA::Image::Task';
}

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Check the task params
	unless ( $self->job_id ) {
		Carp::croak("Task does not have a job_id");
	}
	unless ( Params::Util::_SET($self->platforms, 'PITA::Image::Platform') ) {
		Carp::croak("Did not provide a list of platforms");
	}

	# Create a discovery object for each platform
	my @discoveries = ();
	foreach my $platform ( @{$self->platforms} ) {
		push @discoveries, PITA::Scheme::Perl::Discovery->new(
			path => $platform->path,
		);
	}
	$self->{discoveries} = \@discoveries;

	$self;
}

sub job_id {
	$_[0]->{job_id};
}

sub platforms {
	$_[0]->{platforms};
}

sub discoveries {
	$_[0]->{discoveries};
}





#####################################################################
# Run the discovery process

sub run {
	my $self = shift;

	# Create a Guest to hold the platforms.
	### Although we might not be running in the Local driver,
	### WE can't tell the difference, so we might as well be.
	### The driver will correct it later if it's wrong.
	my $guest = PITA::XML::Guest->new(
		driver => 'Local',
		params => {},
	);

	# Run the discovery on each platform
	foreach my $discovery ( @{$self->discoveries} ) {
		require Devel::Dumpvar;
		$discovery->delegate;
		if ( $discovery->platform ) {
			$guest->add_platform( $discovery->platform );
		} else {
			my $path = $discovery->path;
			Carp::croak("Error finding platform at $path");
		}
	}

	# Looks good, save
	$self->{result} = $guest;

	1;
}

sub result {
	$_[0]->{result};
}

1;
