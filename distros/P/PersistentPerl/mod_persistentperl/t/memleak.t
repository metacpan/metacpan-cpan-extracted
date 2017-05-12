#
# See if mod_persistentperl leaks memory.  Do 100 requests to stabilize the memory
# usage, get the amount of memory in use, then do another 200 requests and
# see if the usage goes up. 
#
# This test only works on linux.
#

use lib 't';
use ModTest;

my $scr = 'perperl/pid';

ModTest::test_init(60, [$scr]);

my $pid = ModTest::get_httpd_pid;

sub mem_used {
    open(PS, "ps -o vsz -p $pid |");
    scalar <PS>;
    my $val = int(<PS>);
    close(PS);
    return $val;
}

sub do_requests { my $times = shift;
    ModTest::http_get("/$scr") while ($times--);
}

if (&mem_used) {
    print "1..1\n";
    &do_requests(50);
    my $mem1 = &mem_used;
    &do_requests(400);
    my $mem2 = &mem_used;
    ## print STDERR "mem1=$mem1 mem2=$mem2\n";
    if ($mem2 <= $mem1) {
	print "ok\n";
    } else {
	print "not ok\n";
    }
} else {
    print "1..0\n";
}
