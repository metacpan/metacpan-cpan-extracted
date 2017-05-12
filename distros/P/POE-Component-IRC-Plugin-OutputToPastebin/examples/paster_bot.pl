#!/usr/bin/env perl

use strict;
use warnings;

use lib qw(../lib  lib);
use POE qw(Component::IRC  Component::IRC::Plugin::OutputToPastebin);

my $irc = POE::Component::IRC->spawn(
    nick        => 'PasterBot',
    server      => 'irc.freenode.net',
    port        => 6667,
    ircname     => 'Paster BOT',
);

POE::Session->create(
    package_states => [
        main => [ qw(_start irc_001 irc_public) ],
    ],
);

$poe_kernel->run;

sub _start {
    $irc->yield( register => 'all' );

    $irc->plugin_add(
        'Paster' =>
            POE::Component::IRC::Plugin::OutputToPastebin->new(debug=>1)
    );

    $irc->yield( connect => {} );
}

sub irc_001 {
    $irc->yield( join => '#zofbot' );
}

sub irc_public {
    $irc->yield( privmsg => '#zofbot' =>
        'OH HAI! [irc_to_pastebin]sorry just testing this plugin :)'
    );
}
