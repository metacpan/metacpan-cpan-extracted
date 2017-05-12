package Qless::Queue;
=head1 NAME

Qless:Queue

=cut

use strict; use warnings;
use JSON::XS qw(decode_json encode_json);
use Qless::Jobs;
use Qless::Job;
use Time::HiRes qw();

=head1 METHODS

=head2 C<new>
=cut
sub new {
	my $class = shift;
	my ($name, $client, $worker_name) = @_;

	$class = ref $class if ref $class;
	my $self = bless {}, $class;

	$self->{'name'}        = $name;
	$self->{'client'}      = $client;
	$self->{'worker_name'} = $worker_name;

	$self;
}

sub generate_jid {
	my ($self, $data) = @_;
	return $self->{'worker_name'}.'-'.CORE::time.'-'.sprintf('%06d', int(rand(999999)));
}

sub client       { $_[0]->{'client'} }
sub name         { $_[0]->{'name'} }
sub worker_name  { $_[0]->{'worker_name'} }


=head2 C<jobs>

=cut

sub jobs {
	my ($self) = @_;
	Qless::Jobs->new($self->{'name'}, $self->{'client'});
}

=head2 C<counts>

=cut

sub counts {
	my ($self) = @_;
	return decode_json($self->{'client'}->_queues([], Time::HiRes::time, $self->{'name'}));
}

=head2 C<heartbeat>
=cut
sub heartbeat {
	my ($self, $new_value) = @_;

	my $config = $self->{'client'}->config;

	if (defined $new_value) {
		$config->set($self->{'name'}.'-heartbeat', $new_value);
		return;
	}

	return $config->get($self->{'name'}.'-heartbeat') || $config->get('heartbeat') || 60;
}

=head2 C<put>
=cut
sub put {
	my ($self, $klass, $data, %args ) = @_;

	return $self->{'client'}->_put([$self->{'name'}],
		$args{'jid'} || $self->generate_jid($data),
		$klass,
		encode_json($data),
		Time::HiRes::time,
		$args{'delay'} || 0,
		'priority', $args{'priority'} || 0,
		'tags', encode_json($args{'tags'} || []),
		'retries', $args{'retries'} || 5,
		'depends', encode_json($args{'depends'} || []),
	);
}

=head2 C<recur>
=cut
sub recur {
	my ($self, $klass, $data, @args) = @_;

	my $interval;
	my %args;

	if (scalar(@args)%2) {
		$interval = shift @args;
		%args = @args;
	}
	else {
		%args = @args;
		$interval = $args{'interval'};
	}

	return $self->{'client'}->_recur([], 'on', $self->{'name'},
		$args{'jid'} || $self->generate_jid($data),
		$klass,
		encode_json($data),
		Time::HiRes::time,
		'interval', $interval, $args{'offset'} || 0,
		'priority', $args{'priority'} || 0,
		'tags', encode_json($args{'tags'} || []),
		'retries', $args{'retries'} || 5,
	);

}

=head2 C<pop>
=cut
sub pop {
	my ($self, $count) = @_;
	my $jobs = [ map { Qless::Job->new($self->{'client'}, decode_json($_)) }
		@{ $self->{'client'}->_pop([$self->{'name'}], $self->{'worker_name'}, $count||1, Time::HiRes::time) } ];
	if (!defined $count) {
		return scalar @{ $jobs } ?  $jobs->[0] : undef;
	}

	return @{ $jobs };
}

=head2 C<peek>
=cut
sub peek {
	my ($self, $count) = @_;
	my $jobs = [ map { Qless::Job->new($self->{'client'}, decode_json($_)) }
		@{ $self->{'client'}->_peek([$self->{'name'}], $count||1, Time::HiRes::time) } ];
	if (!defined $count) {
		return scalar @{ $jobs } ?  $jobs->[0] : undef;
	}

	return @{ $jobs };
}

=head2 C<stats>

=cut

sub stats {
	my ($self, $date) = @_;
	return decode_json($self->{'client'}->_stats([], $self->{'name'}, $date || Time::HiRes::time));
}

=head2 C<length>

=cut

sub length {
	my ($self) = @_;

	my $redis = $self->{'client'}->{'redis'};
	my $sum = 0;
	my $sum_cb = sub { $sum += shift };

	$redis->zcard('ql:q:'.$self->{'name'}.'-locks',     $sum_cb);
	$redis->zcard('ql:q:'.$self->{'name'}.'-work',      $sum_cb);
	$redis->zcard('ql:q:'.$self->{'name'}.'-scheduled', $sum_cb);
	$redis->wait_all_responses;

	return $sum;
}

1;
