#!perl

use Test::More;
use strict;
use warnings;
our $es;
my $r;

## SCROLL
ok $r = $es->search(
    query  => { match_all => {} },
    sort   => ['num'],
    fields => ['_id'],
    scroll => '5m',
    size   => 2
    ),
    'Scroll search';
my $scroll_id = $r->{_scroll_id};
ok $scroll_id, ' - has scroll ID';

is $r->{hits}{hits}[0]{_id}, 1, ' - first hit is ID 1';
is $r->{hits}{hits}[1]{_id}, 2, ' - second hit is ID 2';

for my $tranche ( 1 .. 14 ) {
    ok $r = $es->scroll( scroll_id => $scroll_id, scroll => '5m' ),
        " - tranche $tranche";
    my $first  = 1 + 2 * $tranche;
    my $second = $first + 1;
    if ( $tranche == 14 ) {
        $first  = 30;
        $second = undef;
    }
    is $r->{hits}{hits}[0]{_id}, $first, " - first hit is ID $first";
    is $r->{hits}{hits}[1]{_id}, $second,
        " - first hit is ID " . ( $second || 'undef' );

}

# SCROLLED SEARCH
isa_ok $r = $es->scrolled_search(
    query  => { query_string => { query => 'foo bar' } },
    scroll => '2m',
    facets => { foo => { terms => { field => 'text' } } },
    ),
    'Search::Elasticsearch::Compat::ScrolledSearch';

is $r->total, 25, ' - total';
ok $r->max_score > 0, ' - max_score';
ok $r->facets->{foo}, ' - facets';

my @docs;
is scalar( @docs = $r->next() ), 1, ' - next()';
is scalar( @docs = $r->next(2) ),   2,  ' - next(2)';
is scalar( @docs = $r->next(100) ), 22, ' - next(100)';

ok $r->eof, ' - eof';

# SCROLLED SEARCH AS JSON
isa_ok $r = $es->scrolled_search(
    query  => { query_string => { query => 'foo bar' } },
    scroll => '2m',
    facets  => { foo => { terms => { field => 'text' } } },
    as_json => 1,
    ),
    'Search::Elasticsearch::Compat::ScrolledSearch';

is $r->total, 25, ' - total';
ok $r->max_score > 0, ' - max_score';
ok $r->facets, ' - facets';

my $json = $es->JSON;
is scalar( @{ $json->decode( $r->next() ) } ), 1, ' - next()';
is scalar( @{ $json->decode( $r->next(2) ) } ),   2,  ' - next(2)';
is scalar( @{ $json->decode( $r->next(100) ) } ), 22, ' - next(100)';
is scalar( @{ $json->decode( $r->next() ) } ), 0, ' - eof next()';

ok $r->eof, ' - eof';

# BUFFER
ok $r = $es->scrolled_search(
    q           => 'foo bar',
    size        => 1,
    search_type => 'scan'
    ),
    ' - prepare buffer';

my $cur = 0 + @{ $r->{_buffer} };
my $tot = 0;

while ( !$r->eof ) {
    my @docs = $r->drain_buffer;
    $tot += @docs;
    ok @docs == $cur, " - buffer drained: $cur";
    $cur = $r->refill_buffer;
    ok $cur <= 15, " - buffer refilled: $cur";
}
ok !$r->refill_buffer, ' - buffer empty';
ok 25 == $tot, ' - all docs drained';

1;
