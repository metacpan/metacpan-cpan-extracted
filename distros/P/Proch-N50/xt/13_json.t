use strict;
use warnings;
use Proch::N50;
use Test::More qw(no_plan);
use FindBin qw($Bin);
our $hasJSON = eval { 'use JSON'; };
plan skip_all => 'JSON required for this test' if (! $hasJSON );
my $file = "$Bin/../data/small_test.fa";

SKIP: {
	skip "missing input file" if (!-e "$file");


		my $stats = getStats($file, 'JSON');
		my $data = decode_json($stats->{json});

		ok($data->{N50} > 0, 'got an N50');
		ok($data->{N50} == 65, 'N50==65 as expected (in JSON)');
		ok($data->{seqs} == 6, 'NumSeqs==6 as expected (in JSON)');


}
SKIP: {
	skip "missing input file" if (! $hasJSON );
	if ($hasJSON) {

	eval {
		my $json = jsonStats($file);
		my $data2= decode_json($json);
		ok($data->{N50} > 0, 'got an N50 from jsonStats()');
		ok($data->{N50} == 65, 'N50==65 as expected from jsonStats()');
		ok($data->{seqs} == 6, 'NumSeqs==6 as expected from jsonStats()');
	};
	}
}
# {
#    "seqs" : 6,
#    "status" : 1,
#    "filename" : "small_test.fa",
#    "N50" : "65",
#    "dirname" : "data",
#    "size" : 130
# }
