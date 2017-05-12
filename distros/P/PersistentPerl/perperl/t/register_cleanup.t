#
# Test that the cleanup method works.  It should run the prints in the
# order in which they were registered.
#
# The cleanups should only run if registered each time - shouldn't persist.
# In the second run we turn off the registration, so we shouldn't get
# those lines.
#

print "1..2\n";

my $scr = 't/scripts/register_cleanup';
utime time, time, $scr;
sleep 1;

sub doit { my($arg, $result) = @_;
    my @lines = `$ENV{PERPERL} $scr $arg`;
    #print STDERR "script returned:\n", @lines;
    my $ok = join('', @lines) eq $result;
    print $ok ? "ok\n" : "not ok\n";
}

&doit(1, "1\n2\n3\n4\n");
&doit(0, "1\n2\n");
