package PITA::Scheme::Perl5::Make;

# Class for implementing the perl5-make testing scheme

use 5.005;
use strict;
use Carp               ();
use Config             ();
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

	### Additional checks

	$self;
}





#####################################################################
# PITA::Scheme Methods

sub prepare_package {
	my $self = shift;

	# Do the generic unpacking
	$self->SUPER::prepare_package(@_);

	# Validate that the package has a Makefile.PL in the root
	unless ( -f $self->workarea_file('Makefile.PL') ) {
		Carp::croak("Package does not contain a Makefile.PL");
	}

	$self;
}

sub execute_all {
	my $self = shift;

	# Run the Makefile.PL
	$self->execute_makefilepl or return '';

	# Run the make
	$self->execute_make or return '';

	# Run the tests
	$self->execute_maketest or return '';

	1;
}

sub execute_makefilepl {
	my $self = shift;
	unless ( -f $self->workarea_file('Makefile.PL') ) {
		Carp::croak("Cannot execute_makefilepl without a Makefile.PL");
	}

	# Run the Makefile.PL
	my $command = $self->execute_command('perl', 'Makefile.PL');

	# Did it create a make file
	if ( -f $self->workarea_file('Makefile') ) {
		# Worked as expected
		### Do we need to add stuff here later?
		return 1;
	}

	# Didn't work
	### Do we need to add stuff here later?
	return '';
}

sub execute_make {
	my $self = shift;
	unless ( -f $self->workarea_file('Makefile') ) {
		Carp::croak("Cannot execute_make without a Makefile");
	}

	# Run make
	my $make    = $Config::Config{make} || 'make';
	my $command = $self->execute_command($make);

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

sub execute_maketest {
	my $self = shift;
	unless ( -f $self->workarea_file('Makefile') ) {
		Carp::croak("Cannot execute_maketest without a Makefile");
	}
	unless ( -d $self->workarea_file('blib') ) {
		Carp::croak("Cannot execute_maketest without a blib");
	}

	# Run the make test
	my $make    = $Config::Config{make} || 'make';
	my $command = $self->execute_command($make, 'test');

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
