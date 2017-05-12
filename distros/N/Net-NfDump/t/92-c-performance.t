
use Test::More;

if (defined($ENV{'AUTOMATED_TESTING'}) && $ENV{'AUTOMATED_TESTING'} eq 1) {
	plan skip_all => 'Not performed as automated test';
} else {
	plan tests => 1;
}

#open(STDOUT, ">&STDERR");


# testing performance 
diag "";
diag "Testing C performance, it will take while...";

$recs = 50000000;
diag "Preparing dataset with $recs records...";
system("libnf/examples/lnf_ex01_writer -n $recs ");


#%ctests = (' >/dev/null ' => 'read with output', '-p' => 'read without output', '-p -F' => 'read without output and filters');
%ctests = (
	'-P' => 'read without output', 
	'-P -F' => 'read without output and filters',
	'-P -F' => 'read without output and filters',
	'-P -F -G' => 'read without output and filters and lnf_fld_fget',
);

diag "Running read test using lnf_ex02_reader ...";
while (my ($opts, $name) = each %ctests) {

	$tm1 = time();
	system("libnf/examples/lnf_ex02_reader $opts");
	my $tm2 = time() - $tm1 + 1;

	diag sprintf("  %s (%s): %d recs in %d secs (%d/sec)", $name, $opts, $recs, $tm2, $recs/$tm2);
}

ok(1);

