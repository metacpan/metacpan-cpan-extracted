use strict;
use warnings;
use utf8;
use Test::More;

use Search::Fulltext;

plan tests => 9;

my @docs = (
    'I like beer the best',
    'Wine makes people saticefied',
    'Beer makes people happy',
);

# See: http://www.sqlite.org/fts3.html#section_3 for query specification
{
    my $fts = Search::Fulltext->new({
        docs => \@docs,
    });

    # single word query
    {
        my $results = $fts->search('beer');
        is_deeply($results, [0, 2]);
    }
    # AND query
    {
        my $results = $fts->search('beer AND happy');
        is_deeply($results, [2]);
    }
    # OR query
    {
        my $results = $fts->search('saticefied OR happy');
        is_deeply($results, [1, 2]);
    }
    # NOT query
    {
        my $results = $fts->search('people NOT beer');
        is_deeply($results, [1]);
    }
    # wildcard query
    {
        my $results = $fts->search('make*');
        is_deeply($results, [1, 2]);
    }
    # phrase query
    {
        my $results = $fts->search('"makes people"');
        is_deeply($results, [1, 2]);
    }
    # NEAR query
    {
        my $results = $fts->search('beer NEAR happy');
        is_deeply($results, [2]);
        $results    = $fts->search('beer NEAR/2 happy');
        is_deeply($results, [2]);
        $results    = $fts->search('beer NEAR/1 happy');
        is_deeply($results, []);
    }
}
