#!/usr/bin/perl

use warnings;
use strict;
use Test::More;
use POSIX;
use FindBin;
use lib ("$FindBin::Bin/lib", "../lib", "lib");
use Mojo::IOLoop::ReadWriteProcess qw(process queue);

my $p = process(
  serialize => 1,
  set_pipes => 0,
  args      => qw(12 13 14),
  code      => sub {
    return qw(12 13 14);
  })->start();

$p->wait_stop();

is_deeply $p->return_status, [qw(12 13 14)] or diag explain $p->return_status;


done_testing;
