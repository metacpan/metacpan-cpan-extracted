#!perl

use Test::More;
use strict;
use warnings;
our $es;
my $r;

# MATCH ALL
isa_ok $r= $es->search( query => { match_all => {} } ), 'HASH', "Match all";
is $r->{hits}{total}, 29, ' - total correct';
is @{ $r->{hits}{hits} }, 10, ' - returned 10 results';
is $r->{hits}{max_score}, 1, ' - max score 1';

# MATCH NONE
isa_ok $r
    = $es->search( query => { field => { text => 'llll' } } ),
    'HASH',
    "Match none";
is $r->{hits}{total}, 0, ' - total correct';
is @{ $r->{hits}{hits} }, 0, ' - returned 10 results';
ok exists $r->{hits}{max_score}, ' - max score exists';
ok !defined $r->{hits}{max_score}, ' - max score not defined';

# TERM SEARCH
isa_ok $r
    = $es->search( query => { term => { text => 'foo' } } ),
    'HASH',
    "Match text: foo";
is $r->{hits}{total}, 17, ' - total correct';

# QUERY STRING SEARCH
isa_ok $r = $es->search(
    query => {
        query_string => { default_field => 'text', query => 'foo OR bar' }
    }
    ),
    'HASH',
    "Match text: bar foo";

# MIN SCORE
is $r = $es->search(
    min_score => 0.8,
    query     => {
        query_string => { default_field => 'text', query => 'foo OR bar' }
    }
    )->{hits}{total},
    '5',
    "Min score";

1;
