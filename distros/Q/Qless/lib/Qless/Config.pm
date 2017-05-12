package Qless::Config;
=head1 NAME

Qless::Config

=cut

use strict; use warnings;
use JSON::XS qw(decode_json);

sub new {
	my $class = shift;
	my ($client) = @_;

	$class = ref $class if ref $class;
	my $self = bless {}, $class;

	$self->{'client'} = $client;

	$self;
}

sub get {
	my ($self, $key) = @_;
	if ($key) {
		return $self->{'client'}->_config([], 'get', $key);
	}
	return decode_json($self->{'client'}->_config([], 'get'));
}

sub set {
	my ($self, $key, $value) = @_;
	return $self->{'client'}->_config([], 'set', $key, $value);
}

sub del {
	my ($self, $key, $value) = @_;
	return $self->{'client'}->_config([], 'unset', $key);
}

1;
