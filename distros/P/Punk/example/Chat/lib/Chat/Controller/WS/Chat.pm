package Chat::Controller::WS::Chat;

use strict;
use warnings;
use parent 'Punk::Controller';
use File::Raw::JSON ();
use Chat::Bus ();

# The WebSocket half. join_room is called with the context AND the
# connection, once the upgrade handshake has been validated and answered;
# it wires the events it wants and returns. From there the connection lives
# on the worker's event loop - framing, ping/pong and the closing handshake
# run in C, and Perl is reached only when a whole message has arrived.

sub join_room {
    my ($c, $ws) = @_;

    # Read everything off the context now, while the request is still a
    # request: the callbacks below outlive it, so they close over plain
    # values and the per-worker model instance rather than over $c.
    my $room  = Chat::Bus::room_name($c->param('room'));
    my $nick  = Chat::Bus::nick($c->param('nick'));
    my $model = $c->model('Message');
    my $bus   = Chat::Bus::room($room);

    $ws->on(open => sub {
        my ($ws) = @_;
        $bus->join($ws);

        # backlog to this socket only
        $ws->send(Chat::Bus::encode({
            type     => 'welcome',
            room     => $room,
            nick     => $nick,
            protocol => $ws->protocol,
            messages => [ map Chat::Bus::message_event($_),
                          @{ $model->recent($room, 50) } ],
        }));

        Chat::Bus::publish($room, {
            type      => 'presence',
            event     => 'join',
            nick      => $nick,
            connected => Chat::Bus::connected($room),
            created   => Chat::Bus::now(),
        });
    });

    $ws->on(message => sub {
        my ($ws, $text) = @_;

        my $in = eval { File::Raw::JSON::file_json_decode($text) };
        return _oops($ws, 'that was not JSON') if $@ || ref $in ne 'HASH';

        my $body = $in->{text};
        return _oops($ws, 'say something') unless defined $body;
        $body =~ s/\A\s+|\s+\z//g;
        return _oops($ws, 'say something') unless length $body;
        return _oops($ws, 'that is over 1000 characters')
            if length $body > 1000;

        # Straight through the model: validated against the field schema,
        # stored, then fanned out to every socket in the room - including
        # this one, so the sender sees the id and timestamp the row got.
        my $row = eval {
            $model->create({ room => $room, nick => $nick, body => $body,
                             created => Chat::Bus::now() });
        };
        return _oops($ws, 'the message was rejected') if $@ || !$row;

        Chat::Bus::publish($room, Chat::Bus::message_event($row));
    });

    $ws->on(close => sub {
        my ($ws) = @_;
        $bus->leave($ws);
        Chat::Bus::publish($room, {
            type      => 'presence',
            event     => 'part',
            nick      => $nick,
            connected => Chat::Bus::connected($room),
            created   => Chat::Bus::now(),
        });
    });

    return;
}

# A handler that dies does not take the worker down - the error event fires
# and the connection closes with 1011 - but a bad message from one client is
# not an error, so it is answered rather than thrown.
sub _oops {
    my ($ws, $message) = @_;
    $ws->send(Chat::Bus::encode({ type => 'error', message => $message }));
    return;
}

1;
