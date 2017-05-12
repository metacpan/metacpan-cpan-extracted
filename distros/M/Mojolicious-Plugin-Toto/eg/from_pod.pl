#!/usr/bin/env perl

use Mojolicious::Lite;

plugin 'toto' =>
        nav => [ qw{brewery pub beer} ],
        sidebar => {
            brewery => [ qw{brewery/list brewery/search brewery} ],
            pub     => [ qw{pub/list pub/search pub} ],
            beer    => [ qw{beer/list beer/search beer} ],
        },
        tabs => {
            brewery => [qw/view edit delete/],
            pub     => [qw/view edit delete/],
            beer    => [qw/view edit delete/],
        };

app->start;


