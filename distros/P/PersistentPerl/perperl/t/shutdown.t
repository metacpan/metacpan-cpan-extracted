
# Test the shutdown handler method in the PersistentPerl module.

print "1..5\n";

my $testf = "/tmp/perperl.shutdown_done.$$";
my $scr = 't/scripts/shutdown';
unlink($testf);

utime time, time, $scr;
sleep 1;

sub run { my($whichtest, $nomaxruns) = @_;
    my $maxruns = $nomaxruns ? '' : '-r2';
    my $val = `$ENV{PERPERL} -- $maxruns t/scripts/shutdown $testf $whichtest`;
    sleep 1;
    chomp $val;
    return $val;
}

# The shutdown script that we run should create $testf when it
# shuts down.  Test both add_shutdown_handler and set_shutdown_handler.
#
# Run twice by setting the maximum number of runs.
# After the first run, the file should not exist,
# but after the second run, it should exist.
#
for (my $i = 0; $i < 2; $i++) {
    if (&run($i) > 0 && ! -f $testf && &run($i) > 0 && -f $testf) {
	print "ok\n"
    } else {
	print "not ok\n";
    }
    unlink $testf;
}

# Test shutdown_next_time
if (&run(2) > 0 && -f $testf) {
    print "ok\n";
} else {
    print "not ok\n";
}
unlink $testf;

# Test shutdown_now
if (!&run(3) && -f $testf) {
    print "ok\n";
} else {
    print "not ok\n";
}
unlink $testf;

# Test whether a touch on the script causes the shutdown handler to be called
if (&run(1, 1) > 0 && utime(time, time, $scr) && &run(1, 1) > 0 && -f $testf) {
    print "ok\n";
} else {
    print "not ok\n";
}
unlink $testf;
