#!/usr/bin/perl

# A Multiple Network Rot13 'encryption' bot

use strict;
use warnings;
use POE qw(Component::IRC);

my $nickname = 'Flibble' . $$;
my $ircname = 'Flibble the Sailor Bot';

my $settings = {
    'server1.irc' => { port => 6667, channels => [ '#Foo' ], },
    'server2.irc' => { port => 6668, channels => [ '#Bar' ], },
    'server3.irc' => { port => 7001, channels => [ '#Baa' ], },
};

# We create our PoCo-IRC objects
for my $server ( keys %{ $settings } ) {
    POE::Component::IRC->spawn(
        alias   => $server,
        nick    => $nickname,
        ircname => $ircname,
    );
}

POE::Session->create(
    package_states => [
        main => [ qw(_default _start irc_registered irc_001 irc_public) ],
    ],
    heap => { config => $settings },
);

$poe_kernel->run();

sub _start {
    my ($kernel, $session) = @_[KERNEL, SESSION];

    # Send a POCOIRC_REGISTER signal to all poco-ircs
    $kernel->signal( $kernel, 'POCOIRC_REGISTER', $session->ID(), 'all' );

    return;
}

# We'll get one of these from each PoCo-IRC that we spawned above.
sub irc_registered {
    my ($kernel, $heap, $sender, $irc_object) = @_[KERNEL, HEAP, SENDER, ARG0];

    my $alias = $irc_object->session_alias();

    my %conn_hash = (
        server => $alias,
        port   => $heap->{config}->{ $alias }->{port},
    );

    # In any irc_* events SENDER will be the PoCo-IRC session
    $kernel->post( $sender, 'connect', \%conn_hash );

    return;
}

sub irc_001 {
    my ($kernel, $heap, $sender) = @_[KERNEL, HEAP, SENDER];

    # Get the component's object at any time by accessing
    # the heap of the SENDER
    my $poco_object = $sender->get_heap();
    print "Connected to ", $poco_object->server_name(), "\n";

    my $alias = $poco_object->session_alias();
    my @channels = @{ $heap->{config}->{ $alias }->{channels} };

    $kernel->post( $sender => join => $_ ) for @channels;

    return;
}

sub irc_public {
    my ($kernel, $sender, $who, $where, $what) = @_[KERNEL, SENDER, ARG0 .. ARG2];
    my $nick = ( split /!/, $who )[0];
    my $channel = $where->[0];

    if ( my ($rot13) = $what =~ /^rot13 (.+)/ ) {
        $rot13 =~ tr[a-zA-Z][n-za-mN-ZA-M];
        $kernel->post( $sender => privmsg => $channel => "$nick: $rot13" );
    }

    if ( $what =~ /^!bot_quit$/ ) {
        # Someone has told us to die =[
        $kernel->signal( $kernel, 'POCOIRC_SHUTDOWN', "See you loosers" );
    }

    return;
}

# We registered for all events, this will produce some debug info.
sub _default {
    my ($event, $args) = @_[ARG0 .. $#_];
    my @output = ( "$event: " );

    for my $arg ( @$args ) {
        if ( ref($arg) eq 'ARRAY' ) {
            push( @output, '[' . join(' ,', @$arg ) . ']' );
        }
        else {
            push ( @output, "'$arg'" );
        }
    }
    print join ' ', @output, "\n";

    return 0;
}

