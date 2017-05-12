package Puzzle::Args;

our $VERSION = '0.18';

use Params::Validate qw(:types);;

use base 'Class::Container';
use Scalar::Util "blessed";

use HTML::Mason::MethodMaker(
	read_only 		=> [ qw(args) ],
	read_write		=> [ 
	]
);

__PACKAGE__->valid_params (
	args => { type => HASHREF, parse => 'list', default => {}}
);


sub AUTOLOAD {
	my $self	= shift;
	my $key = $AUTOLOAD;
	$key =~ s/.*:://;
	if (@_) {
		$self->set($key,@_);
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


sub set {
	my $self	= shift;
	my $key		= shift;
	if (ref($key) eq 'HASH') {
		&__push_hashref($self->{args}, $key);
	} elsif (ref($key) eq '') {
		my $value	= shift;
		if (blessed($value) && $value->isa('DBIx::Class::ResultSet')) {
			my $relship = shift || {};
			my $array 	= $self->container->tmpl->dcc->resultset($value,$key,$relship);
			$self->set($array);
		} else {
			$self->{args}->{$key} = $value;
		}
	} elsif (blessed($key) && $key->isa('DBIx::Class::ResultSet')) {
		my $relship = shift || {};
		my $array 	= $self->container->tmpl->dcc->resultset($key,undef,$relship);
		$self->set($array);
	} elsif (blessed($key) && $key->isa('DBIx::Class::Row')) {
		my $relship = shift || {};
		$hashref	= $self->container->tmpl->dcc->row($key,$relship);
		$self->set($hashref);
	} else {
		die "Unknown structure to set: " . ref($key) . ' - ' . Data::Dumper::Dumper($key);
	}
	return $self->{args}->{$key};
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
