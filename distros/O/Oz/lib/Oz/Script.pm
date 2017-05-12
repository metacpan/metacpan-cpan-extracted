package Oz::Script;

use 5.008;
use strict;
use Carp                 ();
use File::Slurp  9999.12 ();
use Params::Util    0.20 ();
use Oz::Compiler         ();

our $VERSION = '0.01';





#####################################################################
# Constructor

sub new {
	my $class = shift;

	# Create the basic object
	my $self = bless {
		text => undef,
	}, $class;

	# Load the script
	my $source = shift;
	if ( Params::Util::_SCALAR($source) ) {
		$self->{text} = $$source;
	} elsif ( Params::Util::_STRING($source) ) {
		if ( $source =~ /(?:\012|\015)/ ) {
			Carp::croak("Source code should only be passed as a reference");
		}
		$self->{text} = File::Slurp::read_file( $source );
	} else {
		croak("Missing or invalid source code provided to Oz::Script->new");
	}

	$self;
}

sub text {
	$_[0]->{text};
}





#####################################################################
# Main Methods

sub write {
	my $self = shift;
	my $file = shift;
	File::Slurp::write_file( $file, $self->text );
	return 1;
}

sub run {
	my $self   = shift;
	my @params = @_;

	# Create the default compiler for this script
	my $compiler = Oz::Compiler->new(
		script => $self,
	);

	# Execute and return the result
	return $compiler->run( @params );
}

1;
