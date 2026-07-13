use strict;
use warnings;
use Test::More;

use Search::Trigram;

my $idx = Search::Trigram->new;
ok(defined $idx,              'new() returns something');
isa_ok($idx, 'Search::Trigram');

is($idx->doc_count,     0, 'doc_count == 0 before any add');
is($idx->trigram_count, 0, 'trigram_count == 0 before any add');

my $id0 = $idx->add("The quick brown fox");
ok(defined $id0, 'add() returns a value');
ok($id0 =~ /^\d+$/, 'add() returns a numeric doc_id');

my $id1 = $idx->add("Pack my box with five dozen liquor jugs");
my $id2 = $idx->add("How vexingly quick daft zebras jump");

ok($id1 > $id0, 'second add returns higher id');
ok($id2 > $id1, 'third add returns higher id');

is($idx->doc_count, 3, 'doc_count == 3 after three adds');
ok($idx->trigram_count > 0, 'trigram_count > 0 after add');

my $tc1 = $idx->trigram_count;
$idx->add("entirely different zymurgy content here");
ok($idx->trigram_count > $tc1, 'trigram_count increases with distinct content');

$idx->clear;
is($idx->doc_count,     0, 'clear() resets doc_count to 0');
is($idx->trigram_count, 0, 'clear() resets trigram_count to 0');

done_testing;
