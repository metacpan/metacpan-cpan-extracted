#!perl
use strict;

package MyHomePage;
use Mouse;

has 'counter' => (
    traits  => ['Counter'],
    is      => 'rw',
    isa     => 'Int',
    default => 0,
    handles => {
        inc_counter   => 'inc',
        dec_counter   => 'dec',
        reset_counter => 'reset',
    },
);

sub by_hand_inc_counter {
    return $_[0]->counter( $_[0]->counter + 1 );
}

package main;

use Benchmark qw(cmpthese);

my $obj = MyHomePage->new;

cmpthese shift || -1, {
    mousex      => sub { $obj->inc_counter },
    by_hand     => sub { $obj->by_hand_inc_counter },
};
