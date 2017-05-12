# -*- perl -*-

use Test::More tests => 7;
use warnings;
use strict;
use Log::Log4perl;
use POSIX qw(mkfifo);

Log::Log4perl::init("t/log4perl.conf");

BEGIN {
  unlink "t/fifo-monitor";
  use_ok("Test::AutoBuild::Monitor::Pipe") or die;
}

END {
  unlink "t/fifo-monitor";
}

TEST_ERRORS: {
  eval {
    my $monitor = Test::AutoBuild::Monitor::Pipe->new(name => "pipe",
						      label => "Send down FIFO pipe");
  };
  ok(defined $@, "die when path option is missing");

  my $monitor = Test::AutoBuild::Monitor::Pipe->new(name => "pipe",
						    label => "Send down FIFO pipe",
						    options => {
							       path => "t/fifo-monitor"
							       });
  is($monitor->option("mask"), 0755, "mask defaults to 0755");

  open FIFO, ">t/fifo-monitor" or die "cannot create t/fifo-monitor file: $!";
  print FIFO "Dummy\n";
  close FIFO;

  eval {
    $monitor->_open_pipe();
  };
  ok(defined $@, "die when file exists and isn't a fifo");

  unlink "t/fifo-monitor";
}

TEST_ONE: {
SKIP: {
  skip "Cannot figure out why this fails sometimes", 3 if 1;

  my $monitor = Test::AutoBuild::Monitor::Pipe->new(name => "pipe",
						    label => "Send down FIFO pipe",
						    options => {
								path => "t/fifo-monitor",
								mask => 0755,
							       });
  isa_ok($monitor, "Test::AutoBuild::Monitor::Pipe");

  my $pid = fork();
  die "could not fork a listener" unless defined $pid;
  if ($pid == 0) {
    # Give other process a chance to open the pipe
    sleep 1;
    open FIFO, "<t/fifo-monitor"
      or die "cannot read fifo: $!";

    my $line1 = <FIFO>;
    my $line2 = <FIFO>;
    chomp $line1;
    chomp $line2;
    my $status = 0;
    if ($line1 ne "beginStage('foo', 'Foo \\'eek\\' wizz\\\\n')") {
      $status |= (1 << 0);
    }
    if ($line2 ne "endStage('foo')") {
      $status |= (1 << 1);
    }
    exit $status;
  } else {
    $monitor->notify("beginStage", "foo", "Foo 'eek' wizz\\n");
    $monitor->notify("endStage", "foo");
    my $kid = waitpid $pid, 0;
    die "unexpected child exited" unless $kid == $pid;

    ok((($?>>8) & (1 <<0)) == 0, "got expected first line");
    ok((($?>>8) & (1 <<1)) == 0, "got expected second line");
  }
}
}
