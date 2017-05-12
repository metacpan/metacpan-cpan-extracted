package FixedSizeQueue;

use strict;
use Minions ();

our %__meta__ = (
    interface => [qw(push size max_size)],
    implementation => 'FixedSizeQueueImpl',
    construct_with  => {
        max_size => { 
            assert => { positive_int => sub { $_[0] =~ /^\d+$/ && $_[0] > 0 } }, 
        },
    }, 
);
Minions->minionize;
