#!/usr/bin/env perl

use strict;
use warnings;

# VERSION

use lib qw(../lib  lib);
use POE qw(Component::IRC  Component::IRC::Plugin::HTML::AttributeInfo);

my $irc = POE::Component::IRC->spawn(
    nick        => 'HTMLAttrBot',
    server      => 'irc.freenode.net',
    NoDNS       => 1,
    port        => 6667,
    ircname     => 'HTML Attributes Lookup Bot',
    plugin_debug => 1,
);

POE::Session->create(
    package_states => [
        main => [ qw(_start irc_001  irc_html_attribute  _default) ],
    ],
);

$poe_kernel->run;

sub _start {
    $irc->yield( register => 'all' );

    $irc->plugin_add(
        'HTMLAttributeInfo' =>
            POE::Component::IRC::Plugin::HTML::AttributeInfo->new(
                debug => 1,
            )
    );

    $irc->yield( connect => {} );
}

sub irc_001 {
    $irc->yield( join => '#zofbot' );
}

sub irc_html_attribute {
    use Data::Dumper;
    print Dumper $_[ARG0];
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
