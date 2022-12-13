#!/usr/bin/perl

use warnings;
use strict;
use Test::More;
use POSIX;
use FindBin;
use Mojo::File qw(tempfile path);
use lib ("$FindBin::Bin/lib", "../lib", "lib");

use Mojo::IOLoop::ReadWriteProcess              qw(process);
use Mojo::IOLoop::ReadWriteProcess::Test::Utils qw(attempt);
use Mojo::IOLoop;

subtest to_ioloop => sub {

  my $p = process(sub { print "Hello from first process\n"; sleep 1; exit 70 });

  $p->start();                   # Start and sets the handlers
  my $stream = $p->to_ioloop;    # Get the stream
  my $output;

  $stream->on(
    read => sub { $output .= pop; is $p->is_running, 1, 'Process is running!' }
  );    # Hook on Mojo::IOLoop::Stream events

  Mojo::IOLoop->singleton->start() unless Mojo::IOLoop->singleton->is_running;

  attempt {
    attempts  => 10,
    condition => sub { $p->is_running == 0 },
    cb        => sub { sleep 1 }
  };

  is $p->is_running,  0,  'Process is not running anymore';
  is $p->exit_status, 70, 'We got exit status';
  ok !$p->errored, 'No error from the process';
  is $output, "Hello from first process\n", 'Got correct output from process';
};

done_testing();
