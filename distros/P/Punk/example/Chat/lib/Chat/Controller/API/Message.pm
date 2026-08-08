package Chat::Controller::API::Message;

use strict;
use warnings;
use parent 'Punk::Controller';
use Chat::Bus ();

# The API half. Nothing here declares a route, a parameter or a status
# code: openapi.json does, and Punk resolved each operationId to the method
# of the same name at boot. By the time one of these runs the request has
# already been matched, guarded, size-checked and validated against the
# spec in C, so $c->param is reading typed values that are known good.

sub listRooms {
    my ($c) = @_;
    return $c->model('Message')->rooms->then(sub {
        my ($rooms) = @_;
        $_->{connected} = Chat::Bus::connected($_->{room}) for @$rooms;
        { rooms => $rooms };
    });
}

sub getPresence {
    my ($c) = @_;
    my $room = Chat::Bus::room_name($c->param('room'));
    return { room => $room, connected => Chat::Bus::connected($room) };
}

sub listMessages {
    my ($c) = @_;
    my $room = Chat::Bus::room_name($c->param('room'));
    my $next = $c->param('next');
    return $c->model('Message')->search({ room => $room }, {
        limit => $c->param('limit') || 20,
        (defined $next && length $next ? (after => $next) : ()),
    })->then(sub {
        my ($page) = @_;
        {
            room          => $room,
            messages      => [ map Chat::Bus::message_event($_),
                               @{ $page->{rows} } ],
            has_more_data => $page->{has_more_data} ? \1 : \0,
            next          => $page->{next},
        };
    });
}

# The operation that ties the two halves together: it stores the message
# exactly as the WebSocket handler would, then publishes it to the room, so
# a curl against this endpoint lands in every open browser tab.
sub postMessage {
    my ($c) = @_;
    my $room = Chat::Bus::room_name($c->param('room'));
    my $body = $c->openapi->{body};

    $c->status(201);
    return $c->model('Message')->create({
        room    => $room,
        nick    => Chat::Bus::nick($body->{nick}),
        body    => $body->{text},
        created => Chat::Bus::now(),
    })->then(sub {
        my ($row) = @_;
        my $event = Chat::Bus::message_event($row);
        Chat::Bus::publish($room, $event);
        $event;
    });
}

# Reached only when the spec's adminToken scheme passed - the generated
# guard answered 401 otherwise, before the body was ever read.
sub clearRoom {
    my ($c) = @_;
    my $room = Chat::Bus::room_name($c->param('room'));
    my $by   = $c->stash->{auth}{adminToken}{name};

    return $c->model('Message')->purge($room)->then(sub {
        my ($n) = @_;
        Chat::Bus::publish($room, {
            type    => 'cleared',
            room    => $room,
            deleted => $n,
            by      => $by,
            created => Chat::Bus::now(),
        });
        { room => $room, deleted => $n };
    });
}

1;
