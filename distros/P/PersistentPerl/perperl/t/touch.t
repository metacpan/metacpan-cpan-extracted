#
# Do a touch on a script file while it is running.  It should finish
# running OK, but the next run should have a different pid.
#
print "1..1\n";

my $scr = 't/scripts/touch';

my($pid1,$pid2) = split(/\n/, `$ENV{PERPERL} $scr $scr`);
my($pid3) = split(/\n/, `$ENV{PERPERL} $scr`);

#print STDERR "1=$pid1 2=$pid2 3=$pid3\n";

my $ok = $pid1 && $pid2 && $pid3 && $pid1 == $pid3 && $pid1 != $pid2;

print $ok ? "ok\n" : "not ok\n";
