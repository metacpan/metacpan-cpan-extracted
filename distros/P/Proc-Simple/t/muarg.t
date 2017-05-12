#!/usr/bin/perl -w

use Proc::Simple;
use Test::More;

plan tests => 4;

$psh  = Proc::Simple->new();

ok($psh->start("sleep", "1"));      # 1
while($psh->poll) { 
    sleep 1; }
ok(!$psh->poll());                  # 2 Must be dead

sub mysleep { sleep(@_); }

ok($psh->start(\&mysleep, 1));      # 3
while($psh->poll) {
    sleep 1; }
ok(!$psh->poll());                  # 4 Must have been terminated
