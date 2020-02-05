use 5.012;
use warnings;
use Proch::N50;
use Test::More;
use FindBin qw($RealBin);
use JSON::PP;
use Data::Dumper;
plan skip_all => 'JSON required for this test' if $@;
my $file = "$RealBin/../data/small_test.fa_bad_file";

SKIP: {
	skip "found but unwanted input file" if (-e "$file");
	my $stats = getStats($file, 'JSON');
	my $valid_json = eval {
		my $data  = decode_json($stats->{json});
		1;
	};
	ok($stats->{status} eq 0, "Status = 0");
	ok(! defined $valid_json,  'getStats() returned NO json');
	
	my $json = jsonStats($file);
	ok(! defined $json, "JSON object undef: file not found");
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
