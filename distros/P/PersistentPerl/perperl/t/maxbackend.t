
# Check to see if the maxbackends limit is in effect

print "1..1\n";

my $scr = 't/scripts/maxbackend';
utime time, time, $scr;
sleep 1;

my $cmd = "$ENV{PERPERL} -- -M2 $scr </dev/null |";

open (RUN1, $cmd);
sleep 1;
open (RUN2, $cmd);
sleep 1;
open (RUN3, $cmd);

$pid1 = <RUN1>; chop $pid1;
$pid2 = <RUN2>; chop $pid2;
$pid3 = <RUN3>; chop $pid3;

close(RUN1);
close(RUN2);
close(RUN3);

my $ok =  $pid1 && ($pid3 == $pid1 || $pid2 == $pid1); 

foreach my $p ($pid1, $pid2, $pid3) {
    $p && kill 9, $p;
}

print $ok ? "ok\n" : "not ok\n";
