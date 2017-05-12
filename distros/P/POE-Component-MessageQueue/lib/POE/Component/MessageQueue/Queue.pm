#
# Copyright 2007-2010 David Snopek <dsnopek@gmail.com>
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
#

package POE::Component::MessageQueue::Queue;

use POE;
use POE::Session;
use Moose;

with qw(POE::Component::MessageQueue::Destination);

sub flag { has $_[0] => (is => 'rw', default => 0) }
flag 'pumping';
flag 'pump_pending';
flag 'shutting_down';

sub stash {
	my $n = $_[0];
	has $n => (
		is      => 'rw',
		isa     => 'HashRef',
		default => sub { {} },
		traits  => ['Hash'],
		handles => {
			"set_$n"    => 'set',
			"del_$n"    => 'delete',
			"${n}_keys" => 'keys',
		}
	);
}

stash 'waiting';
stash 'serviced';

sub next_subscriber 
{
	my $self = $_[0];
	if (my @keys = $self->waiting_keys) 
	{
		my $id = pop(@keys);
		my $s = $self->del_waiting($id);
		if($s->client)
		{
		  $self->set_serviced($id, $s);
			return $s;
		}
		else
		{
			$self->delete_subscription($id);
			return $self->next_subscriber;
		}
	}
	else 
	{
		my $serviced = $self->serviced;
		$self->serviced($self->waiting);
		$self->waiting($serviced);
		return (keys %$serviced) && $self->next_subscriber;
	}
}

sub next_ready
{
  my $self = $_[0];
	my ($s, %seen);

	while ($s = $self->next_subscriber and !exists $seen{$s})
	{
		return $s if $s->ready;
		$seen{$s} = 1;
	}
	return;
}

after set_subscription => __PACKAGE__->can('set_waiting');
after delete_subscription => sub {
	my ($self, @args) = @_;
	$self->del_waiting(@args);
	$self->del_serviced(@args);
};

__PACKAGE__->meta->make_immutable();

sub BUILD
{
	my ($self, $args) = @_;
	POE::Session->create(
		object_states => [ $self => [qw(_start _shutdown _pump_state _pump_timer)]],
	);
}

sub _start
{
	my ($self, $kernel) = @_[OBJECT, KERNEL];
	$kernel->alias_set($self->name);

	$kernel->delay(_pump_timer => $self->parent->pump_frequency)
		if ($self->parent->pump_frequency);
}

sub shutdown { 
	my $self = $_[0];
	$self->shutting_down(1);
	$poe_kernel->post($self->name, '_shutdown') 
}

sub _shutdown
{
	my ($self, $kernel) = @_[OBJECT, KERNEL];
	$kernel->alias_remove($self->name);
	$kernel->alarm_remove_all();
}

# This is the pumping philosophy:  When we receive a pump request, we will
# give everyone a chance to claim a message.  If any pumps are asked for while
# this is happening, we will remember and do another pump when this one is
# finished (just one).  

# This means we're serializing claim and retrieve requests.  More work needs
# to be done to determine whether this is good or necessary.

sub is_persistent { return 1 }

sub _pump_state
{
	my $self = $_[OBJECT];
	return if $self->shutting_down;

	if (my $s = $self->next_ready)
	{
		$s->ready(0);

		$self->storage->claim_and_retrieve($self->name, $s->client->id, sub {
			if (my $msg = $_[0])
			{
				$self->dispatch_message($msg, $s);
				$poe_kernel->post($self->name, '_pump_state');
			}
			else
			{
				$s->ready(1);
				$self->_done_pumping();
			}
		});
	}
	else
	{
		$self->_done_pumping();
	}
}

sub _done_pumping
{
	my $self = $_[0];
	$self->pumping(0);
	$self->pump() if $self->pump_pending;
}

sub _pump_timer
{
	my ($self, $kernel) = @_[OBJECT, KERNEL];
	return if $self->shutting_down;

	# pump (the 1 means that we won't set pump_pending if
	# we are already in a pumping state).
	$self->pump(1);

	$kernel->delay(_pump_timer => $self->parent->pump_frequency);
}

sub pump
{
	my ($self, $skip_pending) = @_;

	if($self->pumping and not $skip_pending)
	{
		$self->pump_pending(1);
	}
	else
	{
		$self->log(debug => ' -- PUMP QUEUE: '.$self->name.' -- ');
		$self->notify('pump');
		$self->pump_pending(0);
		$self->pumping(1);
		$poe_kernel->call($self->name, '_pump_state');
	}
}

sub send
{
	my ($self, $message) = @_;
	return if $self->shutting_down;

	# If we already have a ready subscriber, we'll dispatch before we
	# store to give the subscriber a headstart on processing.
	if (not $message->has_delay and my $s = $self->next_ready)
	{
		my $mid = $message->id;
		my $cid = $s->client->id;
		if ($s->client_ack) 
		{
			$message->claim($cid);
			$self->log(info => "QUEUE: Message $mid claimed by $cid during send");
			$self->storage->store($message);
			$self->notify(store => $message);
		}
		else
		{
			$self->log(info => "QUEUE: Message $mid not stored, sent to $cid");
		}
		$self->dispatch_message($message, $s);
	}
	else
	{
		$self->storage->store($message, sub {
			$self->notify(store => $message);
			$self->pump();
		});
	}
}

1;

