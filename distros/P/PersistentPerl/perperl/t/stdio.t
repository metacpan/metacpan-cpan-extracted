
# Basic stdio test.  Pass a list of numbers through our script which
# does a "cat", and we should get back the same list.

my $do_stderr	= 1;
my $num		= 10000;
my $tmp		= "/tmp/perperl_stdio.$$";
my $max		= $do_stderr ? 4 : 2;
my @redirects	= $do_stderr ? (">$tmp", "1 2>$tmp") : (">$tmp");

print "1..$max\n";

for (my $j = 0; $j < 2; ++$j) {
    foreach my $redirect (@redirects) {
	open(F, "| $ENV{PERPERL} t/scripts/stdio $redirect");
	for (my $i = 1; $i < $num; ++$i) {
	    print F "$i\n";
	}
	close(F);

	my $ok = 1;
	open(F, "<$tmp");
	for (my $i = 1; $i < $num; ++$i) {
	    $_ = <F>;
	    #print "Got: $_";
	    if ($_ != $i) {
		$ok = 0; last;
	    }
	}
	close(F);
	print $ok ? "ok\n" : "not ok\n";

	unlink($tmp);
    }
}
