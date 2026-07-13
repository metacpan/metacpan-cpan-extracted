use strict;
use warnings;
use utf8;
use Test::More;

use Search::Trigram;

my $idx = Search::Trigram->new;

# add() accepts UTF-8 string
my $text = "Ñoño résumé naïve café";
my $doc_id;
ok(eval { $doc_id = $idx->add($text); 1 }, 'add() accepts UTF-8 string');
ok(defined $doc_id, 'add() returns doc_id for UTF-8 text');

# search() accepts UTF-8 query
my $r;
ok(eval { $r = $idx->search("résumé"); 1 }, 'search() accepts UTF-8 query');
is(ref($r), 'ARRAY', 'search returns arrayref for UTF-8 query');

# UTF-8 text round-trips in result text field
ok(scalar @$r > 0, 'UTF-8 search returns a result');
is($r->[0]{text}, $text, 'UTF-8 text round-trips in result text field');

# Multi-byte characters don't corrupt adjacent trigrams
my $idx2 = Search::Trigram->new;
$idx2->add("日本語テスト");
$idx2->add("中文测试内容");
my $r2 = $idx2->search("テスト");
ok(defined $r2, 'search with multi-byte query does not crash');
is(ref($r2), 'ARRAY', 'multi-byte search returns arrayref');

done_testing;
