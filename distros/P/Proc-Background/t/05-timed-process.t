use strict;
use Test;
BEGIN { plan tests => 9; }
use Proc::Background qw(timeout_system);

# Find the lib directory.
my $lib;
foreach my $l (qw(lib ../lib)) {
  if (-d $l) {
    $lib = $l;
    last;
  }
}
$lib or die "Cannot find lib directory.\n";

# Find the sleep_exit.pl and timed-process scripts.  The sleep_exit.pl
# script takes a sleep time and an exit value.  timed-process takes a
# sleep time and a command to run.
my $sleep_exit;
my $timed_process;
foreach my $dir (qw(. ./bin ./t ../bin ../t Proc-Background/t)) {
  unless ($sleep_exit) {
    my $s = "$dir/sleep_exit.pl";
    $sleep_exit = $s if -r $s;
  }
  unless ($timed_process) {
    my $t = "$dir/timed-process";
    $timed_process = $t if -r $t;
  }
}
$sleep_exit or die "Cannot find sleep_exit.pl.\n";
$timed_process or die "Cannot find timed-process.\n";
my @sleep_exit    = ($^X, '-w', $sleep_exit);
my @timed_process = ($^X, '-w', "-I$lib", $timed_process);
my $sleep_exit_cmdline= join ' ', map { $_ =~ /\S/? qq{"$_"} : $_ } @sleep_exit;

sub System {
  my $result = system(@_);
  return ($? >> 8, $? & 127, $? & 128);
}

# Test the timed-process script.  First test a normal exit.
my @t_args = ($^X, '-w', "-I$lib", $timed_process);
my @result = System(@t_args, '-e', 153, 3, "$sleep_exit_cmdline 0 237");
ok($result[0], 237);
ok($result[1],   0);
ok($result[2],   0);

@result = System(@t_args, 1, "$sleep_exit_cmdline 10 27");
ok($result[0], 255);
ok($result[1],   0);
ok($result[2],   0);

@result = System(@t_args, '-e', 153, 1, "$sleep_exit_cmdline 10 27");
ok($result[0], 153);
ok($result[1],   0);
ok($result[2],   0);

