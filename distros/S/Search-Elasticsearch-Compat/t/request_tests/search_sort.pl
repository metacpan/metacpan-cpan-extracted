#!perl

use Test::More;
use strict;
use warnings;
our $es;
my $r;

# SORT
is $es->search(
    query => { match_all => {} },
    sort  => ['num'],
    )->{hits}{hits}[0]{_source}{num}, 2,
    "Query with sort";

is $es->search(
    query => { match_all => {} },
    sort => [ { num => { reverse => \1 } } ],
    )->{hits}{hits}[0]{_source}{num}, 31,
    " - reverse sort";

is $es->search(
    query => { match_all => {} },
    sort  => { 'num'     => 'asc' },
    )->{hits}{hits}[0]{_source}{num}, 2,
    " - asc";

is $es->search(
    query => { match_all => {} },
    sort => [ { num => 'desc' } ],
    )->{hits}{hits}[0]{_source}{num}, 31,
    " - desc";

1;
