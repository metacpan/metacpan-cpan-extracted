package Module::Changes::ADAMK::Change;

use 5.006;
use strict;
use warnings;
use Carp ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.11';
}

use Object::Tiny qw{
	string
	message
	author
};





#####################################################################
# Constructor

sub new {
	my $class = shift;
	my $self  = bless { string => shift }, $class;

	# Get the paragraph strings
	my @lines = split /\n/, $self->{string};

	# A (FOO) at the end indicates an author
	if ( $lines[-1] =~ s/\s*\((\w+)\)\s*\z//s ) {
		$self->{author} = $1;
	}

	# Trim the lines and merge to get the long-form message
	$self->{message} = join ' ', grep {
		s/^\s+//;
		s/\s+\z//;
		$_
	} @lines;
	$self->{message} =~ s/^-\s*//;

	return $self;
}





#####################################################################
# Stringification

sub as_string {
	$_[0]->string;
}

sub roundtrips {
	$_[0]->string eq $_[0]->as_string
}

1;
