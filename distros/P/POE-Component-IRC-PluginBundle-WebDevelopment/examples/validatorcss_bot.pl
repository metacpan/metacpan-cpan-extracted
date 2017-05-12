#!/usr/bin/env perl

use strict;
use warnings;

# VERSION

use lib qw(../lib  lib);
use POE qw(Component::IRC  Component::IRC::Plugin::Validator::CSS);

my $irc = POE::Component::IRC->spawn(
    nick    => 'CSSValidator',
    server  => 'irc.freenode.net',
    port    => 6667,
    ircname => 'CSS Validator Bot',
) or die "Oh noes :( $!";

POE::Session->create(
    package_states => [
        main => [ qw(_start irc_001 _default) ],
    ],
);

$poe_kernel->run;

sub _start {
    $irc->yield( register => 'all' );

    # register our plugin
    $irc->plugin_add(
        'CSSValidator' => POE::Component::IRC::Plugin::Validator::CSS->new
    );

    $irc->yield( connect => {} );
}

sub irc_001 {
    my ( $kernel, $sender ) = @_[ KERNEL, SENDER ];
    $kernel->post( $sender => join => '#zofbot' );
}


sub _default {
    my ($event, $args) = @_[ARG0 .. $#_];
    my @output = ( "$event: " );

    foreach my $arg ( @$args ) {
        if ( ref($arg) eq 'ARRAY' ) {
                push( @output, "[" . join(" ,", @$arg ) . "]" );
        } else {
                push ( @output, "'$arg'" );
        }
    }
    print STDOUT join ' ', @output, "\n";
    return 0;
}

=pod

Usage: perl val.pl

=cut
