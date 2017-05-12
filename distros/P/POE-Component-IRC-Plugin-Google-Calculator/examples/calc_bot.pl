#!/usr/bin/env perl

use strict;
use warnings;

use lib qw(../lib lib);
sub POE::Kernel::ASSERT_DEFAULT () { 1 }
use POE qw(Component::IRC  Component::IRC::Plugin::Google::Calculator);

my @Channels = ( '#zofbot' );

my $irc = POE::Component::IRC->spawn(
    nick        => 'CalcBot',
    server      => 'irc.freenode.net',
    port        => 6667,
    ircname     => 'Google Calculator Bot',
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
        'GoogleCalc' => POE::Component::IRC::Plugin::Google::Calculator->new
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
        next unless defined;
        if ( ref $arg eq 'ARRAY' ) {
            push @output, '[' . join ( q| ,|, @$arg ) . ']';
        }
        else {
            push @output, "'$arg'";
        }
    }
    print STDOUT "@output\n";

    return 0;
}

=pod

Usage: perl calc_bot.pl

=cut



