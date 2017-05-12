#
# The frontend has had a couple bugs where if stderr or stdout were closed
# before it started up, it wouldn't work right.
#

use strict;

print "1..2\n";

$| = 1;
my $myname = 'stdio_close';
use vars qw($TMP);
$TMP = "/tmp/${myname}$$";

sub onerun { my $use_stderr = shift;
    unlink $TMP;
    if (fork == 0) {
	alarm(3);
	close(STDIN);
	if ($use_stderr) {
	    close(STDOUT);
	    $^W = 0;
	    open(STDERR, ">$TMP");
	} else {
	    close(STDERR);
	    open(STDOUT, ">$TMP");
	}
	exec("$ENV{PERPERL} t/scripts/$myname $use_stderr");
    }
    wait;

    if (`cat $TMP` ne '') {
	print "ok\n";
    } else {
	print "not ok\n";
    }
    unlink $TMP;
}

&onerun(0);
&onerun(1);
alarm(0);
