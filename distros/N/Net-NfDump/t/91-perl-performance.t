

BEGIN {
	use Config;
	if (! $Config{'useithreads'}) {
		print("1..0 # Skip: Perl not compiled with 'useithreads'\n");
		exit(0);
	}
}


use Test::More;

if (defined($ENV{'AUTOMATED_TESTING'}) && $ENV{'AUTOMATED_TESTING'} eq 1) {
	plan skip_all => 'Not performed as automated test';
} else {
	plan tests => 1;
}

use Net::NfDump qw ':all';
use Data::Dumper;
open(STDOUT, ">&STDERR");
our %DS;

require "t/ds.pl";

# testing performance 
diag "";
diag "Testing  performance, it will take while...";
diag "Method \$obj->storerow_hashref():";
my $recs = 300000;

my %tests = ( 'v4_basic_raw' => 'basic items', 'v4_raw' => 'all items' );

while (my ($key, $val) = each %tests ) {
	my $rec = $DS{$key};
	my $flow = new Net::NfDump(OutputFile => "t/flow_$key.tmp" );
	my $tm1 = time();
	for (my $x = 0 ; $x < $recs; $x++) {
#		printf STDERR "\n\nTEST XXX2 $x:\n";
		$flow->storerow_hashref( $rec );
	}
	$flow->finish();

	my $tm2 = time() - $tm1;
	diag sprintf("  %s: written %d recs in %d secs (%d/sec)", $val, $recs, $tm2, $recs/$tm2);
}


while (my ($key, $val) = each %tests ) {
	my $flow = new Net::NfDump(InputFiles => [ "t/flow_$key.tmp" ] );
	my $tm1 = time();
	my $cnt = 0;
	$flow->query();
	while ( $row = $flow->fetchrow_hashref() )  {
		$cnt++ if ($row);
	}
	$flow->finish();

	my $tm2 = time() - $tm1;
	diag sprintf("  %s: read %d recs in %d secs (%d/sec)", $val, $cnt, $tm2, $recs/$tm2);
}

diag "Method  \$obj->storerow_arrayref():";
$recs = 2000000;

%tests = ( 'v4_basic_raw' => 'basic items', 'v4_raw' => 'all items' );

while (my ($key, $val) = each %tests ) {
	my @fields  = keys %{$DS{$key}};
	my $rec = [ values %{$DS{$key}} ];
	my $flow = new Net::NfDump(OutputFile => "t/flow_$key.tmp", Fields => [ @fields ] );
	my $tm1 = time();
	for (my $x = 0 ; $x < $recs; $x++) {
		$flow->storerow_arrayref( $rec );
	}
	$flow->finish();

	my $tm2 = time() - $tm1;
	diag sprintf("  %s: written %d recs in %d secs (%d/sec)", $val, $recs, $tm2, $recs/$tm2);
}


while (my ($key, $val) = each %tests ) {
	my @fields  = keys %{$DS{$key}};
	my $flow = new Net::NfDump(InputFiles => [ "t/flow_$key.tmp" ], Fields => [ @fields ] );
	my $tm1 = time();
	my $cnt = 0;
	$flow->query();
	while ( $row = $flow->fetchrow_arrayref() )  {
		$cnt++ if ($row);
	}
	$flow->finish();

	my $tm2 = time() - $tm1;
	diag sprintf("  %s: read %d recs in %d secs (%d/sec)", $val, $cnt, $tm2, $recs/$tm2);
}

diag "Method  \$obj->clonerow():";

%tests = ( 'v4_basic_raw' => 'basic items', 'v4_raw' => 'all items' );

while (my ($key, $val) = each %tests ) {
	my $flowr = new Net::NfDump(InputFiles => [ "t/flow_$key.tmp" ], Fields => [ 'bytes' ] );
	my $floww = new Net::NfDump(OutputFile => "t/flow_clone_$key.tmp", Fields => [ 'bytes' ] );
	my $tm1 = time();
	my $cnt = 0;
	$flowr->query();
	while ( $row = $flowr->fetchrow_arrayref() )  {
		$floww->clonerow($flowr);
		$floww->storerow_arrayref($row);
		$cnt++ if ($row);
	}
	$floww->finish();
	$flowr->finish();

	my $tm2 = time() - $tm1;
	diag sprintf("  %s: read/write %d recs in %d secs (%d/sec)", $val, $cnt, $tm2, $recs/$tm2);
}

ok(1);

