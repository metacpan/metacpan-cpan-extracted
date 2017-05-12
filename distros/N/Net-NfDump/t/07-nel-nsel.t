
BEGIN {
	use Config;
	if (! $Config{'useithreads'}) {
		print("1..0 # Skip: Perl not compiled with 'useithreads'\n");
		exit(0);
	}
}

use Test::More tests => 2;
use Net::NfDump qw ':all';
use Data::Dumper;

#open(STDOUT, ">&STDERR");

require "t/ds.pl";


$DS{'v4_nel_nsel_txt'} = { 
	%{$DS{'v4_txt'}},
	'eventtime' => time() * 1000,
	'connid' => 1000,
	'icmpcode' => 1,
	'icmptype' => 2, 
	'event' => 3,
	'xevent' => 5, 
	'xsrcip' => '147.229.3.10',
	'xdstip' => '147.229.3.11',
	'xsrcport' => 2222,
	'xdstport' => 3333,
# added 2014-04-19
	'eventflag' => 1,
	'ingressvrfid' => 7,
	'egressvrfid' => 2,
	'blockstart' => 3333,
	'blockend' => 3334,
	'blockstep' => 6666,
	'blocksize' => 6667,

	'iacl' => 20,
	'iace' => 30,
	'ixace' => 40,
	'eacl' => 50,
	'eace' => 60,
	'exace' => 70,

	'username' => 'tpoder@vutbr.czxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',

	'egressacl' => undef,
	'ingressacl' => undef,
	#NEL (NetFlow Event Logging) fields
#	'nevent' => 1,
#	'nsrcport' => 5555,
#	'ndstport' => 6666,

# !!! BUG in NFDUMP PackRecord and Expand record doesn't work 
#	'vrf' => 1,

#	'nsrcip' => '192.168.1.6',
#	'ndstip' => '10.255.6.1'
};



$DS{'v4_nel_nsel_raw'} = txt2flow( $DS{'v4_nel_nsel_txt'} );

# testing net, nsel fields
my ($floww, $flowr);
$floww = new Net::NfDump(OutputFile => "t/v4_nel_nsel_rec.tmp" );
$floww->storerow_hashref( $DS{'v4_nel_nsel_raw'} );
$floww->storerow_hashref( $DS{'v4_nel_nsel_raw'} );
$floww->finish();

$flowr = new Net::NfDump(InputFiles => [ "t/v4_nel_nsel_rec.tmp" ] );
my $invalid = 0;
while ( my $row = $flowr->fetchrow_hashref() )  {
#	diag Dumper($DS{'v4_nel_nsel_txt'});
#	diag Dumper(flow2txt($row));
	my $rr = flow2txt($row);
	foreach (keys %{$rr}) {
		if (defined($DS{'v4_nel_nsel_txt'}->{$_}) && $DS{'v4_nel_nsel_txt'}->{$_} ne $rr->{$_}) {
			diag sprintf "%s : %s -> %s\n", $_, $DS{'v4_nel_nsel_txt'}->{$_}, $rr->{$_};
			$invalid = 1;
		}
	}
	ok( $invalid == 0 );
#	ok( eq_hash( $DS{'v4_nel_nsel_txt'}, flow2txt($row)) );
}



