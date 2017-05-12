#!perl

use Test::More;
use strict;
use warnings;
our $es;
my $r;

ok $es->exists(
    index => 'es_test_1',
    type  => 'type_1',
    id    => 1,
)->{ok}, 'Doc exists';

ok !$es->exists(
    index => 'es_test_1',
    type  => 'type_1',
    id    => 2,
    ),
    'Doc does not exist';

1
