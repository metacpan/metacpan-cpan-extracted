#!/usr/bin/env perl

use strict;
use warnings;

# VERSION

use lib qw(../lib  lib);
use POE qw(Component::IRC  Component::IRC::Plugin::SigFail);

my $irc = POE::Component::IRC->spawn(
    nick        => 'FailBot',
    server      => 'irc.freenode.net',
    port        => 6667,
    ircname     => 'FAIL BOT',
    plugin_debug => 1,
);

POE::Session->create(
    package_states => [
        main => [ qw(_start  irc_001  irc_public  _default) ],
    ],
);

$poe_kernel->run;

sub _start {
    $irc->yield( register => 'all' );

    $irc->plugin_add(
        'SigFail' =>
            POE::Component::IRC::Plugin::SigFail->new
    );

    $irc->yield( connect => {} );
}

sub irc_public {
    $irc->yield( privmsg => '#zofbot' => '<irc_sigfail:FAIL>' );
}

sub irc_001 {
    $irc->yield( join => '#zofbot' );
}

 # We registered for all events, this will produce some debug info.
 sub _default {
     my ($event, $args) = @_[ARG0 .. $#_];
     my @output = ( "$event: " );

     for my $arg (grep defined, @$args) {
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