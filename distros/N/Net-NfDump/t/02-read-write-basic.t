
BEGIN {
	use Config;
	if (! $Config{'useithreads'}) {
		print("1..0 # Skip: Perl not compiled with 'useithreads'\n");
		exit(0);
	}
}


use Test::More tests => 16;
use Net::NfDump qw ':all';
use Data::Dumper;

open(STDOUT, ">&STDERR");

require "t/ds.pl";

# testing v4
my ($floww, $flowr);
$floww = new Net::NfDump(OutputFile => "t/v4_rec.tmp" );
$floww->storerow_hashref( $DS{'v4_raw'} );
$floww->storerow_hashref( $DS{'v4_raw'} );
$floww->finish();

$flowr = new Net::NfDump(InputFiles => [ "t/v4_rec.tmp" ] );
while ( my $row = $flowr->fetchrow_hashref() )  {
#	diag Dumper(flow2txt($row));
	#diag Dumper($DS{'v4_txt'});
	
	# remove exporter_id because this is assigned internally 
	delete($row->{'exporterid'});

	ok( eq_hash( $DS{'v4_raw'}, $row) );
	ok( eq_hash( $DS{'v4_txt'}, flow2txt($row)) );
	my $rr = flow2txt($row);
	foreach (keys %{$rr}) {
		if ($DS{'v4_txt'}->{$_} ne $rr->{$_}) {
			diag sprintf "\n%s : %s -> %s\n", $_, $DS{'v4_txt'}->{$_}, $rr->{$_};
		}
	}

}

#exit 1;

# testing v6
$floww = new Net::NfDump(OutputFile => "t/v6_rec.tmp" );
$floww->storerow_hashref( $DS{'v6_raw'} );
$floww->storerow_hashref( $DS{'v6_raw'} );
$floww->finish();


$flowr = new Net::NfDump(InputFiles => [ "t/v6_rec.tmp" ] );
while ( my $row = $flowr->fetchrow_hashref() )  {
	# remove exporter_id because this is assigned internally 
	delete($row->{'exporterid'});
	my $rr = flow2txt($row);
	ok( eq_hash( $DS{'v6_raw'}, $row) );
	ok( eq_hash( $DS{'v6_txt'}, flow2txt($row)) );
	foreach (keys %{$rr}) {
		if ($DS{'v6_txt'}->{$_} ne $rr->{$_}) {
			diag sprintf "\n%s : %s -> %s\n", $_, $DS{'v6_txt'}->{$_}, $rr->{$_};
		}
	}
}
$flowr->finish();

# testing fetchrow_array
$floww = new Net::NfDump(OutputFile => "t/v6_rec2.tmp", Fields => ['srcip', 'dstip'] );
$floww->storerow_array($DS{'v6_raw'}->{'srcip'}, $DS{'v6_raw'}->{'dstip'});
$floww->storerow_array($DS{'v6_raw'}->{'srcip'}, $DS{'v6_raw'}->{'dstip'});
$floww->finish();

$flowr = new Net::NfDump(InputFiles => [ "t/v6_rec2.tmp" ], Fields => ['srcip', 'dstip'] );
while ( my ($srcip, $dstip) = $flowr->fetchrow_array() ) {
	ok( ip2txt($srcip), $DS{'v6_txt'}->{'srcip'} );
	ok( ip2txt($dstip), $DS{'v6_txt'}->{'dstip'} );
}
$flowr->finish();


# testing fields as a string 
$flowr = new Net::NfDump(InputFiles => "t/v6_rec2.tmp" , Fields => 'srcip, dstip' );
while ( my ($srcip, $dstip) = $flowr->fetchrow_array() ) {
	ok( ip2txt($srcip), $DS{'v6_txt'}->{'srcip'} );
	ok( ip2txt($dstip), $DS{'v6_txt'}->{'dstip'} );
}
$flowr->finish();

