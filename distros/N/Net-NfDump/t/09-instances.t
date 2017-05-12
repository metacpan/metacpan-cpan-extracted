
BEGIN {
	use Config;
	if (! $Config{'useithreads'}) {
		print("1..0 # Skip: Perl not compiled with 'useithreads'\n");
		exit(0);
	}
}

use Test::More tests => 2000;
use Net::NfDump qw ':all';
use Data::Dumper;

open(STDOUT, ">&STDERR");

require "t/ds.pl";

# preapre dataset 
$floww = new Net::NfDump(OutputFile => "t/agg_dataset.tmp" );
my %row = %{$DS{'v4_txt'}};
for (my $i = 0; $i < 1000; $i++) {
	$floww->storerow_hashref( txt2flow(\%row) );
}
$floww->finish();

for ($i = 0; $i < 2000; $i++) {

	$flowr = new Net::NfDump(
			InputFiles => [ "t/agg_dataset.tmp" ], 
			Fields => "srcip,dstport,bytes,duration,inif,outif,bps,pps,pkts", 
			Aggreg => 1);
	$flowr->query();
	my $numrows = 0;
	%row = %{$DS{'v4_txt'}};
	while ( my $row = $flowr->fetchrow_hashref() )  {
		$row = flow2txt($row);
		$numrows++ if ($row->{'srcip'} eq '147.229.3.135' && $row->{'bytes'} eq '750000000000' 
		&& $row->{'outif'} eq '1' && $row->{'bps'} eq '100000000000');
	#	diag Dumper($row);
	}
	ok($numrows == 1);

	$flowr->finish();

}

