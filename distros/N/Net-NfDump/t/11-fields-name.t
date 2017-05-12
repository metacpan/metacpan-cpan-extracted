
BEGIN {
	use Config;
	if (! $Config{'useithreads'}) {
		print("1..0 # Skip: Perl not compiled with 'useithreads'\n");
		exit(0);
	}
}


use Test::More tests => 3;
use Net::NfDump qw ':all';
use Data::Dumper;

open(STDOUT, ">&STDERR");

require "t/ds.pl";

# * star as field 
my $cnt = 0;
my $flow = new Net::NfDump(InputFiles => [ "t/v4_rec.tmp" ] );
$flow->query();

foreach $colno (0..$flow->{NUM_OF_FIELDS}-1) { $cnt++; }
#printf "NUM:$cnt\n";
ok($cnt == 77);

$flow->finish();

# selected fields 
$cnt = 0;
$flow = new Net::NfDump(InputFiles => [ "t/v4_rec.tmp" ], Fields => "srcip,dstip,srcport,pps" );
$flow->query();

foreach $colno (0..$flow->{NUM_OF_FIELDS}-1) { $cnt++; }
ok($cnt == 4);

$flow->finish();

# selected fields 
$cnt = 0;
$flow = new Net::NfDump(InputFiles => [ "t/v4_rec.tmp" ], Aggreg => "srcip", Fields => "srcip,dstip,srcport,pps" );
$flow->query();

foreach $colno (0..$flow->{NUM_OF_FIELDS}-1) { $cnt++; }
ok($cnt == 4);

$flow->finish();

