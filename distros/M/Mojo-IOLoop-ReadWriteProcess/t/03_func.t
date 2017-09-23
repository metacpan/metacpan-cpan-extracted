#!/usr/bin/perl

use warnings;
use strict;
use Test::More;
use POSIX;
use FindBin;
use Mojo::File qw(tempfile path);
use lib ("$FindBin::Bin/lib", "../lib", "lib");
use Mojo::IOLoop::ReadWriteProcess qw(process);

subtest _new_err => sub {
  my $p = process();
  $p->_new_err("Test");
  is $p->error->last->to_string, "Test";
  $p->_new_err("Test", "Test");
  ok !$p->error->last->to_string;
};

subtest _fork => sub {
  use Mojo::Util 'monkey_patch';
  monkey_patch 'IO::Pipe', new => sub { undef };
  my $p = process(sub { exit 0 })->start->wait_stop;
  is $p->error->size, 7;

  like $p->error->last->to_string, qr/Failed creating internal return/
    or diag explain $p->error->last;
  like $p->error->first->to_string, qr/Failed creating input pipe/
    or diag explain $p->error->first;
  like @{$p->error}[2]->to_string, qr/Failed creating output error pipe/
    or diag explain @{$p->error}[2];
  like @{$p->error}[3]->to_string, qr/Failed creating Channel input pipe/
    or diag explain @{$p->error}[3];
  like @{$p->error}[4]->to_string, qr/Failed creating Channel output pipe/
    or diag explain @{$p->error}[4];
  like @{$p->error}[5]->to_string, qr/Failed creating internal error pipe/
    or diag explain @{$p->error}[5];
  like @{$p->error}[6]->to_string, qr/Failed creating internal return pipe/
    or diag explain @{$p->error}[6];
};

done_testing;
