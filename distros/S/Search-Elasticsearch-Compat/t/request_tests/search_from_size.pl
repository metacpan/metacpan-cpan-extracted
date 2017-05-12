#!perl

use Test::More;
use strict;
use warnings;
our $es;
my $r;

# RETRIEVE ALL RESULTS
isa_ok $r
    = $es->search( query => { match_all => {} }, size => 100 ),
    'HASH',
    "Match up to 100";
is $r->{hits}{total}, 29, ' - total correct';
is @{ $r->{hits}{hits} }, 29, ' - returned 29 results';

# FROM / TO
ok $r= $es->search(
    query => { match_all => {} },
    sort  => ['num'],
    size  => 5,
    from  => 5,
    ),
    "Query with size and from";
is @{ $r->{hits}{hits} }, 5, ' - number of hits correct';
is $r->{hits}{hits}[0]{_source}{num}, 7, ' - started from correct pos';

1
