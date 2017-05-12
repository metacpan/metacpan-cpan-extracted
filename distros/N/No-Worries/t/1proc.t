#!perl

use strict;
use warnings;
use Config qw(%Config);
use Test::More;
use File::Temp qw(tempdir);
use No::Worries::File qw(file_read file_write);

use No::Worries::Proc qw(*);

our($perl, $tmpdir, $path, $status, $stdin, $stdout, $stderr, $test, %proc);

#
# operating system checks
#

if ($^O =~ /^(cygwin|dos|MSWin32)$/) {
    plan skip_all => "Not supported (yet) on $^O";
} else {
    plan tests => 41;
}

#
# helpers
#

sub tp (@) {
    return($perl, "tp", @_);
}

sub match ($$$) {
    my($string, $regexp, $message) = @_;

    if ($string =~ $regexp) {
	ok(1, $message);
    } else {
	is($string, "match $regexp", $message);
    }
}

#
# setup
#

$perl = $Config{perlpath};
$tmpdir = tempdir(CLEANUP => 1);
chdir($tmpdir) or die("*** cannot chdir($tmpdir): $!\n");
END {
    chdir("/") or die("*** cannot chdir(/): $!\n");
}

file_write("tp", data => join("", <DATA>));

#
# simple tests
#

$status = $stdin = $stdout = $stderr = undef;
$status = proc_run(command => [ tp(qw(-stdout -stderr)) ], stdout => \$stdout, stderr => \$stderr);
is($status, 0, "status 0");
is($stdout, "stdout\n", "stdout");
is($stderr, "stderr\n", "stderr");

$status = $stdin = $stdout = $stderr = undef;
$status = proc_run(command => [ tp(qw(-stderr -exit 7)) ], stdout => \$stdout, stderr => "");
is($status, 7<<8, "status 7<<8");
is($stdout, "stderr\n", "stderr on stdout");

$status = $stdin = $stdout = $stderr = undef;
$path = "test.stdout";
$status = proc_run(command => [ tp(qw(-stdout)) ], stdout => $path);
is(file_read($path), "stdout\n", "file stdout");
ok(unlink($path), "unlink");

$status = $stdin = $stdout = $stderr = undef;
%proc = proc_run(command => [ tp(qw(-stdout -stderr -sleep 10)) ], stdout => \$stdout, stderr => \$stderr, timeout => 0.9);
ok($proc{timeout}, "timeout");
is($stdout, "", "empty stdout");
match($stderr, qr/ received SIG[A-Z]+ /, "killed stderr");

$path = "test.stdin";
$test = scalar(localtime(time())) . "\n";
file_write($path, data => $test);
$test = sprintf("STDIN:%s\n", unpack("%32C*", $test));

$status = $stdin = $stdout = $stderr = undef;
$status = proc_run(command => [ tp(qw(-checksum)) ], stdin => $path, stdout => \$stdout, stderr => \$stderr);
is($status, 0, "status 0");
is($stdout, $test, "stdout");
is($stderr, "", "stderr");

$status = $stdin = $stdout = $stderr = undef;
$stdin = file_read($path);
$status = proc_run(command => [ tp(qw(-checksum)) ], stdin => \$stdin, stdout => \$stdout, stderr => \$stderr);
is($status, 0, "status 0");
is($stdout, $test, "stdout");
is($stderr, "", "stderr");

ok(unlink($path), "unlink");

$stdout = proc_output(tp(qw(--count 1 --stdout)));
is($stdout, "stdout 1\n", "output");

#
# advanced tests
#

$status = $stdin = $stdout = $stderr = undef;
%proc = ();
# start
$proc{stdout} = proc_create(command => [ tp(qw(-stdout)) ], stdout => \$stdout);
$proc{stderr} = proc_create(command => [ tp(qw(-stderr -sleep 10)) ], stderr => \$stderr);
foreach $test (qw(command pid start)) {
    ok($proc{stdout}{$test}, "proc stdout $test");
    ok($proc{stderr}{$test}, "proc stderr $test");
}
foreach $test (qw(stop status timeout)) {
    ok(!defined($proc{stdout}{$test}), "proc stdout !$test");
    ok(!defined($proc{stderr}{$test}), "proc stderr !$test");
}
# wait for one to finish => must be stdout
proc_monitor([ values(%proc) ], deaths => 1);
ok($proc{stdout}{stop}, "proc stdout stop");
is($proc{stdout}{status}, 0, "proc stdout status");
ok(!defined($proc{stdout}{timeout}), "proc stdout !timeout");
is($stdout, "stdout\n", "proc stdout stdout");
foreach $test (qw(stop status timeout)) {
    ok(!defined($proc{stderr}{$test}), "proc stderr !$test");
}
# terminate the other
select(undef, undef, undef, 0.9);
proc_terminate($proc{stderr});
proc_monitor([ values(%proc) ], timeout => 0);
ok($proc{stderr}{stop}, "proc stderr stop");
ok($proc{stderr}{status}, "proc stderr status");
ok(!defined($proc{stderr}{timeout}), "proc stderr !timeout");
match($stderr, qr/ received SIG[A-Z]+ /, "proc stderr stderr");

__DATA__
#
# No::Worries::Proc Test Program
#

use strict;
use warnings;
use Getopt::Long qw(GetOptions);

our(%Option);

sub init () {
    $SIG{INT} = $SIG{QUIT} = $SIG{TERM} = sub { die("tp: received SIG$_[0]") };
    $Option{exit} = 0;
    $Option{separator} = "\n";
    GetOptions(\%Option,
	"checksum",
        "count|c=i",
        "help|h|?",
        "separator=s",
        "sleep=i",
        "exit=i",
        "stderr",
        "stdout",
        "unbuffer",
    ) or die;
}

sub main () {
    $| = 1 if $Option{unbuffer};
    if ($Option{checksum}) {
	printf(STDOUT "STDIN:%s\n", unpack("%32C*", <STDIN>));
    } elsif ($Option{count}) {
	foreach (1 .. $Option{count}) {
	    sleep($Option{sleep}) if $_ != 1 and $Option{sleep};
	    print(STDOUT "stdout $_$Option{separator}") if $Option{stdout};
	    print(STDERR "stderr $_$Option{separator}") if $Option{stderr};
	}
    } else {
	sleep($Option{sleep}) if $Option{sleep};
	print(STDOUT "stdout$Option{separator}") if $Option{stdout};
	print(STDERR "stderr$Option{separator}") if $Option{stderr};
    }
    exit($Option{exit});
}

init();
main();
