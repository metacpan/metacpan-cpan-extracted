#! /usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 20;

use Pinwheel::View::Wrap::Array;

my $o = bless({}, 'Pinwheel::View::Wrap::Array');


{
    is($o->first([10, 20, 30]), 10);
    is($o->first([]), undef);

    is($o->last([10, 20, 30]), 30);
    is($o->last([]), undef);
}

{
    is_deeply($o->reverse([3, 1, 4, 2]), [2, 4, 1, 3]);
    is_deeply($o->reverse([]), []);

    is_deeply($o->sort([3, 1, 4, 2]), [1, 2, 3, 4]);
    is_deeply($o->sort([]), []);

    is_deeply($o->min([3, 10, 4, 2]), 2);
    is_deeply($o->min([]), undef);

    is_deeply($o->max([3, 10, 4, 2]), 10);
    is_deeply($o->max([]), undef);
}

{
    is($o->length([10, 20, 30]), 3);
    is($o->length([]), 0);

    is($o->size([10, 20, 30]), 3);
    is($o->size([]), 0);

    ok(!$o->empty([10, 20, 3]));
    ok($o->empty([]));
}

{
    eval { $o->blah };
    like($@, qr/bad array method/i);
    eval { $o->BLAH };
    ok(!$@);
}
