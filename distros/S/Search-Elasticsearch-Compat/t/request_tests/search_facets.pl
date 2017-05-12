#!perl

use Test::More;
use strict;
use warnings;
our $es;
my $r;

# FACETS SEARCH

isa_ok $r = $es->search(
    facets => {
        all_terms => { terms => { field => 'text' }, },
        bar_facet => {
            terms        => { field => 'text' },
            facet_filter => { term  => { text => 'bar' } }
        }
    },
    query => { term => { text => 'foo' } }
    ),
    'HASH',
    "Facets search";

is $r->{hits}{total}, 17, ' - total correct';
my $f;
isa_ok $f= $r->{facets}{all_terms}, 'HASH', 'all_terms facet';
is $f->{_type}, 'terms', ' - is terms facet';
is @{ $f->{terms} }, 3, ' - 3 terms listed';
is $f->{terms}[0]{term},  'foo', ' - first is foo';
is $f->{terms}[0]{count}, 17,    ' - foo count';

isa_ok $f= $r->{facets}{bar_facet}, 'HASH', 'bar_facet';
is $f->{_type}, 'terms', ' - is terms facet';
is @{ $f->{terms} }, 3, ' - 3 terms listed';
is $f->{terms}[2]{term},  'baz', ' - last is baz';
is $f->{terms}[2]{count}, 4,     ' - baz count';

1
