
# Test#1
# Bug in 2.11 release.  The frontend blocks sigalarms, but fails to unblock
# them after forking the backend, making alarms unusable in the backend.

# Test#2
# Alarms that occur after perl exits should have no effect on the backend.

print "1..2\n";

# Test 1 - just print something
my $line = `$ENV{PERPERL} t/scripts/alarm`;
print ($line =~ /fail/ ? "not ok\n" : "ok\n");

# Test 2 -
my $pid1 = 0 + `$ENV{PERPERL} t/scripts/alarm 1`;
sleep(2);
my $pid2 = 0 + `$ENV{PERPERL} t/scripts/alarm 1`;
if ($pid1 > 0 && $pid1 == $pid2) {
    print "ok\n";
} else {
    print "not ok\n";
}
