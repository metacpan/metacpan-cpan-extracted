# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl PDLDM-Common.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 3;
#BEGIN { use_ok('PDLDM::Common') };

use PDL;
use PDLDM::Common qw(NormalizeData WritePDL2DtoCSV ReadCSVtoPDL SetValue GetSampleWithoutReplacements);
my $test_pdl = pdl ([[1,2,3,3,4,4,4,5,6,6], [1,1,1,2,2,4,4,5,6,6],[5,3,2,4,2,8,1,0,-2,6]]);
NormalizeData($test_pdl);
my $normalized_ans = pdl ([
 [  0 ,0.2, 0.4, 0.4, 0.6, 0.6, 0.6, 0.8,   1,   1],
 [  0,   0,   0,   0.2,   0.2, 0.6, 0.6, 0.8,   1,   1],
 [0.7, 0.5, 0.4, 0.6, 0.4,   1, 0.3, 0.2,   0, 0.8]
] );

ok(sum($test_pdl - $normalized_ans) == 0,'NormalizeData');

WritePDL2DtoCSV($test_pdl,'WritePDL2DtoCSV_test.csv');
my $read_csv_pdl = ReadCSVtoPDL('WritePDL2DtoCSV_test.csv');

ok(sum($read_csv_pdl - $normalized_ans) == 0,'WritePDL2DtoCSV and ReadCSVtoPDL');

my $sample = GetSampleWithoutReplacements(100,10);
ok($sample->getdim(0) == 10,'GetSampleWithoutReplacements');

print "Changed: $test_pdl \n";













