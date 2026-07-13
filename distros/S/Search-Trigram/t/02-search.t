use strict;
use warnings;
use Test::More;

use Search::Trigram;

my $idx = Search::Trigram->new;

# Empty index
my $r = $idx->search("quick");
is(ref($r), 'ARRAY', 'search returns arrayref');
is(scalar @$r, 0, 'search on empty index returns []');

$idx->add("The quick brown fox jumps over the lazy dog");
$idx->add("Pack my box with five dozen liquor jugs");
$idx->add("How vexingly quick daft zebras jump");

my $none = (do {
    my $tmp = Search::Trigram->new;
    $tmp->add("cat sat on mat");
    $tmp->search("dog runs far");
});
is(ref($none), 'ARRAY', 'no-match returns arrayref');
is(scalar @$none, 0, 'search with no matches returns []');

my $res = $idx->search("quick fox", 2);

ok(scalar @$res > 0, 'search returns results for matching query');

my $hit = $res->[0];
ok(exists $hit->{doc_id}, 'result has doc_id key');
ok(exists $hit->{score},  'result has score key');
ok(exists $hit->{text},   'result has text key');

# Exact match scores 1.0
my $idx2 = Search::Trigram->new;
$idx2->add("quick fox");
my $exact = $idx2->search("quick fox");
is(scalar @$exact, 1, 'exact match returns one result');
ok(abs($exact->[0]{score} - 1.0) < 1e-5, 'exact match scores 1.0');

# Ranking: closer match ranks higher
my $idx3 = Search::Trigram->new;
$idx3->add("quick fox");
$idx3->add("the quick brown fox jumps over the lazy dog with many extra words");
my $ranked = $idx3->search("quick fox");
ok($ranked->[0]{score} >= $ranked->[1]{score}, 'closer match ranked higher');

# Limit
my $idx4 = Search::Trigram->new;
for my $t ("quick red fox", "quick blue fox", "quick green fox",
           "quick black fox", "quick white fox") {
    $idx4->add($t);
}
my $lim = $idx4->search("quick fox", 2);
ok(scalar @$lim <= 2, 'limit => 2 returns at most 2 results');

my $default = $idx4->search("quick fox");
ok(scalar @$default <= 10, 'default limit is 10');

# Case insensitivity
my $idx5 = Search::Trigram->new;
$idx5->add("the quick brown fox");
my $case_res = $idx5->search("Fox");
ok(scalar @$case_res > 0, 'search is case-insensitive (Fox matches fox)');

# Partial match
my $idx6 = Search::Trigram->new;
$idx6->add("quick brown fox over the lazy dog");
my $partial = $idx6->search("quick");
ok(scalar @$partial > 0, 'partial match returns result');
ok($partial->[0]{score} < 1.0, 'partial match score < 1.0');

# Multi-word scores intersection
my $idx7 = Search::Trigram->new;
my $did1 = $idx7->add("quick fox");
my $did2 = $idx7->add("lazy dog");
my $multi = $idx7->search("quick fox");
is($multi->[0]{doc_id}, $did1, 'multi-word query scores intersection correctly');

# Results sorted by score descending
my $idx8 = Search::Trigram->new;
$idx8->add("quick brown fox");
$idx8->add("the quick brown fox jumped over the enormous lazy shaggy old dog sleeping");
my $sorted = $idx8->search("quick brown fox");
ok(scalar @$sorted >= 2, 'got multiple results');
ok($sorted->[0]{score} >= $sorted->[-1]{score}, 'results sorted by score descending');

done_testing;
