#
# Copyright 2007 Paul Driver <frodwith@gmail.com>
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

package POE::Component::MessageQueue::Storage::Double;
use Moose::Role;
use MooseX::MultiInitArg;

# These guys just call a method on both front and back stores and have a
# simple no-arg completion callback.  No reason to write them all!
foreach my $method (qw(empty disown_destination disown_all)) {
	__PACKAGE__->meta->add_method($method, sub {
		my $self = shift;
		my $last = pop;
		if(ref $last eq 'CODE')
		{
			my @args = @_;
			$self->front->$method(@args, sub {
				$self->back->$method(@args, $last);
			});
		}
		else
		{
			$self->front->$method(@_, $last);
			$self->back->$method(@_, $last);
		}
	});
}

with qw(POE::Component::MessageQueue::Storage);
use POE::Component::MessageQueue::Storage::BigMemory;

has front => (
	metaclass => 'MultiInitArg',
	init_args => ['front_store'],
	is        => 'ro',
	does      => qw(POE::Component::MessageQueue::Storage),
	default   => sub {POE::Component::MessageQueue::Storage::BigMemory->new()},
	required  => 1,
);

has back => (
	is        => 'ro',
	metaclass => 'MultiInitArg',
	init_args => [qw(back_store storage)],
	does      => qw(POE::Component::MessageQueue::Storage),
	required  => 1,
);

# Any true value for a given ID means the message is in the front store.
# (value may be useful data, like message size)
has front_info => (
	is => 'ro',
	isa => 'HashRef',
	default => sub { {} },
	traits  => ['Hash'],
	handles => {
		'in_front'     => 'exists',
		'get_front'    => 'get',
		'set_front'    => 'set',
		'clear_front'  => 'clear',
		'delete_front' => 'delete',
	},
);

after 'set_logger' => sub {
	my ($self, $logger) = @_;
	$self->front->set_logger($logger);
	$self->back->set_logger($logger);
};

sub in_back 
{
	my ($self, $id) = @_;
	return 1 unless $self->in_front($id);
	return $self->get_front($id)->{persisted};
}

sub _split_ids
{
	my ($self, $ids) = @_;
	my (@fids, @bids);
	foreach my $id (@$ids)
	{
		push (@fids, $id) if $self->in_front($id);
		push (@bids, $id) if $self->in_back($id);
	}
	return (\@fids, \@bids);
}

sub _doboth
{
	my ($self, $ids, $do_front, $do_back, $callback) = @_;
	my ($fids, $bids) = $self->_split_ids($ids);

	if (@$fids && @$bids)
	{
		$do_front->($fids, sub {$do_back->($bids, $callback)});
	}
	elsif(@$fids)
	{
		$do_front->($fids, $callback);
	}
	elsif(@$bids)
	{
		$do_back->($bids, $callback);
	}
	else
	{
		goto $callback;
	}
}

sub remove
{
	my ($self, $aref, $callback) = @_;
	$self->_doboth(
		$aref, 
		sub {
			my ($ids, $callback) = @_;
			$self->delete_front($ids);
			$self->front->remove($ids, $callback);
		},
		sub {
			my ($ids, $callback) = @_;
			$self->back->remove($ids, $callback);
		},
		$callback,
	);
}

sub claim
{
	my ($self, $aref, $client, $callback) = @_;
	$self->_doboth(
		$aref,
		sub {$self->front->claim($_[0], $client, $_[1])},
		sub {$self->back ->claim($_[0], $client, $_[1])},
	  $callback,
	);
}

sub get
{
	my ($self, $ids, $callback) = @_;
	my ($fids, $bids) = $self->_split_ids($ids);
	$self->front->get($fids, sub {
		goto $callback unless @$bids; # Avoid backstore call
		my $got_front = $_[0];
		$self->back->get($bids, sub {
			my $got_back = $_[0];
			push(@$got_back, @$got_front);
			goto $callback;
		});
	});
}

sub get_all
{
	my ($self, $callback) = @_;
	my %messages; # store in a hash to ensure uniqueness
	$self->front->get_all(sub {
		$messages{$_->id} = $_ foreach @{$_[0]};
		$self->back->get_all(sub {
			$messages{$_->id} = $_ foreach @{$_[0]};
			@_ = ([values %messages]);
			goto $callback;	
		});
	});
}

sub get_oldest
{
	my ($self, $callback) = @_;
	$self->front->get_oldest(sub {
		my $f = $_[0];
		$self->back->get_oldest(sub {
			my $b = $_[0];
			@_ = (
				($f && $b) ? 
				($f->timestamp < $b->timestamp ? $f : $b) :
				($f || $b)
			);
			goto $callback;
		});
	});
}

sub claim_and_retrieve
{
	my ($self, $destination, $client_id, $callback) = @_;

	$self->front->claim_and_retrieve($destination, $client_id, sub {
		if (my $msg = $_[0])
		{
			# We don't need to claim unless it's in the backstore already
			goto $callback unless ($self->in_back($msg->id));
			$self->back->claim($msg->id, $client_id, sub {
				@_ = ($msg);
				goto $callback;
			});
		}
		else
		{
			$self->back->claim_and_retrieve($destination, $client_id, sub {
				my $msg = $_[0];
				goto $callback
					if (not defined $msg or not $self->in_front($msg->id));

				$self->front->claim($msg->id, $client_id, sub {
					@_ = ($msg);
					goto $callback;
				});
			});
		}
	});
}

1;

__END__

=pod

=head1 NAME

POE::Component::MessageQueue::Storage::Double -- Stores composed of two other
stores.
 
=head1 DESCRIPTION

Refactor mercilessly, as they say.  They also say don't repeat yourself.  This
module contains functionality for any store that is a composition of two 
stores.  At least Throttled and Complex share this trait, and it doesn't make 
any sense to duplicate code between them.

=head1 CONSTRUCTOR PARAMETERS

=over 2

=item front => SCALAR

=item back => SCALAR

Takes a reference to a storage engine to use as the front store / back store.

=back

=head1 Unimplemented Methods

=over 2

=item store

This isn't implemented because Complex and Throttled differ here.  Perhaps
your storage differs here as well.  This is essentially where you specify
policy about what goes in which store.  Be sure you update the front_info hash
when you store something!

=item storage_shutdown

And this is where you specify policy about what happens when you die.  You
lucky person, you.

=back

=cut
