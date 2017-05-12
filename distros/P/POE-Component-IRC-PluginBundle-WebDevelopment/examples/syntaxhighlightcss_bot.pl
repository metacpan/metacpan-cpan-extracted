#!/usr/bin/env perl

use strict;
use warnings;

# VERSION

use lib qw(lib ../lib);
use POE qw(
    Component::IRC
    Component::IRC::Plugin::OutputToPastebin
    Component::IRC::Plugin::Syntax::Highlight::CSS
);

my $irc = POE::Component::IRC->spawn(
    nick        => 'CSSHighlighterBot',
    server      => 'irc.freenode.net',
    port        => 6667,
    ircname     => 'CSSHighlighterBot',
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
        'CSSHighlighter' =>
            POE::Component::IRC::Plugin::Syntax::Highlight::CSS->new
    );

    $irc->yield( connect => {} );
}

sub irc_001 {
    $_[KERNEL]->post( $_[SENDER] => join => '#zofbot' );
}

