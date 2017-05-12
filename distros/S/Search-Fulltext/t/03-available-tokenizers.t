use strict;
use warnings;
use utf8;
use Test::More;

use Search::Fulltext;

plan tests => 2;

my $query = 'change';
my @docs = (
    'People change the world',
    'He changes his way of life',
    'The feature has been changed',
);

# simple tokenizer
{
    my $fts = Search::Fulltext->new({
        docs      => \@docs,
        tokenizer => 'simple',
    });
    my $results = $fts->search($query);
    is_deeply($results, [0]);
}

# porter tokenizer, which is robust to suffix differences
{
    my $fts = Search::Fulltext->new({
        docs      => \@docs,
        tokenizer => 'porter',
    });
    my $results = $fts->search($query);
    is_deeply($results, [0, 1, 2]);
}
