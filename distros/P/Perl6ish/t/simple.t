#!/usr/bin/env perl -w
use strict;
use Test::More tests => 4;

use Perl6ish;

sub {
    is(caller->package, 'main', 'caller');
}->();

ok(main->can('say'), 'say');
ok(main->can('slurp'), 'slurp');

my @foo = gather {
    take 2;
    take 3;
    take 5;
};
is_deeply(\@foo, [2, 3, 5], 'gather - take');

