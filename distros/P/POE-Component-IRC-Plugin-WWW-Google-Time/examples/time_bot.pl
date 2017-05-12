#!/usr/bin/env perl

use strict;
use warnings;

use lib qw(lib ../lib);
use POE qw(Component::IRC  Component::IRC::Plugin::WWW::Google::Time);

my $irc = POE::Component::IRC->spawn(
    nick        => 'GoogleTimeBot',
    server      => 'irc.freenode.net',
    port        => 6667,
    ircname     => 'GoogleTimeBot',
    debug       => 1,
);

POE::Session->create(
    package_states => [
        main => [ qw(_start irc_001 ) ],
    ],
);

$poe_kernel->run;


sub _start {
    $irc->yield( register => 'all' );

    $irc->plugin_add(
        'google_time' =>
            POE::Component::IRC::Plugin::WWW::Google::Time->new
    );

    $irc->yield( connect => {} );
}

sub irc_001 {
    $_[KERNEL]->post( $_[SENDER] => join => '#zofbot' );
}

