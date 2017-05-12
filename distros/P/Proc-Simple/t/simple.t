#!/usr/bin/perl -w

use Proc::Simple;

package EmptySubclass;
@ISA = qw(Proc::Simple);
1;

package Main;
use Test::More;

plan tests => 10;

###
### Simple Test
###

### Shell commands

# Proc::Simple::debug(1);
$psh  = Proc::Simple->new();

ok($psh->start("sleep 1"));         # 1
while($psh->poll) { 
    sleep 1; }
ok(!$psh->poll());                  # 2 Must have been terminated

ok($psh->start("sleep 10"));        # 3
while(!$psh->poll) { 
    sleep 1; }
ok($psh->kill());                   # 4
while($psh->poll) { 
    sleep 1; }
ok(!$psh->poll());                  # 5 Must have been terminated


### Perl subroutines
$psub  = Proc::Simple->new();

ok($psub->start(sub { sleep 1 }));  # 6
while($psub->poll) { 
    sleep 1; }
ok(!$psub->poll());                 # 7 Must have been terminated

ok($psub->start(sub { sleep 10 })); # 8
while(!$psub->poll) { 
    sleep 1; }

ok($psub->kill("SIGTERM"));         # 9
while($psub->poll) { 
    sleep 1; }
ok(!$psub->poll());                 # 10 Must have been terminated

1;
