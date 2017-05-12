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

package POE::Component::MessageQueue::Storage::Complex::IdleElement;
use Heap::Elem;
use base qw(Heap::Elem);
BEGIN {eval q(use Time::HiRes qw(time))}

sub new
{
	my ($class, $id) = @_;
	my $self = bless([ @{ $class->SUPER::new($id) }, time() ], $class);
}

sub cmp
{
	my ($self, $other) = @_;
	return $self->[2] <=> $other->[2];
}

1;

package POE::Component::MessageQueue::Storage::Complex;
use Moose;
with qw(POE::Component::MessageQueue::Storage::Double);

use POE;
use Heap::Fibonacci;
BEGIN {eval q(use Time::HiRes qw(time))}

has timeout => (
	is       => 'ro',
	isa      => 'Int',
	required => 1,
);

has granularity => (
	is       => 'ro',
	isa      => 'Int',
	lazy     => 1,
	default  => sub { $_[0]->timeout / 2 },
);

has alias => (
	is       => 'ro',
	default  => 'MQ-Expire-Timer',
	required => 1,
);

has front_size => (
	is      => 'rw',
	isa     => 'Int',
	default => 0,
	traits  => ['Number'],
	handles => {
		'more_front' => 'add',
		'less_front' => 'sub',
	},
);

has front_max => (
	is       => 'ro',
	isa      => 'Int', 
	required => 1,
);

has front_expirations => (
	is      => 'ro', 
	isa     => 'HashRef[Num]',
	default => sub { {} },
	traits  => ['Hash'],
	handles => {
		'expire_from_front'       => 'set',
		'delete_front_expiration' => 'delete',
		'clear_front_expirations' => 'clear',
		'count_front_expirations' => 'count',
		'front_expiration_pairs'  => 'kv',
	},	
);

has nonpersistent_expirations => (
	is => 'ro',
	isa => 'HashRef',
	default => sub { {} },
	traits  => ['Hash'],
	handles => {
		'expire_nonpersistent'            => 'set',
		'delete_nonpersistent_expiration' => 'delete',
		'clear_nonpersistent_expirations' => 'clear',
		'count_nonpersistent_expirations' => 'count',
		'nonpersistent_expiration_pairs'  => 'kv',
	},
);

sub count_expirations 
{
	my $self = $_[0];
	return $self->count_nonpersistent_expirations +
	       $self->count_front_expirations;
}

has idle_hash => (
	is => 'ro',
	isa => 'HashRef',
	default   => sub { {} },
	traits  => ['Hash'],
	handles => {
		'_hashset_idle' => 'set',
		'get_idle'      => 'get',
		'delete_idle'   => 'delete',
		'clear_idle'    => 'clear',
	},
);

has idle_heap => (
	is => 'ro',
	isa => 'Heap::Fibonacci',
	lazy => 1,
	default => sub { Heap::Fibonacci->new },
	clearer => 'reset_idle_heap',
);

sub set_idle
{
	my ($self, @ids) = @_;

	my %idles = map {($_ => 
		POE::Component::MessageQueue::Storage::Complex::IdleElement->new($_)
	)} @ids;

	$self->_hashset_idle(%idles);
	$self->idle_heap->add($_) foreach (values %idles);
}

around delete_idle => sub {
	my $original = shift;
	$_[0]->idle_heap->delete($_) foreach ($original->(@_));
};

after clear_idle => sub {$_[0]->reset_idle_heap()};

has shutting_down => (
	is       => 'rw',
	default  => 0, 
);

after remove => sub {
	my ($self, $arg, $callback) = @_;
	my $aref = (ref $arg eq 'ARRAY') ? $arg : [$arg];
	my @ids = (grep $self->in_front($_), @$aref) or return;

	$self->delete_idle(@ids);
	$self->delete_front_expiration(@ids);
	$self->delete_nonpersistent_expiration(@ids);

	my $sum = 0;
	foreach my $info ($self->delete_front(@ids))
	{
		$sum += $info->{size} if $info;
	}
	$self->less_front($sum);
};

after empty => sub {
	my ($self) = @_;
	$self->clear_front();
	$self->clear_idle();
	$self->clear_front_expirations();
	$self->clear_nonpersistent_expirations();
	$self->front_size(0);
};

after $_ => sub {$_[0]->_activity($_[1])} foreach qw(claim get);

around claim_and_retrieve => sub {
	my $original = shift;
	my $self = $_[0];
	my $callback = pop;
	$original->(@_, sub {
		if (my $msg = $_[0])
		{
			$self->_activity($msg->id);
		}
		goto $callback;
	});
};

sub _activity
{
	my ($self, $arg) = @_;
	my $aref = (ref $arg eq 'ARRAY' ? $arg : [$arg]);
	
	my $time = time();
	foreach my $elem (grep {$_} $self->get_idle(@$aref))
	{
		# we can't just decrease_key, the values get bigger as we go.
		$self->idle_heap->delete($elem);
		$elem->[2] = $time;
		$self->idle_heap->add($elem);
	}
}

sub BUILD 
{
	my $self = shift;
	POE::Session->create(
		object_states => [ $self => [qw(_expire)] ],
		inline_states => {
			_start => sub {
				$poe_kernel->alias_set($self->alias);
			},
			_check => sub {
				$poe_kernel->delay(_expire => $self->granularity);
			},
		},
	);
	$self->children({FRONT => $self->front, BACK => $self->back});
	$self->add_names('COMPLEX');
}

sub store
{
	my ($self, $message, $callback) = @_;
	my $id = $message->id;

	$self->more_front($message->size);
	$self->set_front($id => {persisted => 0, size => $message->size});
	$self->set_idle($id);

	# Move a bunch of messages to the backstore to keep size respectable
	my (@bump, %need_persist);
	while($self->front_size > $self->front_max)
	{
		my $top = $self->idle_heap->extract_top or last;
		my $id = $top->val;
		$need_persist{$id} = 1 unless $self->in_back($id);
		$self->less_front($self->delete_front($id)->{size});
		push(@bump, $id);
	}

	if(@bump)
	{
		my $idstr = join(', ', @bump);
		$self->log(info => "Bumping ($idstr) off the frontstore.");
		$self->delete_idle(@bump);
		$self->delete_front_expiration(@bump);
		$self->front->get(\@bump, sub {
			my $now = time();
			$self->front->remove(\@bump);
			$self->back->store($_) foreach 
				grep { $need_persist{$_->id} } 
				grep { !$_->has_expiration or $now < $_->expire_at } 
				grep { $_->persistent || $_->has_expiration }
				@{ $_[0] }; 
		});
	}

	if ($message->persistent)
	{
		$self->expire_from_front($id, time() + $self->timeout);
	}
	elsif ($message->has_expiration)
	{
		$self->expire_nonpersistent($id, $message->expire_at);
	}

	$self->front->store($message, $callback);
	$poe_kernel->post($self->alias, '_check') if ($self->count_expirations == 1);
}

sub _is_expired
{
	my $now = time();
	map  {$_->[0]}
	grep {$_->[1] <= $now}
	@_;
}

sub _expire
{
	my ($self, $kernel) = @_[OBJECT, KERNEL];

	return if $self->shutting_down;

	if (my @front_exp = _is_expired($self->front_expiration_pairs))
	{
		my $idstr = join(', ', @front_exp);
		$self->log(info => "Pushing expired messages ($idstr) to backstore.");
		$_->{persisted} = 1 foreach $self->get_front(@front_exp);
		$self->delete_front_expiration(@front_exp);

		$self->front->get(\@front_exp, sub {
			# Messages in two places is dangerous, so we are careful!
			$self->back->store($_->clone) foreach (@{$_[0]});
		});
	}

	if (my @np_exp = _is_expired($self->nonpersistent_expiration_pairs))
	{
		my $idstr = join(', ', @np_exp);
		$self->log(info => "Nonpersistent messages ($idstr) have expired.");
		my @remove = grep { $self->in_back($_) } @np_exp;
		$self->back->remove(\@remove) if (@remove);
		$self->delete_nonpersistent_expiration(@np_exp);
	}

	$kernel->yield('_check') if ($self->count_expirations);
}

sub storage_shutdown
{
	my ($self, $complete) = @_;

	$self->shutting_down(1);

	# shutdown our check messages session
	$poe_kernel->alias_remove($self->alias);

	$self->front->get_all(sub {
		my $message_aref = $_[0];

		my @messages = grep {$_->persistent && !$self->in_back($_)}
		               @$message_aref;
		
		$self->log(info => 'Moving all messages into backstore.');
		$self->back->store($_) foreach @messages;
		$self->front->empty(sub {
			$self->front->storage_shutdown(sub {
				$self->back->storage_shutdown($complete);
			});
		});
	});
}

1;

__END__

=pod

=head1 NAME

POE::Component::MessageQueue::Storage::Complex -- A configurable storage
engine that keeps a front-store (something fast) and a back-store (something
persistent), only storing messages in the back-store after a configurable
timeout period.

=head1 SYNOPSIS

  use POE;
  use POE::Component::MessageQueue;
  use POE::Component::MessageQueue::Storage::Complex;
  use strict;

  POE::Component::MessageQueue->new({
    storage => POE::Component::MessageQueue::Storage::Complex->new({
      timeout      => 4,
      granularity  => 2,

      # Only allow the front store to grow to 64Mb
      front_max => 64 * 1024 * 1024,

      front => POE::Component::MessageQueue::Storage::Memory->new(),
      # Or, an alternative memory store is available!
      #front => POE::Component::MessageQueue::Storage::BigMemory->new(),

      back => POE::Component::MessageQueue::Storage::Throttled->new({
        storage => My::Persistent::But::Slow::Datastore->new()

        # Examples include:
        #storage => POE::Component::MessageQueue::Storage::DBI->new({ ... });
        #storage => POE::Component::MessageQueue::Storage::FileSystem->new({ ... });
      })
    })
  });

  POE::Kernel->run();
  exit;

=head1 DESCRIPTION

The idea of having a front store (something quick) and a back store (something
persistent) is common and recommended, so this class exists as a helper to
implementing that pattern.

The front store acts as a cache who's max size is specified by front_max.
All messages that come in are added to the front store.  Messages are only
removed after having been successfully delivered or when pushed out of the
cache by newer messages.

Persistent messages that are not removed after the number of seconds specified
by timeout are added to the back store (but not removed from the front store).
This optimization allows for the possibility that messages will be handled
before having been persisted, reducing the load on the back store.

Non-persistent messages will be discarded when eventually pushed off the front
store, unless the I<expire-after> header is specified, in which case they may
be stored on the back store inorder to keep around them long enough.
Non-persistent messages on the back store which are passed their expiration
date will be periodically cleaned up.

=head1 CONSTRUCTOR PARAMETERS

=over 2

=item timeout => SCALAR

The number of seconds after a message enters the front-store before it
expires.  After this time, if the message hasn't been removed, it will be
moved into the backstore.

=item granularity => SCALAR

The number of seconds to wait between checks for timeout expiration.

=item front_max => SCALAR

The maximum number of bytes to allow the front store to grow to.  If the front
store grows to big, old messages will be "pushed off" to make room for new
messages.

=item front => SCALAR

An optional reference to a storage engine to use as the front store instead of
L<POE::Component::MessageQueue::Storage::BigMemory>.

=item back => SCALAR

Takes a reference to a storage engine to use as the back store.

Using L<POE::Component::MessageQueue::Storage::Throttled> to wrap your main
storage engine is highly recommended for the reasons explained in its specific
documentation.

=back

=head1 SUPPORTED STOMP HEADERS

=over 4

=item B<persistent>

I<Fully supported>.

=item B<expire-after>

I<Fully Supported>.

=item B<deliver-after>

I<Fully Supported>.

=back

=head1 SEE ALSO

L<POE::Component::MessageQueue::Storage::Complex::Default> - The most common case.  Based on this storage engine.

L<POE::Component::MessageQueue>,
L<POE::Component::MessageQueue::Storage>,
L<POE::Component::MessageQueue::Storage::Double>

I<Other storage engines:>

L<POE::Component::MessageQueue::Storage::Default>,
L<POE::Component::MessageQueue::Storage::Memory>,
L<POE::Component::MessageQueue::Storage::BigMemory>,
L<POE::Component::MessageQueue::Storage::FileSystem>,
L<POE::Component::MessageQueue::Storage::DBI>,
L<POE::Component::MessageQueue::Storage::Generic>,
L<POE::Component::MessageQueue::Storage::Generic::DBI>,
L<POE::Component::MessageQueue::Storage::Throttled>
L<POE::Component::MessageQueue::Storage::Default>

=cut
