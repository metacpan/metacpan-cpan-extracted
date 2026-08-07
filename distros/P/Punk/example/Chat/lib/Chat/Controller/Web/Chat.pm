package Chat::Controller::Web::Chat;

use strict;
use warnings;
use parent 'Punk::Controller';
use Chat::Bus ();

# The pages. Both render through Stencil into root/templates/layout.tmpl.

sub index {
    my ($c) = @_;
    my $rooms = $c->model('Message')->rooms;
    $_->{connected} = Chat::Bus::connected($_->{room}) for @$rooms;
    return $c->render('index', {
        title => 'Punk Chat',
        rooms => $rooms,
    });
}

sub room {
    my ($c) = @_;
    my $room = Chat::Bus::room_name($c->param('room'));

    # The canonical name may differ from what was typed (case, punctuation);
    # send the browser to the one the WebSocket route will agree with.
    return $c->redirect("/chat/$room") if $room ne ($c->param('room') // '');

    return $c->render('room', {
        title => "#$room - Punk Chat",
        room  => $room,
    });
}

1;
