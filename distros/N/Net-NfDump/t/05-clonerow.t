
BEGIN {
	use Config;
	if (! $Config{'useithreads'}) {
		print("1..0 # Skip: Perl not compiled with 'useithreads'\n");
		exit(0);
	}
}

use Test::More;
use Net::NfDump qw ':all';
use Data::Dumper;

open(STDOUT, ">&STDERR");


if ( ! -x "libnf/nfdump/bin/nfdump" ) {
	plan skip_all => 'nfdump executable not available';
	exit 0;
} else {
	plan tests => 1;
}


require "t/ds.pl";

# prepare some data
my ($flow);
$flow = new Net::NfDump(OutputFile => "t/clonerow.tmp" );
for (my $x = 1; $x < 10; $x++) {
	$flow->storerow_hashref( $DS{'v4_basic_raw'} );
	$flow->storerow_hashref( $DS{'v4_raw'} );
	$flow->storerow_hashref( $DS{'v6_raw'} );
}
$flow->finish();

# use clonerow
my ($floww, $flowr);

$flowr = new Net::NfDump(InputFiles => [ "t/clonerow.tmp" ], Fields => [ 'srcip' ] );
$floww = new Net::NfDump(OutputFile => "t/clonerow_out.tmp", Fields => [ 'srcip' ] );
while ( my $ref = $flowr->fetchrow_arrayref() )  {
	$floww->clonerow($flowr);
	$floww->storerow_arrayref($ref);
}

$flowr->finish();
$floww->finish();


SKIP: {

    system("libnf/nfdump/bin/nfdump -q -r t/clonerow.tmp -o raw | grep -v size > t/clonerow.txt.tmp");
    system("libnf/nfdump/bin/nfdump -q -r t/clonerow_out.tmp -o raw | grep -v size > t/clonerow_out.txt.tmp");

    system("diff t/clonerow.txt.tmp t/clonerow_out.txt.tmp");

    ok( $? == 0 );
}


