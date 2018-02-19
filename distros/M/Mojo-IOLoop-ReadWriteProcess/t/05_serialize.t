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


my $q = queue;
$q->pool->maximum_processes(2);
$q->queue->maximum_processes(800);

my $proc = 10;
my $fired;

my $i = 1;
for (1 .. $proc) {
  $q->add(
    process(
      serialize => 1,
      code      => sub {
        shift;
        return {$_[0] => $_[0]};
      }
    )->args($i));
  $i++;
}

my @output;
$q->once(
  stop => sub {
    $fired++;
    push @output, shift->return_status;
  });
is $q->queue->size,             $proc - $q->pool->maximum_processes;
is $q->pool->size,              2;
is $q->pool->maximum_processes, 2;
$q->consume;
is $fired, $proc;
is $q->queue->size, 0;
is $q->pool->size,  0;

$i = 0;
for ($proc .. 1) {
  is_deeply $output[$i], [{$i => $i}] or diag explain $output[$i];
  $i++;
}

done_testing;
