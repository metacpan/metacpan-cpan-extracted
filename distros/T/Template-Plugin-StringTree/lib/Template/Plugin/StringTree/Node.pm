package Template::Plugin::StringTree::Node;

# This package implements the actual nodes in the StringTree.
# We need to be very careful not to pollute this namespace with methods.

use 5.005;
use strict;
use Scalar::Util ();
use overload '""'   => '__get';

use vars qw{$VERSION %STRING};
BEGIN {
	$VERSION = '0.08';

	# Data store for the Nodes
	%STRING  = ();
}

# Create a new node, with an optional value
sub __new {
	my $class = ref $_[0] ? ref shift : shift;
	my $self  = bless {}, $class;

	if ( defined $_[0] and ! ref $_[0] ) {
		# The value for this node
		$STRING{Scalar::Util::refaddr($self)} = shift;
	}

	$self;
}

# Get the value for this node
sub __get {
	my $self = ref $_[0] ? shift : return undef;
	$STRING{Scalar::Util::refaddr($self)};
}

# Set the value for this node
sub __set {
	my $self = ref $_[0] ? shift : return undef;
	if ( defined $_[0] ) {
		$STRING{Scalar::Util::refaddr($self)} = shift;
	} else {
		delete $STRING{Scalar::Util::refaddr($_[0])};
	}

	1;
}

# Methods compatible with UNIVERSAL will die in a major way.
# Fortunately, we can tell if 'isa' and 'can' calls are meant to be genuine
# or not. The two-argument form is passed though, the one-argument form
# is treated by descending.
sub isa {
	my $self = shift;
	return $self->SUPER::isa(@_) if @_;
	exists $self->{isa} ? $self->{isa} : undef;
}
sub can {
	my $self = shift;
	return $self->SUPER::can(@_) if @_;
	exists $self->{can} ? $self->{can} : undef;
}

# Unfortunately, we have no choice but to use this name.
# To prevent pollution, we'll throw an error should we ever try to set
# a value using a DESTROY segment in a path.
sub DESTROY {
	delete $STRING{Scalar::Util::refaddr($_[0])} if ref $_[0];
}

1;
