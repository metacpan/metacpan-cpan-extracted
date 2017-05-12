package Qless::Job;
=head1 NAME

Qless::Job

=cut

use strict; use warnings;
use base 'Qless::BaseJob';
use Qless::Utils qw(fix_empty_array);
use JSON::XS qw(decode_json encode_json);
use Class::Load qw(try_load_class);
use Time::HiRes qw();

sub new {
	my $class = shift;

	my ($client, $args) = @_;

	$class = ref $class if ref $class;
	my $self = $class->SUPER::new($client, $args);

	foreach my $key (qw(state tracked failure history dependents dependencies)) {
		$self->{$key} = $args->{ $key };
	}
	$self->{'dependents'}   = fix_empty_array($self->{'dependents'});
	$self->{'dependencies'} = fix_empty_array($self->{'dependencies'});

	$self->{'expires_at'}       = $args->{'expires'};
	$self->{'original_retries'} = $args->{'retries'};
	$self->{'retries_left'}     = $args->{'remaining'};
	$self->{'worker_name'}      = $args->{'worker'};

	$self;
}

sub state            { $_[0]->{'state'} }
sub tracked          { $_[0]->{'tracked'} }
sub failure          { $_[0]->{'failure'} }
sub history          { $_[0]->{'history'} }
sub dependents       { $_[0]->{'dependents'} }
sub dependencies     { $_[0]->{'dependencies'} }
sub expires_at       { $_[0]->{'expires_at'} }
sub original_retries { $_[0]->{'original_retries'} }
sub retries_left     { $_[0]->{'retries_left'} }
sub worker_name      { $_[0]->{'worker_name'} }

sub ttl {
	my ($self) = @_;
	return $self->{'expires_at'} - Time::HiRes::time;
}

sub process {
	my ($self) = @_;

	my $class = $self->klass;

	my ($loaded, $error_message) = try_load_class($class);
	if(!$loaded) {
		return $self->fail($self->queue_name.'-class-missing', $class. ' is missing: '.$error_message);
	}

	my $method;

	if ($class->can($self->queue_name)) {
		$method = $self->queue_name;
	}
	elsif ($class->can('process')) {
		$method = 'process';
	}

	if (!$method) {
		return $self->fail($self->queue_name.'-method-missing', $class. ' is missing a method "'.$self->queue_name.'" or "process"');
	}

	eval {
		$class->$method($self);
	};

	if ($@) {
		print STDERR "Error: $@\n";
		return $self->fail($self->queue_name.'-'.$class.'-'.$method, $@);
	}

}

sub move {
	my ($self, $queue, $delay, $depends) = @_;

	return $self->{'client'}->_put([$queue],
		$self->jid,
		$self->klass,
		encode_json($self->data),
		Time::HiRes::time,
		$delay||0,
		'depends', encode_json($depends||[])
	);
}

sub complete {
	my ($self, $next, $delay, $depends) = @_;
	
	if ($next) {
		return $self->client->_complete([], $self->jid, $self->client->worker_name, $self->queue_name,
			Time::HiRes::time, encode_json($self->data), 'next', $next, 'delay', $delay||0, 'depends', encode_json($depends||[])
		);
	}
	else {
		return $self->client->_complete([], $self->jid, $self->client->worker_name, $self->queue_name,
			Time::HiRes::time, encode_json($self->data)
		);
	}
}

sub heartbeat {
	my ($self) = @_;

	return $self->{'expires_at'} = $self->client->_heartbeat([],
		$self->jid, $self->client->worker_name, Time::HiRes::time, encode_json($self->data)
	) || 0;
}


sub fail {
	my ($self, $group, $message) = @_;

	return $self->client->_fail([], $self->jid, $self->client->worker_name, $group, $message, Time::HiRes::time, encode_json($self->data));
}

sub track {
	my ($self) = @_;

	return $self->client->_track([], 'track', $self->jid, Time::HiRes::time);
}

sub untrack {
	my ($self) = @_;

	return $self->client->_track([], 'untrack', $self->jid, Time::HiRes::time);
}

sub retry {
	my ($self, $delay) = @_;

	return $self->client->_retry([], $self->jid, $self->queue_name, $self->worker_name, Time::HiRes::time, $delay||0);
}

sub depend {
	my ($self, @args) = @_;
	return $self->client->_depends([], $self->jid, 'on', @args);
}

sub undepend {
	my ($self, @args) = @_;
	if ($args[0] eq 'all') {
		return $self->client->_depends([], $self->jid, 'off', 'all');
	}
	return $self->client->_depends([], $self->jid, 'off', @args);
}

1;
