package Puzzle::Args;

our $VERSION = '0.20';

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
	my $value	= shift;
	my $params	= shift;
	die "Starting from 0.19 the fourth arg must be an hashref of params." .
		" Replace relship with {relship => ...}" if ($params && ref($params) ne 'HASH');
	if (ref($key) eq 'HASH') {
		&__push_hashref($self->{args}, $key, $params->{filter});
	} elsif (ref($key) eq '') {
		if (blessed($value) && $value->isa('DBIx::Class::ResultSet')) {
			my $relship = $params->{relship} ? $params->{relship} : {};
			my $array 	= $self->container->tmpl->dcc->resultset($value,$key,$relship);
			$self->set($array,undef,$params);
		} else {
			$self->{args}->{$key} = &__call_filter($flt,$value,$key,$value,0);
		}
	} elsif (blessed($key) && $key->isa('DBIx::Class::ResultSet')) {
		my $relship = $params->{relship} ? $params->{relship} : {};
		my $array 	= $self->container->tmpl->dcc->resultset($key,undef,$relship);
		$self->set($array,undef,$params);
	} elsif (blessed($key) && $key->isa('DBIx::Class::Row')) {
		my $relship = $params->{relship} ? $params->{relship} : {};
		$hashref	= $self->container->tmpl->dcc->row($key,$relship);
		$self->set($hashref,undef,$params);
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
	my $flt	= shift;
	foreach (keys %$src) {
		$dst->{$_} = &__call_filter($flt,$src,$_,$src->{$_},0);
	}
}

sub __call_filter {
	my $flt	= shift;
	my $src	= shift;
	my $key = shift;
	my $val	= shift;
	my $lev	= shift;
	return $val unless ($flt);
	if (ref($val) eq 'HASH') {
		while (my ($k,$v) = each %$val) {
			$val->{$k} = &__call_filter($flt,$val,$k,$v,$lev+1);
		}
	} elsif (ref($val) eq 'ARRAY') {
		for (my $i=0;$i<scalar(@$val); $i++) {
			$val->[$i] = &__call_filter($flt,$val,$i,$val->[$i],$lev+1);
		}
	}
	return &$flt($src,$key,$val,$lev);
}


1;
