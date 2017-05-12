#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';
use POE;
use POE::Component::IRC;
use Socket qw(unpack_sockaddr_in);
use Test::More tests => 4;

my $bot = POE::Component::IRC->spawn(Flood => 1);

POE::Session->create(
    package_states => [
        main => [qw(
            _start
            _shutdown
            irc_shutdown
        )],
    ],
);

$poe_kernel->run();

sub _start {
    my ($kernel, $parent_heap) = @_[KERNEL, HEAP];

    $bot->yield(register => 'all');
    # we're testing if pocoirc correctly copes with a session immediately
    # dying after sending a 'shutdown' event
    POE::Session->create(
        inline_states => {
            _start => sub {
                $parent_heap->{sub_id} = $_[SESSION]->ID();
                pass('Subsession started');
                $bot->yield('shutdown');
            },
            _stop => sub {
                pass('Subsession stopped');
            }
        },
    );
    $kernel->delay(_shutdown => 60, 'Timed out');
}

sub irc_shutdown {
    my ($heap, $killer_id) = @_[HEAP, ARG0];
    pass('IRC component shut down');
    is($killer_id, $heap->{sub_id}, 'Killer session id matches');
    $poe_kernel->yield('_shutdown');
}

sub _shutdown {
    my ($kernel, $error) = @_[KERNEL, ARG0];
    fail($error) if defined $error;
    $kernel->alarm_remove_all();
    $bot->yield('shutdown');
}
