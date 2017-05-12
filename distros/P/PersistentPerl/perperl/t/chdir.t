
# Test #1: if script cd's elsewhere, it should come back on the next run.

# Test #2: If the perl process does a chdir then hits the maxruns limit
# it should restart the next time from the original directory.

# Test #3 same as #1, but cd to /tmp in between runs.  The backend
# shoudl track the chdir

# Tests 4&5, similar to 1&3, but start from a path where the parent
# is unreabable, meaning getcwd will fail on some oses.  The backend
# may not be able to get to the right dir in 4, so don't check that.

# Tests 6&7, same as 4&5, but with current directory mode 0, which makes
# stat(".") fail.

print "1..7\n";

# Test 1
my $scr = 't/scripts/chdir';

use strict;
use vars qw($start);
$start = `pwd`;
chop $start;

my $PIDS = 1;
my $DIR = 2;
my $BOTH = ($PIDS | $DIR);

sub doit { my($maxruns, $tocheck, $cdto) = @_;
    utime time, time, "$start/$scr";
    sleep 1;
    my(@spdir, @pid);
    my $curdir = $start;
    for (my $i = 0; $i < 2; ++$i) {
	my $cmd = "$ENV{PERPERL} -- -r$maxruns $start/$scr";
	open(F, "$cmd |");
	chop($spdir[$i] = <F>);
	chop($pid[$i] = <F>);
	close(F);
	sleep 1;
	if ($cdto) {
	    chdir($cdto);
	    $curdir = `pwd`;	# $cdto may be a symlink, so get real path.
	    chop $curdir;
	}
    }
    #print STDERR "pid=", join(',', @pid), " spdir=", join(',', @spdir), "\n";
    my $ok = 1;
    if ($tocheck & $PIDS) {
	$ok = $ok && ($pid[0] == $pid[1] && $pid[0] > 0);
    }
    if ($tocheck & $DIR) {
	$ok = $ok && $curdir eq $spdir[1];
    }
    print $ok ? "ok\n" : "not ok\n";
}

&doit(2, $BOTH);
&doit(1, $DIR);
&doit(2, $BOTH, "/tmp");

chdir $start;
my $TMPDIR = "/tmp/unreadable$$";
mkdir $TMPDIR, 0777;
mkdir "$TMPDIR/x", 0777;
chdir "$TMPDIR/x";
chmod 0333, $TMPDIR;
&doit(2, $PIDS);
&doit(2, $BOTH, "/tmp");

chdir "$TMPDIR/x";
chmod 0, ".";
&doit(2, $PIDS);
&doit(3, $BOTH, "/tmp");

rmdir "$TMPDIR/x";
rmdir $TMPDIR;
