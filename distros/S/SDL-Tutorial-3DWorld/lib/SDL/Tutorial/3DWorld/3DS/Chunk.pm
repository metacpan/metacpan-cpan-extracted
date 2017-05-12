package SDL::Tutorial::3DWorld::3DS::Chunk;

use 5.008;
use strict;
use warnings;

our $VERSION = '0.33';





######################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	bless { children => [ ], @_ }, $class;
}

sub start {
	$_[0]->{start};
}

sub type {
	$_[0]->{type};
}

sub bytes {
	$_[0]->{bytes};
}

sub children {
	@{ $_[0]->{children} };
}





######################################################################
# Parsing Methods

sub add {
	push @{ shift->{children} }, @_;
}

sub next_start {
	$_[0]->{start} + $_[0]->{bytes};
}

sub child_start {
	$_[0]->{start} + 6;
}

1;
