#!/usr/bin/env perl

use strict;
use warnings;

# VERSION

use lib qw(lib ../lib);
use POE qw(Component::IRC Component::IRC::Plugin::YouAreDoingItWrong);

my @Channels = ( '#zofbot' );

my $irc = POE::Component::IRC->spawn(
        nick    => 'WrongBot',
        server  => 'irc.freenode.net',
        port    => 6667,
        ircname => 'You Are Doing It Wrong Bot',
) or die "Oh noes :( $!";

POE::Session->create(
    package_states => [
        main => [
            qw(
                _start
                irc_001
                _default
                irc_you_are_doing_it_wrong_response
            )
        ],
    ],
);

$poe_kernel->run();

sub irc_you_are_doing_it_wrong_response {

    my $in = $_[ARG0];
    print "\n";
    foreach my $data ( qw(what who channel pic error) ) {
        next
            unless defined $in->{ $data };
        print "    $data => $in->{ $data }\n";
    }
    print "\n";
}

sub _start {
    $irc->yield( register => 'all' );

    # register our plugin
    $irc->plugin_add(
        'Wrong' => POE::Component::IRC::Plugin::YouAreDoingItWrong->new(
            debug => 1,
        )
    );

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