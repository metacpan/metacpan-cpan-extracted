
BEGIN {
	use Config;
	if (! $Config{'useithreads'}) {
		print("1..0 # Skip: Perl not compiled with 'useithreads'\n");
		exit(0);
	}
}

use Test::More tests => 1;
use Net::NfDump qw ':all';
use Data::Dumper;

open(STDOUT, ">&STDERR");

require "t/ds.pl";

$floww = new Net::NfDump(OutputFile => "t/agg_time_data.tmp" );
for (my $i = 0; $i < 7200; $i++) {
	$row4{'srcip'} = sprintf("147.229.%d.10", $i % 10);
	$row4{'bytes'} = $i * 2;
#	$row4{'srcip'} = sprintf("2001:67c:1220:%d::10", $i % 10);
	$row4{'bytes'} = $i * 6;
	$row4{'first'} = $i * 1000;
	$row4{'last'} = $i * 1000 + 10000;
	delete($row4{'ip'});
	$floww->storerow_hashref( txt2flow(\%row4) );
}
$floww->finish();

$flowr = new Net::NfDump(InputFiles => [ "t/agg_time_data.tmp" ], 
			Fields => "first/300,bytes", 
			Aggreg => 1, OrderBy => "first");
$flowr->query();
$numrows = 0;
while ( my $row = $flowr->fetchrow_hashref() )  {
	$row = flow2txt($row);
	$numrows++;
#	diag Dumper($row);
#	printf "NUMROWS: $numrows\n";
}

$flowr->finish();

ok($numrows == 24);
