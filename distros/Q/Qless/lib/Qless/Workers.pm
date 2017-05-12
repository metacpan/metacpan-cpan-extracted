package Qless::Workers;
=head1 NAME

Qless::Workers

=cut

use strict; use warnings;
use JSON::XS qw(decode_json);
use Time::HiRes qw();
use Qless::Utils qw(fix_empty_array);

sub new {
	my $class = shift;
	my ($client) = @_;

	$class = ref $class if ref $class;
	my $self = bless {}, $class;

	$self->{'client'} = $client;

	$self;
}

sub counts {
	my ($self) = @_;
	my $results = decode_json($self->{'client'}->_workers([], Time::HiRes::time));
	$results = fix_empty_array($results);
	return $results;
}

sub item {
	my ($self, $name) = @_;
	my $rv = decode_json($self->{'client'}->_workers([], Time::HiRes::time, $name));
	$rv->{'jobs'}    = fix_empty_array($rv->{'jobs'});
	$rv->{'stalled'} = fix_empty_array($rv->{'stalled'});

	$rv;
}


1;
