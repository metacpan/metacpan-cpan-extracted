package Myriad::Transport::Memory;

our $VERSION = '1.001'; # VERSION
# AUTHORTIY

use strict;
use warnings;

=head1 NAME

Myriad::Transport::Memory - In-Memory data layer that mimics Redis behaviour..

=head1 SYNOPSIS

  my $transport = Myriad::Transport::Memory->new();

  $transport->publish('channel_name', 'event...');

=head1 DESCRIPTION

=cut

use Ryu::Async;

use Myriad::Class extends => qw(IO::Async::Notifier);
use Myriad::Exception::Builder category => 'memory_transport';

=head1 Exceptions

=cut

=head2 StreamNotFound

Thrown when the operation requires the stream to be
created beforehand but the stream is not currently available.

=cut

declare_exception 'StreamNotFound' => (
    message => 'The given stream does not exist'
);

=head2 GroupExists

Thrown when the user is trying to re-create a group
but the operation doesn't allow that.

=cut

declare_exception 'GroupExists' => (
    message => 'The given group name already exists'
);

=head2 GroupNotFound

Thrown when the operation requires the group to be
exist but it's not.

=cut

declare_exception 'GroupNotFound' => (
    message => 'The given group does not exist'
);

has $ryu;
has $streams;
has $channels;

BUILD {
    $streams = {};
    $channels = {};
}

=head2 create_stream

Creats an empty stream.

=over 4

=item * C<stream_name> - The name of the stream.

=back

=cut

async method create_stream ($stream_name) {
    return if $streams->{$stream_name};
    $streams->{$stream_name} = {current_id => 0, data => {}};
}

=head2 stream_info

Return stream details

=over 4

=item * C<stream_name> - The name of the stream.

=back

=cut

async method stream_info($stream_name) {
    return $streams->{$stream_name}
        // Myriad::Exception::Transport::Memory::StreamNotFound->throw(reason => 'Stream should exist before creating new consumer group');
}

=head2 add_to_stream

Adds a new item to a stream, if the stream doesn't exist it'll be created.

=over 4

=item * C<stream_name> - The name of the stream.

=item * C<data> - A perl hash that contains the user data.

=back

=cut

async method add_to_stream ($stream_name, %data) {
    my ($id, $stream) = (0, undef);
    if ($stream = $streams->{$stream_name}) {
        $id = ++$stream->{current_id} if $stream->{data}->%*;
    } else {
        await $self->create_stream($stream_name);
    }

    $streams->{$stream_name}->{data}->{$id} = { data => \%data };
    return $id;
}

=head2 create_consumer_group

Creates a consumer group for a given stream.

=over 4

=item * C<stream_name> - The name of the stream.

=item * C<group_name> - The name of the group that is going to be created.

=item * C<offset> - If set the group will see this value as the first message in the stream.

=item * C<make_stream> - If set and the stream doesn't exist it'll be created.

=back

=cut

async method create_consumer_group ($stream_name, $group_name, $offset = 0, $make_stream = 0) {
    await $self->create_stream($stream_name) if $make_stream;
    my $stream = $streams->{$stream_name} // Myriad::Exception::Transport::Memory::StreamNotFound->throw(reason => 'Stream should exist before creating new consumer group');
    $stream->{groups}->{$group_name} = {pendings => {}, cursor => $offset} unless exists $stream->{groups}{$group_name};
}

=head2 read_from_stream

Read elements from the stream.

This operation is stateless you can re-read the same message
as long as it exists in the stream.

=over 4

=item * C<stream_name> - The name of the stream.

=item * C<offset> - The number of messages to skip.

=item * C<count> - The limit of messages to be received.

=back

=cut

async method read_from_stream ($stream_name, $offset = 0 , $count = 50) {
    my $stream = $streams->{$stream_name} // return ();
    return {
        map { $_ => $stream->{data}->{$_}->{data} } ($offset..$offset+$count - 1)
    };
}


=head2 read_from_stream_by_consumer

Read elements from the stream for the given group.

This operation is stateful if the message read by a consumer "A"
it won't be available for consumer "B" also consumer "A" won't be able
to re-read the message using this call.

This is not exaclty how Redis works but it covers our need at the moment.

=over 4

=item * C<stream_name> - The name of the stream should exist before calling this sub.

=item * C<group_name> - The name of the group should exist before callingg this sub.

=item * C<consumer_name> - The current consumer name, will be used to keep tracking of pendign messages.

=item * C<offset> - If given the consumer can skip the given number of messages.

=item * C<count> - The limit of messages to be received.

=back

=cut

async method read_from_stream_by_consumer ($stream_name, $group_name, $consumer_name, $offset = 0, $count = 50) {
    my ($stream, $group) = $self->get_stream_group($stream_name, $group_name);
    my $group_offset = $offset + $group->{cursor};
    my %messages;
    my $read_count = 0;
    for my $i ($group_offset..$group_offset+$count - 1) {
        if (my $message = $stream->{data}->{$i}) {
            $messages{$i} = $message->{data};
            $group->{pendings}->{$i} = {since => time, consumer => $consumer_name, delivery_count => 0};
            $read_count++;
        }
    }

    $group->{cursor} += $offset + $read_count;

    return \%messages;
}

=head2 pending_stream_by_consumer

Read pending elements from the stream for the given group.

This operation will return messages consumed but not yet acknowledged only.
It will return items regardless of their consumer.

=over 4

=item * C<stream_name> - The name of the stream should exist before calling this sub.

=item * C<group_name> - The name of the group should exist before callingg this sub.

=item * C<consumer_name> - The current consumer name, will be used to keep tracking of pendign messages.

=item * C<offset> - If given the consumer can skip the given number of messages.

=item * C<count> - The limit of messages to be received.

=back

=cut

async method pending_stream_by_consumer ($stream_name, $group_name, $consumer_name, $offset = 0, $count = 10) {
    my ($stream, $group);
    try {
        ($stream, $group) = $self->get_stream_group($stream_name, $group_name);
    } catch ($e) {
        return {};
    }
    my %messages;
    for my $i (keys $group->{pendings}->%*) {
        if (my $message = $stream->{data}->{$i}) {
            $messages{$i} = $message->{data};
        }
    }

    return \%messages;
}
=head2 ack_message

Remove a message from the pending list.

It's safe to call this method multiple time even if the message doesn't exist.

=over 4

=item * C<stream_name> - The name of the stream.

=item * C<group_name> - The name of group that has this message as pending.

=item * C<message_id> - The Id of the message that we want to acknowledge.

=back

=cut

async method ack_message ($stream_name, $group_name, $message_id) {
    my ($stream, $group) = $self->get_stream_group($stream_name, $group_name);
    delete $group->{pendings}->{$message_id};
}

=head2 claim_message

Re-assign a message to another consumer.

It'll return the full message.

=over 4

=item * C<stream_name> - The name of the stream.

=item * C<group_name> - The name of the group that has the message as pending.

=item * C<consumer_name> - The name of the new consumer.

=item * C<message_id> - The id of the message to be claimed.

=back

=cut

async method claim_message ($stream_name, $group_name, $consumer_name, $message_id) {
    my ($stream, $group) = $self->get_stream_group($stream_name, $group_name);
    if (my $info = $group->{pendings}->{$message_id}) {
        $info = {since => time, consumer => $consumer_name, delivery_count => $info->{delivery_count}++};
        return $stream->{data}->{$message_id}->%*;
    } else {
        return ();
    }
}

=head2 publish

Publish a message, if no consumer exists the message will be lost.

=over 4

=item * C<channel_name> - The name of the channel that the message will be published to.

=item * C<message> - A scalar that is going to be published.

=back

=cut

async method publish ($channel_name, $message) {
    my $subscribers = $channels->{$channel_name};

    for my $subscriber ($subscribers->@*) {
        $subscriber->emit($message);
    }

    return length $subscribers;
}

=head2 subscribe

Subscribe to a channel by optaining a L<Ryu::Source> that'll receive events.

=over 4

=item * C<channel_name> - The name of the channel.

=back

=cut

async method subscribe ($channel_name) {
    $channels->{$channel_name} = [] unless exists $channels->{$channel_name};
    my $sink = $ryu->sink;
    push $channels->{$channel_name}->@*, $sink;
    return $sink->source;
}


=head2 stream_groups_info

Get information about the stream's groups.

=cut

async method stream_groups_info ($stream_name) {
    my $stream = $streams->{$stream_name} // Myriad::Exception::Transport::Memory::StreamNotFound->throw();
    my $info = [];
    for my $group (keys $stream->{groups}->%*) {
        my $group_info = { name => $group };
        # We don't keep track of consumers yet
        $group_info->{consumers} = 0;
        $group_info->{pending} = +(keys $stream->{groups}->{$group}->{pendings}->%*);
        $group_info->{'last-delivered-id'} = $stream->{groups}->{$group}->{cursor};
        push $info->@*, $group_info;
    }

    return $info;
}

=head2 exists

Checks if a  given key exists or not.

=cut

async method exists ($key) {
    return exists $streams->{$key} || exists $channels->{$key};
}

method get_stream_group ($stream_name, $group_name) {
    my $stream = $streams->{$stream_name} // Myriad::Exception::Transport::Memory::StreamNotFound->throw();
    my $group = $stream->{groups}->{$group_name} // Myriad::Exception::Transport::Memory::GroupNotFound->throw();
    return ($stream, $group);
}

method _add_to_loop($loop) {
    $self->add_child($ryu = Ryu::Async->new());
    $self->next::method($loop);
}

1;

