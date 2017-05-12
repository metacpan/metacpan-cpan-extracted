#!/usr/bin/env perl

use strict;
use warnings;

# VERSION

use lib qw(../lib  lib);
use POE qw(Component::IRC  Component::IRC::Plugin::BrowserSupport);

my $irc = POE::Component::IRC->spawn(
    nick        => 'ZofSupportBot',
    server      => 'irc.freenode.net',
    port        => 6667,
    ircname     => 'BrowserSupport Bot',
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
        'Support' =>
            POE::Component::IRC::Plugin::BrowserSupport->new
    );

    $irc->yield( connect => {} );
}

sub irc_001 {
    $_[KERNEL]->post( $_[SENDER] => join => '#zofbot' );
}


=pod

Usage: perl support_bot.pl

=cut

