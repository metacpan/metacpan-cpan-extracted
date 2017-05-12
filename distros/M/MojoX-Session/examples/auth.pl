#!/usr/bin/env perl

use FindBin;

use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../t/lib";

use Mojolicious::Lite;

plugin session => {store => 'dummy', expires_delta => 5};

get '/' => sub {
    my $c = shift;

    my $message = '';

    my $session = $c->stash('session');

    # Check if we already have a session
    if ($session->load) {

        # Browser shouldn't send a cookie, but if it does, we are ready!
        if ($session->is_expired) {

            # Delete session from the store
            $session->flush;

            # Create a new session
            $session->create;

            $message = 'Cheater!';
        }
        else {
            $message = 'Welcome back. Wait 5 secs and refresh!';

            # Extend the session
            $session->extend_expires;
        }
    }
    else {

        # Create a new session
        $session->create;

        $message = 'Welcome. Refresh the page!';
    }

    $c->res->code(200);
    $c->res->body("Session state: $message\n");
} => 'root';

shagadelic('daemon');

1;
