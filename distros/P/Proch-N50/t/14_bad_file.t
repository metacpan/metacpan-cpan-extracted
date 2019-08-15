use strict;
use warnings;
use Proch::N50;
use Test::More;
use FindBin qw($Bin);
use Data::Dumper;

my $file = "$Bin/../data/small_test.fa";
my $bad_file = $file . '_not_existing';

SKIP: {
	skip "missing input file" unless (-e "$file");
	my $stats = getStats($file, 'JSON');
	ok($stats->{N50} > 0, 'got an N50');
	ok($stats->{N50} == 65, 'N50==65 as expected (in JSON)');
	ok($stats->{seqs} == 6, 'NumSeqs==6 as expected (in JSON)');
}


SKIP: {
	skip "missing input file" if (-e "$bad_file");
	my  $stats = getStats($bad_file);

	#$VAR1 = {
	#          'status' => 0,
	#          'message' => 'Unable to find </git/hub/bioinfo/Proch-N50/.build/bFL6BDvntk/t/../data/small_test.fa_not_existing>',
	#          'N50' => undef
	#        };
       
	ok(! defined $stats->{N50},       'Non existing file tested: N50 undef');
	ok($stats->{status}==0,           'Non existing file tested: status = 0');
	ok(length($stats->{message}) > 0, 'Non existing file tested: message returned');
}

done_testing();
# {
#    "seqs" : 6,
#    "status" : 1,
#    "filename" : "small_test.fa",
#    "N50" : "65",
#    "dirname" : "data",
#    "size" : 130
# }
