use strict;
use warnings;
use Proch::N50;
use Test::More;
use FindBin qw($RealBin);
use JSON::PP;
plan skip_all => 'JSON required for this test' if $@;
my $file = "$RealBin/../data/small_test.fa";

SKIP: {
	skip "missing input file" unless (-e "$file");
	my $stats = getStats($file, 'JSON');
	my $data  = decode_json($stats->{json});

	ok($data->{N50}   > 0,  'got an N50');
	ok($data->{N50}  == 65, 'N50==65 as expected (in JSON)');
	ok($data->{seqs} == 6,  'NumSeqs==6 as expected (in JSON)');
	ok($data->{min}  == 4,  'Minimum length found');
	ok($data->{max}  == 65, 'Maximum length found');
	
	my $json = jsonStats($file);
	my $data2= decode_json($json);
	ok($data2->{N50}   > 0,  'got an N50 from jsonStats()');
	ok($data2->{N50}  == 65, 'N50==65 as expected from jsonStats()');
	ok($data2->{seqs} == 6,  'NumSeqs==6 as expected from jsonStats()');

}

done_testing()

# {
#    "seqs" : 6,
#    "status" : 1,
#    "filename" : "small_test.fa",
#    "N50" : "65",
#    "dirname" : "data",
#    "size" : 130
# }
