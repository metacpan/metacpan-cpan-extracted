
# Test exit status from backend
# Test 1 - normal exit 0
# Test 2 - non-normal exit
# Test 3 - kill with catchable sig
# Test 4 - kill wtih non-catchable sig
# Test 5 - kill our parent - should eventually get status of sigkill.

my @list = (0, 256, 15, 9, 9);

printf "1..%d\n", scalar @list;

for (my $i = 0; $i <= 4; ++$i) {
    my $val = system("$ENV{PERPERL} t/scripts/exit $i");
    if ($val == $list[$i]) {
	print "ok\n";
    } else {
	print "not ok # got $val instead of $list[$i]\n";
    }
}
