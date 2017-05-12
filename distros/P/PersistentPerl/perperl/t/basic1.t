
print "1..1\n";

# Test 1 - just print something
my $str = "hello_world";
my $line = `$ENV{PERPERL} t/scripts/basic.1 $str`;
print ($line eq $str ? "ok\n" : "not ok\n");
