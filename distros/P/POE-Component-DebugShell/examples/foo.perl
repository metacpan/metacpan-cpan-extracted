#!/usr/bin/perl

use warnings;
use strict;

use POE;
use POE::Component::DebugShell;

sub DEBUG () { 1 }

POE::Session->create(
    inline_states => {
        _start => sub {
            $_[KERNEL]->alias_set('PIE');

            $_[KERNEL]->alias_set('PIE2');
            POE::Component::DebugShell->spawn() if DEBUG;
            $_[KERNEL]->delay('ping', 5);
        },
        _stop => sub { },

        ping => sub {
            $_[KERNEL]->delay('ping', 5);
        },
    }
);

POE::Kernel->run();
exit;
