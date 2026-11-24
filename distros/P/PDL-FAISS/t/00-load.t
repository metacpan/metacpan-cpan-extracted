use strict;
use warnings;
use Test::More;
use PDL;

use_ok('PDL::FAISS', qw(flat_l2 flat_ip));

my $idx = flat_l2(4);
isa_ok($idx, 'PDL::FAISS::Index');
is($idx->dim(), 4, 'index dim is 4');
is($idx->ntotal(), 0, 'index starts empty');

my $db = float([
    [1, 0, 0, 0],
    [0, 1, 0, 0],
    [0, 0, 1, 0],
    [0, 0, 0, 1],
]);
$idx->add($db);
is($idx->ntotal(), 4, 'index has 4 vectors after add');

my ($dist, $labels) = $idx->search(float([[0, 0.9, 0.1, 0]]), 2);
is($labels->at(0, 0), 1, 'nearest neighbor is vector 1');
ok($dist->at(0, 0) < 0.05, 'nearest neighbor L2 distance is small');

my $ip = flat_ip(4);
$ip->add($db);
my ($ip_scores, $ip_labels) = $ip->search(float([[0, 0, 2, 0]]), 1);
is($ip_labels->at(0, 0), 2, 'inner-product nearest neighbor is vector 2');
is($ip_scores->at(0, 0), 2, 'inner-product score is 2');

done_testing();
