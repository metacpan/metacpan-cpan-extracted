#!perl

use Test::More;
use strict;
use warnings;
our $es;
my $r;

# INDICES_BOOST

ok $r= $es->search(
    query => { field => { text => 'foo' } },
    sort  => ['_score'],
    size  => 1,
    indices_boost => { 'es_test_1' => 5000, 'es_test_2' => 0.1 }
    ),
    'boost index 1';

is $r->{hits}{hits}[0]{_index}, 'es_test_1', ' - index is 1';

ok $r= $es->search(
    query => { field => { text => 'foo' } },
    sort  => ['_score'],
    size  => 1,
    indices_boost => { 'es_test_1' => 0.1, 'es_test_2' => 5000 }
    ),
    'boost index 2';
is $r->{hits}{hits}[0]{_index}, 'es_test_2', ' - index is 2';

1
