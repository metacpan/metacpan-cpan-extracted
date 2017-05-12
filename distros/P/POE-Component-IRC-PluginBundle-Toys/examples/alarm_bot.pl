#!/usr/bin/env perl

use strict;
use warnings;

# VERSION

use lib qw(../lib  lib);

use POE qw(Component::IRC  Component::IRC::Plugin::AlarmClock);

my $irc = POE::Component::IRC->spawn(
    nick        => 'AlarmClockBot',
    server      => 'irc.freenode.net',
    port        => 6667,
    ircname     => 'AlarmClock bot',
    plugin_debug => 1,
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
        'AlarmClock' =>
            POE::Component::IRC::Plugin::AlarmClock->new( debug => 1 )
    );

    $irc->yield( connect => {} );
}

sub irc_001 {
    $irc->yield( join => '#zofbot' );
}
