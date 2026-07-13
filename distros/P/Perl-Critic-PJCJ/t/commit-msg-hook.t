#!/usr/bin/env perl

use v5.26.0;
use strict;
use warnings;

use Test2::V0    qw( done_testing is like skip_all subtest unlike );
use feature      qw( signatures );
use experimental qw( signatures );

use Cwd        qw( abs_path );
use File::Temp qw( tempdir );

skip_all "the commit-msg hook needs POSIX process control" if $^O eq "MSWin32";

use POSIX qw( setsid );

my $Hook = abs_path("utils/commit-msg-hook");
my $Work = tempdir(CLEANUP => 1);
my $N    = 0;

sub run_hook ($bytes) {
  $N++;
  my $msg = "$Work/msg$N.txt";
  my $out = "$Work/out$N.txt";
  open my $fh, ">:raw", $msg or die "Cannot write $msg: $!\n";
  print {$fh} $bytes;
  close $fh or die "Cannot close $msg: $!\n";

  my $pid = fork // die "Cannot fork: $!\n";
  unless ($pid) {
    delete @ENV{qw( GIT_DIR GIT_WORK_TREE GIT_COMMON_DIR )};
    setsid() != -1 or die "Cannot setsid: $!\n";
    chdir $Work    or die "Cannot chdir $Work: $!\n";
    open STDIN,  "<",  "/dev/null" or die "Cannot open /dev/null: $!\n";
    open STDOUT, ">",  $out        or die "Cannot open $out: $!\n";
    open STDERR, ">&", \*STDOUT    or die "Cannot dup stdout: $!\n";
    exec $^X, $Hook, $msg or die "Cannot exec $Hook: $!\n";
  }
  waitpid $pid, 0;
  my $exit = $? >> 8;
  open my $rd, "<:raw", $out or die "Cannot read $out: $!\n";
  my $output = do { local $/; <$rd> }
    // "";
  close $rd or die "Cannot close $out: $!\n";
  ($output, $exit)
}

subtest "Without a terminal the hook declines cleanly" => sub {
  my ($out, $exit) = run_hook("bad subject line\n\nTicket GH-1234\n");
  like $out,   qr/Errors found:/,  "the error report is printed";
  unlike $out, qr/Can't open tty/, "the hook does not die";
  unlike $out, qr/Force commit\?/, "no unanswerable prompt is printed";
  is $exit, 1, "the commit is rejected";
};

subtest "A clean message needs no terminal" => sub {
  my ($out, $exit) = run_hook("Improve the widget\n\nTicket GH-1234\n");
  is $out,  "", "no output";
  is $exit, 0,  "the commit is accepted";
};

subtest "An empty message is reported without printf warnings" => sub {
  my ($out, $exit) = run_hook("");
  like $out,   qr/Empty commit message/, "the empty message is reported";
  unlike $out, qr/Missing argument/,     "printf receives both values";
  is $exit, 1, "the commit is rejected";
};

subtest "A message with invalid UTF-8 is reported, not fatal" => sub {
  my ($out, $exit)
    = run_hook("Improve the widget\xE9 handling\n\nTicket GH-1234\n");
  like $out,   qr/not valid UTF-8/,         "the encoding is reported";
  unlike $out, qr/does not map to Unicode/, "the hook does not die";
  is $exit, 1, "the commit is rejected";
};

subtest "A valid UTF-8 message with multibyte characters passes" => sub {
  my ($out, $exit)
    = run_hook("Improve the widget\xC3\xA9 handling\n\nTicket GH-1234\n");
  is $out,  "", "no output";
  is $exit, 0,  "the commit is accepted";
};

subtest "Subject length is counted in characters, not bytes" => sub {
  my $subject = "Improve " . "\xC3\xA9" x 42;  # 50 characters, 92 bytes
  my ($out, $exit) = run_hook("$subject\n\nTicket GH-1234\n");
  is $exit, 0, "a 50-character multibyte subject is accepted";
};

done_testing
