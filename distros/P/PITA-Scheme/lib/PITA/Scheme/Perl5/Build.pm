package PITA::Scheme::Perl5::Build;

# Class for implementing the perl5-build testing scheme

use 5.005;
use strict;
use Carp               ();
use File::Spec         ();
use File::Which        ();
use PITA::Scheme::Perl ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.43';
	@ISA     = 'PITA::Scheme::Perl';
}





#####################################################################
# Constructor

sub default_path {
	File::Which::which('perl') || '';
}

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);

	### Additional checks, if any

	$self;
}





#####################################################################
# PITA::Scheme Methods

sub prepare_package {
	my $self = shift;

	# Do the generic unpacking
	$self->SUPER::prepare_package(@_);

	# Validate that the package has a Makefile.PL in the root
	unless ( -f $self->workarea_file('Build.PL') ) {
		Carp::croak("Package does not contain a Makefile.PL");
	}

	$self;
}

sub execute_all {
	my $self = shift;

	# Run the Makefile.PL
	$self->execute_buildpl or return '';

	# Run the make
	$self->execute_build or return '';

	# Run the tests
	$self->execute_buildtest or return '';

	1;
}

sub execute_buildpl {
	my $self = shift;
	unless ( -f $self->workarea_file('Build.PL') ) {
		Carp::croak("Cannot execute_makefilepl without a Build.PL");
	}

	# Run the Makefile.PL
	my $command = $self->execute_command('perl', 'Build.PL');

	# Did it create a make file
	if ( -f $self->workarea_file('Build') ) {
		# Worked as expected
		### Do we need to add stuff here later?
		return 1;
	}

	# Didn't work
	### Do we need to add stuff here later?
	return '';
}

sub execute_build {
	my $self = shift;
	unless ( -f $self->workarea_file('Build') ) {
		Carp::croak("Cannot execute_make without a Build file");
	}

	# Run the make
	my $command = $self->execute_command('perl', 'Build');

	# Did it create a blib directory?
	if ( -d $self->workarea_file('blib') ) {
		# Worked as expected
		### Do we need to add stuff here later?
		return 1;
	}

	# Didn't work
	### Do we need to add stuff here later?
	return '';
}

sub execute_buildtest {
	my $self = shift;
	unless ( -f $self->workarea_file('Build') ) {
		Carp::croak("Cannot execute_maketest without a Build file");
	}
	unless ( -d $self->workarea_file('blib') ) {
		Carp::croak("Cannot execute_maketest without a blib");
	}

	# Run the make test
	my $command = $self->execute_command('perl', 'Build', 'test');

	# Did it... erm...
	if ( 1 ) {
		# Worked as expected
		### Do we need to add stuff here later?
		return 1;
	}

	# Didn't work
	### Do we need to add stuff here later?
	return '';
}

1;
