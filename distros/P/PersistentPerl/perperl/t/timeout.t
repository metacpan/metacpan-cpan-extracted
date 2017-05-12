# Basic test of the timeout feature (-t)

print "1..1\n";

delete $ENV{PERPERL_TIMEOUT};

my $scr = 't/scripts/basic.2';
my $cmd = "$ENV{PERPERL} -- -t2 -M1 $scr";

# The script just returns 1, 2, 3 incrementing the persistent counter
# each time it runs.  If -t is working, then the third time we should
# get 1 again.

utime time, time, $scr;
sleep 2;

my $one = `$cmd`;
my $two = `$cmd`;
sleep 3;
my $three = `$cmd`;

#print STDERR "one=$one two=$two three=$three\n";

print $one == 1 && $two == 2 && $three == 1 ? "ok\n" : "not ok\n";
