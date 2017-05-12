#!/usr/bin/env perl

use strict;
use warnings;

# VERSION

use lib qw(../lib  lib);
use POE qw(Component::IRC  Component::IRC::Plugin::HTML::ElementInfo);

my $irc = POE::Component::IRC->spawn(
    nick        => 'HTMLInfoBot',
    server      => 'irc.freenode.net',
    port        => 6667,
    ircname     => 'Lookup HTML element info',
);

POE::Session->create(
    package_states => [
        main => [ qw(_start irc_001 irc_html_info) ],
    ],
);

$poe_kernel->run;

sub irc_html_info {
use Data::Dumper;
print Dumper $_[ARG0];
}

sub _start {
    $irc->yield( register => 'all' );

    $irc->plugin_add(
        'HTMLInfo' =>
            POE::Component::IRC::Plugin::HTML::ElementInfo->new
    );

    $irc->yield( connect => {} );
}

sub irc_001 {
    $_[KERNEL]->post( $_[SENDER] => join => '#zofbot' );
}
