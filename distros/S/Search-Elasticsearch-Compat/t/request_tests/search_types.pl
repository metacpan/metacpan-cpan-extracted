#!perl

use Test::More;
use strict;
use warnings;
our $es;
my $r;

# QUERY_THEN_FETCH
isa_ok $r= $es->search(
    query       => { match_all => {} },
    search_type => 'query_then_fetch'
    ),
    'HASH',
    "query_then_fetch";
is $r->{hits}{total}, 29, ' - total correct';
is @{ $r->{hits}{hits} }, 10, ' - returned 10 results';

# QUERY_AND_FETCH

isa_ok $r= $es->search(
    query       => { match_all => {} },
    search_type => 'query_and_fetch'
    ),
    'HASH',
    "query_and_fetch";
is $r->{hits}{total}, 29, ' - total correct';
ok @{ $r->{hits}{hits} } > 10, ' - returned  > 10 results';

# COUNT
isa_ok $r = $es->search( search_type => 'count' ), 'HASH', 'count';
is $r->{hits}{total}, 29, ' - total correct';
is @{ $r->{hits}{hits} }, 0, ' - zero results';

# SCAN
throws_ok { $es->search( search_type => 'scan' ) } qr/Request/,
    ' - scan without scroll';

ok $r = $es->search( search_type => 'scan', scroll => '2m', size => 1 ),
    ' - scan with scroll';

is @{ $r->{hits}{hits} }, 0, ' - no initial hits';
ok $r->{_scroll_id}, ' - scroll id';

is @{ $es->scroll( scroll_id => $r->{_scroll_id} )->{hits}{hits} }, 10,
    ' - hits from all shards';

1;
