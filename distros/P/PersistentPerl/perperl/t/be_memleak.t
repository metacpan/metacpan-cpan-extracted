# Backend parent leaked during fork in release 2.21.
# Also, test the backend itself for leakage.

my $scr = 't/scripts/be_memleak';
my $runs = 1000;
my $sanity = 100;

sub doruns { my($num, $cmd) = @_;
    my $mem;
    while (--$num) {
	`$cmd 0`;
    }
    $mem = `$cmd 1`;
    #print STDERR "mem=$mem\n";
    if (!defined($mem) || $mem !~ /^\d/) {
	$mem = 0;
    }
    return $mem;
}

sub onetest { my $cmd = shift;
    utime time, time, $scr;
    sleep 2;

    my $memused = &doruns(1, $cmd);
    if ($memused < $sanity) {
	return undef;
    }

    $memused = &doruns(5, $cmd);
    my $end = &doruns($runs, $cmd);

    #print STDERR "mem was $memused end usage is $end\n";

    my $result;
    if ($end > $memused || $end < $sanity) {
	$result = "not ok";
	print STDERR " mem usage went from ${memused}K to ${end}K in $runs runs\n";
    } else {
	$result = "ok";
    }
    #print STDERR "Returning result $result\n";
    return $result;
}

# Test#1 - backend parent fork leak.
my $result = &onetest("$ENV{PERPERL} -- -r1 $scr 1");
if (!defined($result)) {
    print "1..0  # Skipped: Cannot determine memory usage\n";
    exit(0);
}
print "1..2\n$result\n";

# Test #2 - the backend itself
print &onetest("$ENV{PERPERL} -- -r1000000 $scr 0"), "\n";
