use strict;
use warnings;
use utf8;
use Test::More;

use Search::Fulltext;
use Search::Fulltext::Tokenizer::MeCab;

plan tests => 7;

my @docs = (
    '我輩は猫である',
    '犬も歩けば棒に当る',
    '実家でてんちゃんって猫を飼ってまして，ものすっごい可愛いんですよほんと',
);

# See: http://www.sqlite.org/fts3.html#section_3 for query specification
{
    my $fts = Search::Fulltext->new({
        docs      => \@docs,
        tokenizer => "perl 'Search::Fulltext::Tokenizer::MeCab::tokenizer'",
    });

    # single word query
    {
        my $results = $fts->search('可愛い');
        is_deeply($results, [2]);
    }
    # AND query
    {
        my $results = $fts->search('猫 AND 可愛い');
        is_deeply($results, [2]);
    }
    # OR query
    {
        my $results = $fts->search('犬 OR ほんと');
        is_deeply($results, [1, 2]);
    }
    # NOT query
    {
        my $results = $fts->search('猫 NOT 可愛い');
        is_deeply($results, [0]);
    }
    # NEAR query
    {
        my $results = $fts->search('猫 NEAR 実家');
        is_deeply($results, [2]);
        $results    = $fts->search('猫 NEAR/4 実家');
        is_deeply($results, [2]);
        $results    = $fts->search('猫 NEAR/3 実家');
        is_deeply($results, []);
    }
}
