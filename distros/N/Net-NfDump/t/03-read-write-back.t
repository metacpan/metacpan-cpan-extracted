
BEGIN {
	use Config;
	if (! $Config{'useithreads'}) {
		print("1..0 # Skip: Perl not compiled with 'useithreads'\n");
		exit(0);
	}
}

use Test::More;
open(STDOUT, ">&STDERR");

if ( ! -x "libnf/nfdump/bin/nfdump" ) {
	plan skip_all => 'nfdump executable not available';
	exit 0;
} else {
	plan tests => 1;
}

use Net::NfDump qw ':all';

# 
my ($floww, $flowr);
$flowr = new Net::NfDump(InputFiles => [ "t/data1" ] );
$floww = new Net::NfDump(OutputFile => "t/data2.tmp" );

use Data::Dumper;

while ( my $raw = $flowr->fetchrow_hashref() ) {
	
	my $plain = flow2txt($raw);
	my $raw2 = txt2flow($plain);
	$floww->storerow_hashref($raw2);
}

$flowr->finish();
$floww->finish();

SKIP: { 

	system("libnf/nfdump/bin/nfdump -q -r t/data1 -o raw | grep -v size > t/data1.txt.tmp");
	system("libnf/nfdump/bin/nfdump -q -r t/data2.tmp -o raw | grep -v size > t/data2.txt.tmp");

	system("diff -u t/data1.txt.tmp t/data2.txt.tmp");

	ok( $? == 0 );
}

