#!/usr/bin/env perl

use strict;
use warnings;

use lib qw(../lib lib);
use POE qw(Component::IRC  Component::IRC::Plugin::WWW::CPANRatings::RSS);

my $irc = POE::Component::IRC->spawn(
    nick        => 'CPANRatings',
    server      => 'irc.freenode.net',
    port        => 6667,
    ircname     => 'CPAN Ratings Bot',
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
        'cpan_ratings' =>
            POE::Component::IRC::Plugin::WWW::CPANRatings::RSS->new(
                channels => [ '#zofbot' ],
                utf => 1,
                max_ratings => 50,
            )
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
        next unless defined $arg;
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