#!/usr/bin/env perl

use strict;
use warnings;

# VERSION

use lib qw(lib ../lib);
use POE qw(Component::IRC  Component::IRC::Plugin::Fortune);

my $irc = POE::Component::IRC->spawn(
    nick        => 'FortuneBot',
    server      => 'irc.freenode.net',
    port        => 6667,
    ircname     => 'FortuneBot',
);

POE::Session->create(
    package_states => [
        main => [ qw(_start irc_001) ],
    ],
);

$poe_kernel->run;

sub _start {
    $irc->yield( register => 'all' );

    $irc->plugin_add(
        'fortune' =>
            POE::Component::IRC::Plugin::Fortune->new
    );

    $irc->yield( connect => {} );
}

sub irc_001 {
    $irc->yield( join => '#zofbot' );
}

