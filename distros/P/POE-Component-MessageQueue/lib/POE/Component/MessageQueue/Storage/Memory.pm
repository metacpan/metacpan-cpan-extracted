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

package POE::Component::MessageQueue::Storage::Memory;
use Moose;
with qw(POE::Component::MessageQueue::Storage);

# destination => @messages
has 'messages' => (is => 'ro', default => sub { {} });

sub store
{
	my ($self, $msg, $callback) = @_;

	my $id = $msg->id;
	my $destination = $msg->destination;

	# push onto our array
	my $aref = ($self->messages->{$destination} ||= []);
	push(@$aref, $msg);
	$self->log(info => "Added $id");

	goto $callback if $callback;
}

sub _msg_foreach
{
	my ($self, $action) = @_;
	foreach my $messages_in_dest (values %{$self->messages})
	{
		foreach my $message (@$messages_in_dest)
		{
			$action->($message);
		}
	}
}

sub _msg_foreach_ids
{
	my ($self, $ids, $action) = @_;
	my %id_hash = map { ($_, 1) } (@$ids);
	$self->_msg_foreach(sub {
		my $msg = $_[0];
		$action->($msg) if (exists $id_hash{$msg->id});
	});
}

sub get
{
	my ($self, $ids, $callback) = @_;
	my @messages;
	$self->_msg_foreach_ids($ids, sub {push(@messages, $_[0])});
	@_ = (\@messages);
	goto $callback;
}

sub get_all
{
	my ($self, $callback) = @_;
	my @messages;
	$self->_msg_foreach(sub {push(@messages, $_[0])});
	@_ = (\@messages);
	goto $callback;
}

sub claim_and_retrieve
{
	my ($self, $destination, $client_id, $callback) = @_;
	my $oldest;
	my $aref = $self->messages->{$destination} || [];
	my $current_time = time();
	foreach my $msg (@$aref)
	{
		unless ($msg->claimed || ($msg->has_delay and $current_time < $msg->deliver_at) ||
		        ($oldest && $oldest->timestamp < $msg->timestamp))
		{
			$oldest = $msg;
		}
	}
	$self->_claim_it_yo($oldest, $client_id) if $oldest;
	@_ = ($oldest);
	goto $callback;
}

sub get_oldest
{
	my ($self, $callback) = @_;
	my $oldest;
	$self->_msg_foreach(sub {
		my $msg = shift;
		$oldest = $msg unless ($oldest && ($oldest->timestamp < $msg->timestamp));
	});
	@_ = ($oldest);
	goto $callback;
}

sub remove
{
	my ($self, $message_ids, $callback) = @_;
	# Stuff IDs into a hash so we can quickly check if a message is on the list
	my %id_hash = map { ($_, 1) } (@$message_ids);

	foreach my $messages (values %{$self->messages})
	{
		my $max = scalar @{$messages};

		for ( my $i = 0; $i < $max; $i++ )
		{
			my $message = $messages->[$i];
			# Check if this messages is in the "remove" list
			next unless exists $id_hash{$message->id};
			splice @$messages, $i, 1;
			$i--; $max--;
		}
	}

	goto $callback if $callback;
}

sub empty 
{
	my ($self, $callback) = @_;
	%{$self->messages} = ();
	goto $callback if $callback;
}

sub _claim_it_yo
{
	my ($self, $msg, $client_id) = @_;;
	$msg->claim($client_id);
	$self->log('info', sprintf('Message %s claimed by client %s',
		$msg->id, $client_id));
}

sub claim
{
	my ($self, $ids, $client_id, $callback) = @_;

	$self->_msg_foreach_ids($ids, sub {
		$self->_claim_it_yo($_[0], $client_id);
	});

	goto $callback if $callback;
}

sub disown_destination
{
	my ($self, $destination, $client_id, $callback) = @_;
	my $aref = $self->messages->{$destination} || [];
	$_->disown foreach grep {$_->claimed && $_->claimant eq $client_id} @$aref;

	goto $callback if $callback;
}

sub disown_all
{
	my ($self, $client_id, $callback) = @_;
	$self->_msg_foreach(sub {
		my $m = $_[0];
		$m->disown() if $m->claimed && $m->claimant eq $client_id;
	});
	goto $callback if $callback;
}

sub storage_shutdown
{
	my ($self, $callback) = @_;
	goto $callback if $callback;
}

1;

__END__

=pod

=head1 NAME

POE::Component::MessageQueue::Storage::Memory -- In memory storage engine.

=head1 SYNOPSIS

  use POE;
  use POE::Component::MessageQueue;
  use POE::Component::MessageQueue::Storage::Memory;
  use strict;

  POE::Component::MessageQueue->new({
    storage => POE::Component::MessageQueue::Storage::Memory->new()
  });

  POE::Kernel->run();
  exit;

=head1 DESCRIPTION

A storage engine that keeps all the messages in memory.  Provides no persistence
what-so-ever.

For an alternative in-memory storage engine optimized for a large number of 
messages, please see L<POE::Component::MessageQueue::Storage::BigMemory>.

I wouldn't suggest using this as your main storage engine because if messages
aren't removed by consumers, it will continue to consume more memory until it
explodes.  Check-out L<POE::Component::MessageQueue::Storage::Complex> which
can use  this module internally to keep messages in memory for a period of
time before moving them into persistent storage.

=head1 CONSTRUCTOR PARAMETERS

None to speak of!

=head1 SUPPORTED STOMP HEADERS

=over 4

=item B<persistent>

I<Ignored>.  Nothing is persistent in this store.

=item B<expire-after>

I<Ignored>.  All messages are kept until handled.

=item B<deliver-after>

I<Fully Supported>.

=back

=head1 SEE ALSO

L<POE::Component::MessageQueue::Storage::BigMemory> -- Alternative memory-based storage engine.

L<POE::Component::MessageQueue>,
L<POE::Component::MessageQueue::Storage>

I<Other storage engines:>

L<POE::Component::MessageQueue::Storage::BigMemory>,
L<POE::Component::MessageQueue::Storage::FileSystem>,
L<POE::Component::MessageQueue::Storage::DBI>,
L<POE::Component::MessageQueue::Storage::Generic>,
L<POE::Component::MessageQueue::Storage::Generic::DBI>,
L<POE::Component::MessageQueue::Storage::Throttled>,
L<POE::Component::MessageQueue::Storage::Complex>,
L<POE::Component::MessageQueue::Storage::Default>

=cut
