
BEGIN {
	use Config;
	if (! $Config{'useithreads'}) {
		print("1..0 # Skip: Perl not compiled with 'useithreads'\n");
		exit(0);
	}
}

use Test::More tests => 19506;
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


$flowr = new Net::NfDump(
		InputFiles => [ "t/agg_dataset.tmp" ], 
		Fields => "srcip/24/64,bytes,bps", 
		Aggreg => 1);
$flowr->query();
$numrows = 0;
while ( my $row = $flowr->fetchrow_hashref() )  {
	$row = flow2txt($row);
	$numrows++ if ($row->{'srcip'} eq '147.229.3.0' && $row->{'bytes'} eq '750000000000');
#	diag Dumper($row);
}

ok($numrows == 1);

my %row4 = %{$DS{'v4_txt'}};
my %row6 = %{$DS{'v6_txt'}};

$floww = new Net::NfDump(OutputFile => "t/agg_dataset2.tmp" );
for (my $i = 0; $i < 1000; $i++) {
	$row4{'srcip'} = sprintf("147.229.%d.10", $i % 10);
	$row4{'bytes'} = $i * 2;
	$row6{'srcip'} = sprintf("2001:67c:1220:%d::10", $i % 10);
	$row6{'bytes'} = $i * 6;
	delete($row4{'ip'});
	delete($row6{'ip'});
	$floww->storerow_hashref( txt2flow(\%row4) );
	$floww->storerow_hashref( txt2flow(\%row6) );
	$floww->storerow_hashref( txt2flow(\%row6) );
}
$floww->finish();

$flowr = new Net::NfDump(InputFiles => [ "t/agg_dataset2.tmp" ], Fields => "srcip/24/64,bytes", 
			Aggreg => 1, OrderBy => "bytes");
$flowr->query();
$numrows = 0;
while ( my $row = $flowr->fetchrow_hashref() )  {
	$row = flow2txt($row);
	$numrows++;
#	diag Dumper($row);
#	printf "NUMROWS: $numrows\n";
}

$flowr->finish();
ok($numrows == 20);

# sorting 
# we will perform test for 0 to 1000 records in dataset in reverse order 
for ( my $nrecs = 1; $nrecs < 100; $nrecs++ ) {
#for ( my $nrecs = 10; $nrecs < 11; $nrecs++ ) {

	# create dataset with n records 
	$floww = new Net::NfDump(OutputFile => "t/sort_dataset1.tmp", OrderBy => "bytes" );

	for ($i = 0; $i < $nrecs; $i++) {
		$row6{'srcip'} = sprintf("2001:67c:1220:%d::10", $i);
		$row6{'bytes'} = $i * 8;
		$row6{'first'} = 1 * 1000;
		$row6{'last'} = 11 * 1000;
		delete($row4{'ip'});
		delete($row6{'ip'});
		$floww->storerow_hashref( txt2flow(\%row6) );
	}	
	$floww->finish();

	system("cp t/sort_dataset1.tmp t/sort_dataset2.tmp");


	# read aggregated and sorted 
	$flowr = new Net::NfDump(InputFiles => [ "t/sort_dataset1.tmp" ], Fields => "srcip,bytes", 
			Aggreg => 1, OrderBy => "bytes");
	$flowr->query();
	my $last_bytes = undef;
	while ( my $row = $flowr->fetchrow_hashref() )  {
		$row = flow2txt($row);
		if (defined($last_bytes)) {
			if ($last_bytes <= $row->{'bytes'}) {
				diag "invalid sequence (aggregated) last_bytes: $last_bytes, bytes: ".$row->{'bytes'}.", nrecs: $nrecs\n";
		#		diag Dumper($row);
			} else {
				ok(1);
			}
		}
#		diag Dumper($row);
		$last_bytes = $row->{'bytes'};

	}
	$flowr->finish();

	# read aggregated and sorted by calculated  field
	$flowr = new Net::NfDump(InputFiles => [ "t/sort_dataset1.tmp" ], Fields => "srcip,bytes,bps", 
			Aggreg => 1, OrderBy => "bps");
	$flowr->query();
	my $last_bps = undef;
	while ( my $row = $flowr->fetchrow_hashref() )  {
		$row = flow2txt($row);
		if (defined($last_bps)) {
			if ($last_bps <= $row->{'bps'}) {
				diag "invalid sequence (aggregated) last_bps: $last_bps, bytes: ".$row->{'bps'}.", nrecs: $nrecs\n";
#				diag Dumper($row);
			} else {
				ok(1);
			}
		}
#		diag Dumper($row);
		$last_bps = $row->{'bytes'};

	}
	$flowr->finish();


	# not aggregated 
	$flowr = new Net::NfDump(InputFiles => [ "t/sort_dataset1.tmp", "t/sort_dataset2.tmp" ], Fields => "srcip,bytes", 
			Aggreg => 0, OrderBy => "bytes");
	$flowr->query();
	$last_bytes = undef;
	while ( my $row = $flowr->fetchrow_hashref() )  {
		$row = flow2txt($row);
		if (defined($last_bytes)) {
			if ($last_bytes < $row->{'bytes'}) {
				diag "invalid sequence (non-aggregated) last_bytes: $last_bytes, bytes: ".$row->{'bytes'}.", nrecs: $nrecs\n";
		#		diag Dumper($row);
			} else {
				ok(1);
			}
		}
#		diag Dumper($row);
		$last_bytes = $row->{'bytes'};

	}
	$flowr->finish();
}



