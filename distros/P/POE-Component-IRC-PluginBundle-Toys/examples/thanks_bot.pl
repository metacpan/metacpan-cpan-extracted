#!/usr/bin/perl -w

use strict;
use warnings;

# VERSION

use lib qw(lib ../lib);

use POE qw(Component::IRC Component::IRC::Plugin::Thanks);

my @Channels = ( '#zofbot' );

my $irc = POE::Component::IRC->spawn(
        nick    => 'ThankBot',
        server  => 'irc.freenode.net',
        port    => 6667,
        ircname => 'Silly Thankie bot',
) or die "Oh noes :( $!";

POE::Session->create(
    package_states => [
        main => [
            qw(
                _start
                irc_001
                _default
                thanks_response
            )
        ],
    ],
);


$poe_kernel->run();


sub thanks_response {
    use Data::Dumper;
    print Dumper($_[ARG0]);
}

sub _start {
    $irc->yield( register => 'all' );

    # register our plugin
    $irc->plugin_add( 'Thanks' => POE::Component::IRC::Plugin::Thanks->new );

    $irc->yield( connect => { } );
    undef;
}

sub irc_001 {
    my ( $kernel, $sender ) = @_[ KERNEL, SENDER ];
    $kernel->post( $sender => join => $_ )
        for @Channels;

    undef;
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