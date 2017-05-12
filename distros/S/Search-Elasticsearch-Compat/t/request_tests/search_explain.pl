#!perl

use Test::More;
use strict;
use warnings;
our $es;
my $r;

# EXPLAIN SEARCH
isa_ok $es->search(
    query   => { term => { text => 'foo' } },
    explain => 1
    )->{hits}{hits}[0]{_explanation},
    'HASH',
    "Query with explain";

1
