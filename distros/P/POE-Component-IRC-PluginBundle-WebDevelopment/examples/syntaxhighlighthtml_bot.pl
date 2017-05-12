#!/usr/bin/env perl

use strict;
use warnings;

# VERSION

use lib qw(lib ../lib);
use POE qw(
    Component::IRC
    Component::IRC::Plugin::OutputToPastebin
    Component::IRC::Plugin::Syntax::Highlight::HTML
);

my $irc = POE::Component::IRC->spawn(
    nick        => 'HTMLHighlighterBot',
    server      => 'irc.freenode.net',
    port        => 6667,
    ircname     => 'HTMLHighlighterBot',
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
        'Paster' =>
            POE::Component::IRC::Plugin::OutputToPastebin->new
    );

    $irc->plugin_add(
        'HTMLHighlighter' =>
            POE::Component::IRC::Plugin::Syntax::Highlight::HTML->new
    );

    $irc->yield( connect => {} );
}

sub irc_001 {
    $_[KERNEL]->post( $_[SENDER] => join => '#zofbot' );
}

