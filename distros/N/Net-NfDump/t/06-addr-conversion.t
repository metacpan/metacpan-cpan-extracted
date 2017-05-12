
BEGIN {
	use Config;
	if (! $Config{'useithreads'}) {
		print("1..0 # Skip: Perl not compiled with 'useithreads'\n");
		exit(0);
	}
}

use Test::More tests => 4;
open(STDOUT, ">&STDERR");

use Net::NfDump qw ':all';


my $flowr = new Net::NfDump(InputFiles => [ "t/record_v6" ] );

while ( my $raw = $flowr->fetchrow_hashref() ) {
	
	my $plain = flow2txt($raw);

	$plain->{'srcip'} =~ s/:0:/::/g;
	ok($plain->{'srcip'} eq '2a00:bdc0:3:102:2::402:831');
	ok($plain->{'dstip'} eq '2001:67c:1220:c1a2:297f:d8d6:8a71:bac8');
}

$flowr->finish();


$flowr = new Net::NfDump(InputFiles => [ "t/record_v4" ] );

while ( my $raw = $flowr->fetchrow_hashref() ) {
	
	my $plain = flow2txt($raw);

	ok($plain->{'srcip'} eq '147.229.3.135');
	ok($plain->{'dstip'} eq '10.255.5.6');
}

$flowr->finish();


