#!/usr/bin/env perl

use strict;
use warnings;

# VERSION

use lib qw{lib ../lib};
use POE qw(Component::IRC  Component::IRC::Plugin::WrapExample);

my @Channels = ( '#zofbot' );

my $irc = POE::Component::IRC->spawn(
    nick        => 'RankBot',
    server      => 'irc.freenode.net',
    port        => 6667,
    ircname     => 'Google Calculator bot',
);

POE::Session->create(
    package_states => [
        main => [ qw(_start irc_001 _default) ],
    ],
);

$poe_kernel->run;

sub _start {
    $irc->yield( register => 'all' );

    $irc->plugin_add(
        'calc' => POE::Component::IRC::Plugin::WrapExample->new(debug=>1)
    );

    $irc->yield( connect => {} );
}

sub irc_001 {
    $_[KERNEL]->post( $_[SENDER] => join => $_ )
        for @Channels;
}

sub _default {
    my ( $event, $args ) = @_[ ARG0, ARG1 ];

    my @output = ("$event: ");

    foreach my $arg ( @$args ) {
        if ( ref $arg eq 'ARRAY' ) {
            push @output, '[' . join ( q| ,|, @$arg ) . ']';
        }
        else {
            $arg ='' unless defined $arg;
            push @output, "'$arg'";
        }
    }
    print STDOUT "@output\n";

    return 0;
}

=pod

Usage: perl rank_bot.pl

Address the bot with "rank http://example.com/"

=cut



