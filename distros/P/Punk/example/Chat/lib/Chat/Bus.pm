package Chat::Bus;

use strict;
use warnings;
use POSIX ();
use File::Raw::JSON ();
use Punk::WebSocket::Room ();

# The seam between the two halves of the demo: the WebSocket controller and
# the API controller both publish through here, so a message typed into the
# browser and a message POSTed to /api/rooms/lobby/messages arrive at every
# connected client in exactly the same shape.
#
# A Punk room is per worker - it holds the connections this worker accepted
# and nothing else. That is why bin/punk-chat runs a single worker: with
# several, an API POST handled by worker 2 would broadcast only to the
# sockets worker 2 happens to own. Fanning out across workers is a message
# bus (Redis, a hub socket), which Punk deliberately does not pretend to be.

sub room_name {
    my ($name) = @_;
    $name = '' unless defined $name;
    $name = lc $name;
    $name =~ s/[^a-z0-9-]//g;
    $name =~ s/\A-+//;
    return length $name ? substr($name, 0, 32) : 'lobby';
}

sub nick {
    my ($name) = @_;
    $name = '' unless defined $name;
    $name =~ s/\A\s+|\s+\z//g;
    $name =~ s/[[:cntrl:]]//g;
    return length $name ? substr($name, 0, 32)
                        : sprintf 'anon-%04d', int rand 10_000;
}

sub now { POSIX::strftime('%Y-%m-%dT%H:%M:%SZ', gmtime) }

sub room { Punk::WebSocket::Room->named('chat:' . $_[0]) }

sub encode { File::Raw::JSON::file_json_encode($_[0]) }

# One JSON event to every open socket in the room, optionally skipping one
# (the sender). The frame is encoded once and the same bytes are queued to
# each member. Returns the number of sockets written to.
sub publish {
    my ($name, $event, $except) = @_;
    return room($name)->broadcast(encode($event), $except);
}

sub connected { scalar room($_[0])->clients }

# The wire shape of one message, shared by the history replay, the live
# broadcast and the API's JSON responses.
sub message_event {
    my ($row) = @_;
    return {
        type    => 'message',
        id      => $row->{id},
        room    => $row->{room},
        nick    => $row->{nick},
        body    => $row->{body},
        created => $row->{created},
    };
}

1;
