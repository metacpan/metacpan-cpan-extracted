

BEGIN {
	use Config;
	if (! $Config{'useithreads'}) {
		print("1..0 # Skip: Perl not compiled with 'useithreads'\n");
		exit(0);
	}
}

use Test::More tests => 2;;
open(STDOUT, ">&STDERR");

use Net::NfDump qw ':all';
use Data::Dumper;

my %data =( 

	'version' => '*',
	'nfdump_version' => '*',
	'ident' => 'none',
	'blocks' => '1',
	'catalog' => '0',
	'anonymized' => '0',
	'compressed' => '1',
	'sequence_failures' => '0',

	'first' => '1354046356360',
	'last' => '1354046668173',

	'flows' => '8170',
#	'flows_tcp' => '14',
#	'flows_udp' => '8092',
#	'flows_icmp' => '63',
#	'flows_other' => '1',

	'bytes' => '2641163',
#	'bytes_tcp' => '10611',
#	'bytes_udp' => '2613720',
#	'bytes_icmp' => '16792',
#	'bytes_other' => '40',

	'packets' => '8534',
#	'packets_tcp' => '73',
#	'packets_udp' => '8346',
#	'packets_icmp' => '114',
#	'packets_other' => '1',
	);

# we will use the output file from the previous test 

my %data2 =( 
	'total_files' => 1,
	'percent' => 100,
	'remaining_time' => 0,
	'elapsed_time' => 0,
	'processed_files' => 1,
	'processed_blocks' => 1,
	'current_processed_blocks' => 1,
	'current_total_blocks' => 1
);


my $info = file_info("t/data2");
$info->{'nfdump_version'} = '*';
$info->{'version'} = '*';
#diag Dumper($info);

foreach (keys %{$info}) {
	if ($data{$_} ne $info->{$_}) {
		diag sprintf "\n%s : %s -> %s\n", $_, $->{$_}, $info->{$_};
	}
}
ok( eq_hash($info, \%data) );


$flowr = new Net::NfDump(InputFiles => [ "t/v4_rec.tmp" ] );

while ( my $row = $flowr->fetchrow_hashref() )  {

	my $i = $flowr->info();
#	diag Dumper($i);
#	diag Dumper(\%data2);
	ok( eq_hash(\%data2, $i) );
	last;

}

