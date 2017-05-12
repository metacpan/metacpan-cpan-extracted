
# Pass lots of data through the script.  At the end of each run, our
# test script messes up the STD* files.  See if perperl will fix them
# files before the next run.

my $do_stderr	= 1;
my $num		= 10000;
my $tmp		= "/tmp/perperl_stdio.$$";
my $max		= $do_stderr ? 4 : 2;
my @redirects	= $do_stderr ? (">$tmp", "1 2>$tmp") : (">$tmp");

print "1..$max\n";

# Do two passes to give the script a chance to mess up the files between runs.
for (my $j = 0; $j < 2; ++$j) {
    # Do both stdout and stderr
    foreach my $redirect (@redirects) {
	open(F, "| $ENV{PERPERL} -- -r2 t/scripts/stdio2 $redirect");
	for (my $i = 1; $i < $num; ++$i) {
	    print F "$i\n";
	}
	close(F);

	my $ok = 1;
	open(F, "<$tmp");
	for (my $i = 1; $i < $num; ++$i) {
	    $_ = <F>;
	    ## print STDERR "got $_\n";
	    if ($_ != $i) {
		$ok = 0; last;
	    }
	}
	close(F);
	print $ok ? "ok\n" : "not ok\n";

	unlink($tmp);
    }
}
