
print "1..1\n";

# Test 2 - check persistence - see if we get the same backend twice in a row
my $numruns = 4;
my $scr = 't/scripts/basic.2';
my $num;
utime time, time, $scr;
for (my $i = $numruns; $i > 0; --$i) {
    sleep 2;
    $num = `$ENV{PERPERL} $scr`;
}
print ($num == $numruns ? "ok\n" : "not ok\n");
