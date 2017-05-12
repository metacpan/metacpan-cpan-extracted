use strict;
use warnings;
use utf8;
use Test::More;

use Search::Fulltext;
use Search::Fulltext::Tokenizer::MeCab;

plan tests => 1;

my $query = '猫';
my @docs = (
    '我輩は猫である',
    '犬も歩けば棒に当る',
    '実家でてんちゃんって猫を飼ってまして，ものすっごい可愛いんですよほんと',
);

{
    my $fts = Search::Fulltext->new({
        docs      => \@docs,
        tokenizer => "perl 'Search::Fulltext::Tokenizer::MeCab::tokenizer'",
    });
    my $results = $fts->search($query);
    is_deeply($results, [0, 2]);
}
