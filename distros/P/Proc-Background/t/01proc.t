# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use strict;
use vars qw($loaded);

BEGIN { $| = 1; print "1..41\n"; }
END   {print "not ok 1\n" unless $loaded; }

my $ok_count = 1;
sub ok {
  shift or print "not ";
  print "ok $ok_count\n";
  ++$ok_count;
}

use Proc::Background qw(timeout_system);

package EmptySubclass;
use Proc::Background;
use vars qw(@ISA);
@ISA = qw(Proc::Background);

package main;

# If we got here, then the package being tested was loaded.
$loaded = 1;
ok(1);								# 1

# Find the sleep_exit.pl and timed-process scripts.  The sleep_exit.pl
# script takes a sleep time and an exit value.  timed-process takes a
# sleep time and a command to run.
my $sleep_exit;
foreach my $dir (qw(. ./bin ./t ../bin ../t Proc-Background/t)) {
  unless ($sleep_exit) {
    my $s = "$dir/sleep_exit.pl";
    $sleep_exit = $s if -r $s;
  }
}
$sleep_exit or die "Cannot find sleep_exit.pl.\n";
my @sleep_exit    = ($^X, '-w', $sleep_exit);
my $sleep_exit_cmdline= join ' ', map { $_ =~ /\S/? qq{"$_"} : $_ } @sleep_exit;

# Test the alive and wait returns.
my $p1 = EmptySubclass->new(@sleep_exit, 2, 26);
ok($p1);							# 2
if ($p1) {
  ok($p1->alive);						# 3
  sleep 3;
  ok(!$p1->alive);						# 4
  ok(($p1->wait >> 8) == 26);					# 5
} else {
  ok(0);							# 3
  ok(0);							# 4
  ok(0);							# 5
}

# Test alive, wait, and die on already dead process.  Also pass some
# bogus command line options to the program to make sure that the
# argument protecting code for Windows does not cause the shell any
# confusion.
my $p2 = EmptySubclass->new(@sleep_exit,
                            2,
                            5,
                            "\t",
                            '"',
                            '\" 10 \\" \\\\"');
ok($p2);							# 6
if ($p2) {
  ok($p2->alive);						# 7
  ok(($p2->wait >> 8) == 5);					# 8
  ok($p2->die);							# 9
  ok(($p2->wait >> 8) == 5);					# 10
} else {
  ok(0);							# 7
  ok(0);							# 8
  ok(0);							# 9
  ok(0);							# 10
}

# Test die on a live process and collect the exit value.  The exit
# value should not be 0.
my $p3 = EmptySubclass->new(@sleep_exit, 10, 0);
ok($p3);							# 11
if ($p3) {
  ok($p3->alive);						# 12
  sleep 1;
  ok($p3->die);							# 13
  ok(!$p3->alive);						# 14
  ok($p3->wait);						# 15
  ok($p3->end_time > $p3->start_time);				# 16
} else {
  ok(0);							# 12
  ok(0);							# 13
  ok(0);							# 14
  ok(0);							# 15
  ok(0);							# 16
}

# Test the timeout_system function.  In the first case, sleep_exit.pl
# should exit with 26 before the timeout, and in the other case, it
# should be killed and exit with a non-zero status.  Do not check the
# wait return value when the process is killed, since the return value
# is different on Unix and Win32 platforms.
my $a = timeout_system(2, @sleep_exit, 0, 26);
my @a = timeout_system(2, @sleep_exit, 0, 26);
ok($a>>8 == 26);						# 17
ok(@a == 2);							# 18
ok($a[0]>>8 == 26);						# 19
ok($a[1]    == 0);						# 20
$a = timeout_system(1, @sleep_exit, 4, 0);
@a = timeout_system(1, @sleep_exit, 4, 0);
ok($a);								# 21
ok(@a == 2);							# 22
ok($a[0]);							# 23
ok($a[1] == 1);							# 24

# Test the code to find a program if the path to it is not absolute.
my $p4 = EmptySubclass->new(@sleep_exit, 0, 0);
ok($p4);							# 25
if ($p4) {
  ok($p4->pid);							# 26
  sleep 2;
  ok(!$p4->alive);						# 27
  ok(($p4->wait >> 8) == 0);					# 28
} else {
  ok(0);							# 26
  ok(0);							# 27
  ok(0);							# 28
}

# Test a command line entered as a single string.
my $p5 = EmptySubclass->new("$sleep_exit_cmdline 2 26");
ok($p5);							# 29
if ($p5) {
  ok($p5->alive);						# 30
  sleep 3;
  ok(!$p5->alive);						# 31
  ok(($p5->wait >> 8) == 26);					# 32
} else {
  ok(0);							# 30
  ok(0);							# 31
  ok(0);							# 32
}

# Test the ability to pass options to Proc::Background::new.
my %options;
my $p6 = EmptySubclass->new(\%options, @sleep_exit, 0, 43);
ok($p6);							# 33
if ($p6) {
  ok(($p6->wait >> 8) == 43);					# 34
} else {
  ok(0);							# 34
}

# Test to make sure that the process is killed when the
# Proc::Background object goes out of scope.
$options{die_upon_destroy} = 1;
{
  my $p7 = EmptySubclass->new(\%options, @sleep_exit, 99999, 98);
  ok($p7);							# 35
  if ($p7) {
    my $pid = $p7->pid;
    ok(defined $pid);						# 36
    sleep 1;
    ok(kill(0, $pid) == 1);					# 37
    $p7 = undef;
    # sleep up to 10 seconds waiting for the process id to stop being valid
    my $kill= 1;
    for (1..10) { sleep 1; last if !($kill=kill(0, $pid)); }
    ok($kill == 0);					# 38
  } else {
    ok(0);							# 36
    ok(0);							# 37
    ok(0);							# 38
  }
}

# Test wait with a timeout on a process that doesn't exit.
my $p8 = EmptySubclass->new(@sleep_exit, 10, 0);
ok($p8);                             # 39
ok($p8 && $p8->alive);               # 40
ok($p8 && !defined $p8->wait(1.5));  # 41
$p8->die;

