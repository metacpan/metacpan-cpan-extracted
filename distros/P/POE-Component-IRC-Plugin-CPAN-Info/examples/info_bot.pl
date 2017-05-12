#!/usr/bin/perl -w

use strict;
use warnings;

# VERSION

use lib qw(../lib  lib);

use POE qw(Component::IRC Component::IRC::Plugin::CPAN::Info);

my @Channels = ( '#zofbot' );

my $irc = POE::Component::IRC->spawn(
        nick    => 'CPANInfoBot',
        server  => 'irc.freenode.net',
        port    => 6667,
        ircname => 'CPAN module information bot',
        debug => 1,
) or die "Oh noes :( $!";

POE::Session->create(
    package_states => [
        main => [
            qw(
                _start
                irc_001
            )
        ],
    ],
);


$poe_kernel->run();

sub _start {
    $irc->yield( register => 'all' );

    # register our plugin
    $irc->plugin_add(
        'CPANInfo' =>
            POE::Component::IRC::Plugin::CPAN::Info->new( debug => 1 )
    );

    $irc->yield( connect => { } );
    undef;
}

sub irc_001 {
    my ( $kernel, $sender ) = @_[ KERNEL, SENDER ];
    $kernel->post( $sender => join => $_ )
        for @Channels;
    undef;
}

