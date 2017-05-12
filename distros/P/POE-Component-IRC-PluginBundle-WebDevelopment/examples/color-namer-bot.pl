#!/usr/bin/env perl

use strict;
use warnings;

# VERSION

use lib qw(lib ../lib);
use POE qw(Component::IRC  Component::IRC::Plugin::ColorNamer);

my $irc = POE::Component::IRC->spawn(
    nick        => 'ColorNamerBot',
    server      => 'irc.freenode.net',
    port        => 6667,
    ircname     => 'ColorNamerBot',
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
        'ColorNamerBot' =>
            POE::Component::IRC::Plugin::ColorNamer->new
    );

    $irc->yield( connect => {} );
}

sub irc_001 {
    $irc->yield( join => '#zofbot' );
}
