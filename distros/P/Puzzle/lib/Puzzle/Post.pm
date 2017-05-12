package Puzzle::Post;

our $VERSION = '0.18';

use Params::Validate qw(:types);;

use base 'Class::Container';

use HTML::Mason::MethodMaker(
	read_only 		=> [ qw(args) ],
	read_write		=> [ ]
);

__PACKAGE__->valid_params (
	args => { type => HASHREF, parse => 'list', default => {}}
);



sub AUTOLOAD {
	my $self	= shift;
	my $key = $AUTOLOAD;
	$key =~ s/.*:://;
	if (@_) {
		$self->_set($key,@_);
	} else {
		$self->get($key);
	}
}

sub DESTROY {}

sub get {
	my $self	= shift;
	my $key		= shift;
	return $self->{args}->{$key};
}

sub _set {
	my $self	= shift;
	my $key		= shift;
	if (ref($key) eq 'HASH') {
		&__push_hashref($self->{args}, $key);
	} else {
		$self->{args}->{$key} = shift;
	}
	return $self->args->{$key};
}

sub clear {
	my $self	= shift;
	$self->{args} = {};
}

sub __push_hashref {
	# da verificare cosa e' piu' veloce
	my $dst	= shift;
	my $src	= shift;
	my (@cols) = keys %$src;
	@{$dst}{@cols} = @{$src}{@cols};
}


1;
