# BAsic test of the maxruns feature (-r)

print "1..1\n";

my $scr = 't/scripts/basic.2';
my $cmd = "$ENV{PERPERL} -- -r2 $scr";

# The script just returns 1, 2, 3 incrementing the persistent counter
# each time it runs.  If -r2 is working, then the third time we should
# get 1 again.

utime time, time, $scr;
sleep 2;

my $one = `$cmd`;
sleep 1;
my $two = `$cmd`;
my $three = `$cmd`;

## print "one=$one two=$two three=$three\n";

print $one == 1 && $two == 2 && $three == 1 ? "ok\n" : "not ok\n";
