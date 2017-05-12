#!/usr/bin/env perl

use strict;
use warnings;

# VERSION

use lib qw{lib ../lib};
use POE qw(Component::IRC  Component::IRC::Plugin::Example);

my $irc = POE::Component::IRC->spawn(
    nick        => 'TimeBot',
    server      => 'irc.freenode.net',
    port        => 6667,
    ircname     => 'Time bot',
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
        'Example' =>
            POE::Component::IRC::Plugin::Example->new(
                addressed => 0,
                trigger => qr/^!time$/i,
                triggers => {
                    privmsg => qr/^time$/i,
                    notice  => qr/^time$/i,
                },
                debug => 1,
            )
    );

    $irc->yield( connect => {} );
}

sub irc_001 {
    $_[KERNEL]->post( $_[SENDER] => join => '#zofbot' );
}