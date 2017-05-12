#!/usr/bin/env perl

use strict;
use warnings;

# VERSION

use lib qw(../lib  lib);
use POE qw(Component::IRC  Component::IRC::Plugin::CSS::SelectorTools);

my $irc = POE::Component::IRC->spawn(
    nick        => 'CSSToolsBot',
    server      => 'irc.freenode.net',
    port        => 6667,
    ircname     => 'CSSToolsBot',
    plugin_debug => 1,
);

POE::Session->create(
    package_states => [
        main => [ qw(_start  irc_001  _default) ],
    ],
);

$poe_kernel->run;

sub _start {
    $irc->yield( register => 'all' );

    $irc->plugin_add(
        'CSSSelectorTools' =>
            POE::Component::IRC::Plugin::CSS::SelectorTools->new(debug=>1)
    );

    $irc->yield( connect => {} );
}

sub irc_001 {
    $irc->yield( join => '#zofbot' );
}

sub _default {
    my ($event, $args) = @_[ARG0 .. $#_];
    my @output = ( "$event: " );

    for my $arg (@$args) {
        if ( ref $arg eq 'ARRAY' ) {
            push( @output, '[' . join(' ,', @$arg ) . ']' );
        }
        else {
            push ( @output, "'$arg'" );
        }
    }
    print join ' ', @output, "\n";
    return 0;
}

