#!perl

use Test::More;
use strict;
use warnings;
our $es;
my $r;

###  DELETE_BY_QUERY ###
ok $es->delete_by_query( query => { term => { text => 'foo' } } )->{ok},
    "Delete by query";
wait_for_es();

is $es->count( term => { text => 'foo' } )->{count}, 0, " - foo deleted";
is $es->count( term => { text => 'bar' } )->{count}, 8, " - bar not deleted";

1
