# Kill the fe in the middle of a run and see if perperl recovers

print "1..1\n";

my $scr = 't/scripts/maxbackend';
utime time, time, $scr;
sleep 1;

my $cmd = "exec $ENV{PERPERL} -- -M1 $scr </dev/null |";

my $pid = open (RUN1, $cmd);
sleep(1);
kill(9, $pid);
wait;
open (RUN2, $cmd);

$pid1 = <RUN1>; chop $pid1;
$pid2 = <RUN2>; chop $pid2;

## print "pid1=$pid1 pid2=$pid2\n";

close(RUN1);
close(RUN2);

my $ok =  $pid1 && $pid1 == $pid2;

foreach my $p ($pid1, $pid2) {
    $p && kill 9, $p;
}

print $ok ? "ok\n" : "not ok\n";
