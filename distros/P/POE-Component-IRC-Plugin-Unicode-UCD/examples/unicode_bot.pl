#!/usr/bin/env perl

use strict;
use warnings;

use lib '../lib';
use POE qw(Component::IRC  Component::IRC::Plugin::Unicode::UCD);

my $irc = POE::Component::IRC->spawn(
    nick        => 'UnicodeBot',
    server      => 'irc.freenode.net',
    port        => 6667,
    ircname     => 'Unicode Bot',
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
        'UnicodeUCD' =>
            POE::Component::IRC::Plugin::Unicode::UCD->new
    );

    $irc->yield( connect => {} );
}

sub irc_001 {
    $_[KERNEL]->post( $_[SENDER] => join => '#zofbot' );
}
