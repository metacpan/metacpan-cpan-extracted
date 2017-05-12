package PITA::Scheme::Perl::Discovery;

# Provides a mechanism for discovering the platform of an arbitrary
# perl interpreter, by using Process::Delegatable.

use 5.005;
use strict;
use File::Spec           ();
use Params::Util         ('_STRING');
use Process              ();
use Process::Storable    ();
use Process::Delegatable ();
use PITA::XML            ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.43';
	@ISA     = qw{
		Process::Delegatable
		Process::Storable
		Process
	};
}





#####################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Check that the program exists.
	# The path should not be the command to call, it should be
	# the actual file path of the Perl executable.
	unless ( _STRING($self->{path}) ) {
		Carp::croak("Did not provide a path to perl");
	}
	unless ( File::Spec->file_name_is_absolute($self->{path}) ) {
		Carp::croak("The path $self->{path} is not absolute");
	}
	unless ( -f $self->{path} ) {
		Carp::croak("The path $self->{path} does not exist");
	}
	unless ( -x $self->{path} ) {
		Carp::croak("The path $self->{path} is not executable");
	}

	# Check that it is indeed Perl
	my @output = `$self->{path} -v`;
	chomp @output;
	shift @output if $output[0] =~ /^\s*$/;
	unless ( $output[0] =~ /^This is perl/ ) {
		Carp::croak("The path $self->{path} is not Perl");
	}

	$self;
}

sub path {
	$_[0]->{path};
}

sub platform {
	$_[0]->{platform};
}





#####################################################################
# Process::Delegatable

# Allow delegate to be called without a param.
# And shortcut if already run.
sub delegate {
	my $self = shift;
	return 1 if defined $self->platform;
	$self->SUPER::delegate( $self->path, @_ );
}





#####################################################################
# Process Methods

sub prepare {
	# We are already running inside the Perl interpreter we want
	# to capture at this point, and we have already loaded
	# PITA::XML::Platform, so there's nothing else we need to do.
	return 1;
}

sub run {
	my $self = shift;

	# Do the autodetection
	my $platform = eval {
		PITA::XML::Platform->autodetect_perl5;
	};
	if ( $platform ) {
		$self->{platform} = $platform;
	} else {
		$self->{errstr}   = $@;
	}

	1;
}





#####################################################################
# Error Methods

sub errstr {
	$_[0]->{errstr};
}

1;
