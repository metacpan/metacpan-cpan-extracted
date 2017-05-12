package PITA::Scheme::Perl5;

# Auto-sensing Perl 5 scheme.
# Use Makefile.PL or Build.PL as appropriate.

# We won't know this until AFTER the extract_package method,
# so at the end of this method we will look for the appropriate
# file and rebless ourself into the class for it.

use 5.005;
use strict;
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

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	$self;
}





#####################################################################
# PITA::Scheme Methods

sub default_path {
	File::Which::which('perl') || '';
}

sub prepare_package {
	my $self = shift;

	# Do the generic unpacking
	$self->SUPER::prepare_package(@_);

	# Use the Makefile.PL in preference to Build.PL as it should be
	# more mature than a Module::Build installer.
	# Whichever one we call, it will end up called the same
	# prepare_package in ::Perl. This isn't a problem, as it knows
	# how to shortcut.
	if ( -f $self->workarea_file('Makefile.PL') ) {
		require PITA::Scheme::Perl5::Make;
		bless $self, 'PITA::Scheme::Perl5::Make';
		return $self->prepare_package;

	} elsif ( -f $self->workarea_file('Build.PL') ) {
		require PITA::Scheme::Perl5::Make;
		bless $self, 'PITA::Scheme::Perl5::Make';
		return $self->prepare_package;

	}

	# Doesn't have either
	Carp::croak("Perl5 package contains neither Makefile.PL or Build.PL");
}

1;
