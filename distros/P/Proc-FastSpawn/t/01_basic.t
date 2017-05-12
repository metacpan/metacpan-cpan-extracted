BEGIN { $| = 1; print "1..9\n"; }

use Proc::FastSpawn;

print "ok 1\n";

my $pid = spawn $^X, ["perl", "-e", "exit 5"];
print $pid ? "" : "not ", "ok 2\n";
print +($pid == waitpid $pid, 0) ? "" : "not ", "ok 3\n";
print $? == 0x0500 ? "" : "not ", "ok 4\n";

print "ok 5\n";

$pid = spawnp $^X, ["perl", "-e", "exit 6"];
print $pid ? "" : "not ", "ok 6\n";
print +($pid == waitpid $pid, 0) ? "" : "not ", "ok 7\n";
print $? == 0x0600 ? "" : "not ", "ok 8\n";

print "ok 9\n";
