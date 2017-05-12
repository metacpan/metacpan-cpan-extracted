# $Id$
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

package POE::Component::MessageQueue::Statistics;
use strict;
use warnings;

sub new
{
	my $class = shift;
	my $self  = bless {
		statistics => {
			ID => sprintf(
				"POE::Component::MessageQueue version %s (PID: $$)",
				# hide from PAUSE
				join('::', '$POE', 'Component', 'MessageQueue', 'VERSION') 
			),
			total_stored  => 0,
			total_sent    => 0,
			subscriptions => 0,
			queues        => {},
		},
		store_info => {},
		publishers => [],
	}, $class;

	$self;
}

sub register
{
	my ($self, $mq) = @_;
	$mq->register_event( $_, $self ) 
		for qw(store dispatch remove recv subscribe unsubscribe);
}

sub add_publisher {
  my ($self, $pub) = @_; 
  push(@{$self->{publishers}}, $pub);
}

sub get_queue
{
	my ($self, $name) = @_;

	my $queue = $self->{statistics}{queues}{$name};

	unless ($queue)
	{
		$queue = $self->{statistics}{queues}{$name} = {};
		$queue->{$_} = 0 foreach qw(
			sent          stored
			total_stored  total_sent
			total_recvd   avg_secs_stored  avg_size_recvd
		);
	}

	return $queue;
}

sub get_topic
{
	my ($self, $name) = @_;
	my $topic = $self->{statistics}{topics}{$name};

	unless ($topic)
	{
		$topic = $self->{statistics}{topics}{$name} = {};
		$topic->{$_} = 0 foreach qw(sent total_sent total_recvd avg_size_recvd);
	}

	return $topic;
}

sub shutdown 
{
	my $self = shift;
	foreach my $pub (@{$self->{publishers}}) 
	{
		$pub->shutdown();
	}
}

sub notify
{
	my ($self, $event, $data) = @_;
	if(my $method = $self->can("notify_$event")) 
	{
		$method->($self, $data);
	}
	else
	{
		die "Tried to notify $event, which has no handler.";
	}
}

sub notify_store
{
	my ($self, $message) = @_;
	my $qname = $message->destination;

	return unless $qname =~ m(/queue/(.*));
	$qname = $1;

	$self->{store_info}->{$message->id} = {
		qname     => $qname,
		timestamp => time(),
	};

	my $global = $self->{statistics};
	$global->{total_stored}++;

	my $stats = $self->get_queue($qname);
	$stats->{stored}++;
	$stats->{total_stored}++;
	$stats->{last_stored} = scalar localtime();
}

sub reaverage {
	my ($total, $average, $size) = @_;
	return 0 if ($total <= 0);
	return ($average * ($total - 1) + $size) / $total;
}

sub get_destination
{
	my ($self, $data) = @_;
	my $d = $data->{destination};
	if ($d->name =~ m{/.*/(.*)})
	{
		return $d->isa('POE::Component::MessageQueue::Queue') ?
		                                 $self->get_queue($1) :
		                                 $self->get_topic($1) ;
	}
	return;
}

sub notify_recv
{
	my ($self, $data) = @_;
	my $stats = $self->get_destination($data);
	$stats->{total_recvd}++;

	# recalc the average
	$stats->{avg_size_recvd} = reaverage(
		$stats->{total_recvd},
		$stats->{avg_size_recvd},
		$data->{message}->size,
	);
}

sub notify_dispatch
{
	my ($self, $data) = @_;

	my $global = $self->{statistics};
	$global->{total_sent}++;

	my $stats = $self->get_destination($data);
	$stats->{total_sent}++;
	$stats->{sent}++;
	$stats->{last_sent} = scalar localtime();
}

sub notify_remove {
	my ($self, $id) = @_;
	use YAML;

	if (my $store_info = delete $self->{store_info}->{$id})
	{
		my $stats = $self->get_queue($store_info->{qname});
		$stats->{stored}--;
		$stats->{avg_secs_stored} = reaverage(
			$stats->{total_stored},
			$stats->{avg_secs_stored},
			(time() - $store_info->{timestamp})
		);
	}
}

sub notify_subscribe
{
	my ($self, $data) = @_;

	# Global
	my $h = $self->{statistics};
	$h->{subscriptions}++;

	# Per-queue
	my $stats = $self->get_destination($data);
	$stats->{subscriptions}++;
}

sub notify_unsubscribe
{
	my ($self, $data) = @_;

	# Global
	my $h = $self->{statistics};
	$h->{subscriptions}--;

	# Per-queue
	my $stats = $self->get_destination($data);
	$stats->{subscriptions}--;
}

sub notify_pump {}

1;

__END__

=head1 NAME

POE::Component::MessageQueue::Statistics - Gather MQ Usage Statistics 

=head1 SYNOPSIS

	my $statistics = POE::Component::MessageQueue::Statistics->new();
	$mq->register( $statistics );

=head1 DESCRIPTION

POE::Component::MessageQueue::Statistics is a simple observer that receives
events from the main POE::Component::MessageQueue object to collect usage
statistics.

By itself it will only *gather* statistics, and will not output anything.

To enable outputs, you need to create a separate Publish object:

	POE::Component::MessageQueue::Statistics::Publish::YAML->new(
		output => \*STDERR,
		statistics => $statistics
	);

Please refer to L<POE::Component::MessageQueue::Statistics::Publish> for details
on how to enable output

=head1 SEE ALSO

L<POE::Component::MessageQueue::Statistics::Publish>,
L<POE::Component::MessageQueue::Statistics::Publish::YAML>

=head1 AUTHOR

Daisuke Maki E<lt>daisuke@endeworks.jpE<gt>

=cut
