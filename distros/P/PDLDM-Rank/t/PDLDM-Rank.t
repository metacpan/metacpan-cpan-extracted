# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl PDLDM-Rank.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 10;
#BEGIN { use_ok('PDLDM::Rank') };


#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
use PDL;
use PDLDM::Rank qw(TiedRank EstimateTiedRank EstimateTiedRankWithDups UniqueRank EstimateUniqueRankWithDups);
my $training_pdl = pdl ([[1,2,3,3,4,4,4,5,6,6], [1,1,1,2,2,4,4,5,6,6]]);
my ($ranked_training_pdl,$duplicates_training_pdl) = TiedRank($training_pdl);
my $ranked_training_pdl_ans = pdl([[  1,2,3.5,3.5 ,6,6,6,8,9.5,9.5],[ 2,2,2,4.5,4.5,6.5,6.5,8,9.5,9.5]]);
my $duplicates_training_pdl_ans = pdl([[1,1,2 ,2, 3,3,3, 1, 2, 2],[3, 3, 3, 2, 2, 2, 2, 1, 2, 2]]);
ok(sum($ranked_training_pdl - $ranked_training_pdl_ans) == 0,'Tied Rank');
ok(sum($duplicates_training_pdl - $duplicates_training_pdl_ans) == 0,'Tied Rank Duplicates');

my $test_pdl = pdl ([[0.5,4,4.5,6.5], [0.2,1,2,2.5]]);
my ($ranked_test_pdl,$unique_test_pdl) = EstimateTiedRank($test_pdl,$training_pdl,$ranked_training_pdl);
my $ranked_test_pdl_ans = pdl([[  0,   6,   7 , 10], [  0 ,  2 ,4.5 ,  5]]);
my $unique_test_pdl_ans = pdl([[1, 0, 1, 1],[1, 0, 0, 1]]);

ok(sum($ranked_test_pdl - $ranked_test_pdl_ans) == 0,'Tied Rank Estimation');
ok(sum($unique_test_pdl - $unique_test_pdl_ans) == 0,'Tied Rank Estimation Uniqueness');

my ($ranked_dup_test_pdl,$dup_test_pdl) = EstimateTiedRankWithDups($test_pdl,$training_pdl,$ranked_training_pdl,$duplicates_training_pdl);
my $dup_test_pdl_ans = pdl([[0, 3, 0, 0],[0, 3, 2, 0]]);
ok(sum($ranked_test_pdl - $ranked_dup_test_pdl) == 0,'Tied Rank Estimation with EstimateTiedRankWithDups');
ok(sum($dup_test_pdl - $dup_test_pdl_ans) == 0,'Tied Rank Estimation with duplicates');

my ($uranked_training_pdl,$urank_training_dup_pdl) = UniqueRank($training_pdl);
my $uranked_training_pdl_ans = pdl([[1, 2, 3, 3, 4, 4, 4, 5, 6, 6],[1, 1, 1, 2, 2, 3, 3, 4, 5, 5]]);
ok(sum($uranked_training_pdl - $uranked_training_pdl_ans) == 0,'Unique Rank');
ok(sum($urank_training_dup_pdl - $duplicates_training_pdl_ans) == 0,'Unique Rank Duplicates');

my ($uranked_dup_test_pdl,$udup_test_pdl) = EstimateUniqueRankWithDups($test_pdl,$training_pdl,$uranked_training_pdl,$urank_training_dup_pdl);
my $uranked_dup_test_pdl_ans = pdl([[0, 4, 4, 6],[0, 1, 2, 2]]);
ok(sum($uranked_dup_test_pdl - $uranked_dup_test_pdl_ans) == 0,'Unique Rank Estimation with EstimateUniqRankWithDups');
ok(sum($udup_test_pdl - $dup_test_pdl_ans) == 0,'Unique Rank Estimation with duplicates');


