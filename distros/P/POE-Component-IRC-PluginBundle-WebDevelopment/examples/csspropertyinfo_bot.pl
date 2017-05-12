#!/usr/bin/env perl

use strict;
use warnings;

# VERSION

use lib qw(lib ../lib);
use POE qw(Component::IRC  Component::IRC::Plugin::CSS::PropertyInfo);

my $irc = POE::Component::IRC->spawn(
    nick        => 'CSSInfoBot',
    server      => 'irc.freenode.net',
    port        => 6667,
    ircname     => 'CSS Property Info bot',
);

POE::Session->create(
    package_states => [
        main => [ qw(_start irc_001 irc_css_property_info) ],
    ],
);

$poe_kernel->run;

sub _start {
    $irc->yield( register => 'all' );

    $irc->plugin_add(
        'CSSInfo' =>
            POE::Component::IRC::Plugin::CSS::PropertyInfo->new
    );

    $irc->yield( connect => {} );
}

sub irc_001 {
    $irc->yield( join => '#zofbot' );
}

sub irc_css_property_info {
    use Data::Dumper;
    print Dumper $_[ARG0];
}