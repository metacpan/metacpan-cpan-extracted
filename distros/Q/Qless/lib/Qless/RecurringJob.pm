package Qless::RecurringJob;
=head1 NAME

Qless::RecurringJob

=cut

use strict; use warnings;
use base 'Qless::BaseJob';
use JSON::XS qw(decode_json encode_json);

sub new {
	my $class = shift;

	my ($client, $args) = @_;

	$class = ref $class if ref $class;
	my $self = $class->SUPER::new($client, $args);

	foreach my $key (qw(retries interval count)) {
		$self->{$key} = $args->{ $key };
	}

	$self;
}

sub _set_key {
	my ($self, $key, $value) = @_;
	$self->client->_recur([], 'update', $self->{'jid'}, $key, $value);
	$self->{$key} = $value;
}

sub priority { $#_ == 0 ? $_[0]->SUPER::priority : $_[0]->_set_key('priority', $_[1]) }
sub retries  { $#_ == 0 ? $_[0]->{'retries'}     : $_[0]->_set_key('retries',  $_[1]) }
sub interval { $#_ == 0 ? $_[0]->{'interval'}    : $_[0]->_set_key('interval', $_[1]) }
sub data     { $#_ == 0 ? $_[0]->SUPER::data     : $_[0]->_set_key('data',     encode_json($_[1])) }
sub klass    { $#_ == 0 ? $_[0]->SUPER::klass    : $_[0]->_set_key('klass',    $_[1]) }
sub count    { $_[0]->{'count'} }

sub next {
	my ($self) = @_;
	return $self->client->redis->zscore('ql:q:'.$self->queue_name.'-recur', $self->jid);
}

sub move {
	my ($self, $queue) = @_;
	$self->client->_recur([], 'update', $self->jid, 'queue', $queue);
}

sub cancel {
	my ($self, $queue) = @_;
	$self->client->_recur([], 'off', $self->jid);
}

sub tag {
	my ($self, @tags) = @_;
	$self->client->_recur([], 'tag', $self->jid, @tags);
}

sub untag {
	my ($self, @tags) = @_;
	$self->client->_recur([], 'untag', $self->jid, @tags);
}

1;
