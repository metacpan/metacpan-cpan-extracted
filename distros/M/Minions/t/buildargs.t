use strict;
use Test::Lib;
use Test::Most;
use Minions ();

package FixedSizeQueue;

our %__meta__ = (
    interface => [qw(push size max_size)],
    construct_with => {
        max_size => { 
            assert => { positive_int => sub { $_[0] =~ /^\d+$/ && $_[0] > 0 } }, 
        },
    }, 
    implementation => 'FixedSizeQueueImpl',
);

sub BUILDARGS {
    my ($class, $max_size) = @_;

    return { max_size => $max_size };
}

Minions->minionize;

package main;

my $q = FixedSizeQueue->new(3);

is($q->max_size, 3);

$q->push(1);
is($q->size, 1);

$q->push(2);
is($q->size, 2);

throws_ok { FixedSizeQueue->new() } qr/Param 'max_size' was not provided./;
throws_ok { FixedSizeQueue->new(max_size => 0) } 'Minions::Error::AssertionFailure';

done_testing();
