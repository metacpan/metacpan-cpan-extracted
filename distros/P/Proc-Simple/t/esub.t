#!/usr/bin/perl -w

use Proc::Simple;

package EmptySubclass;
@ISA = qw(Proc::Simple);
1;


package Main;
use Test::More;
plan tests => 3;

###
### Empty Subclass test
###
# Proc::Simple::debug(1);

$psh  = EmptySubclass->new();

ok($psh->start("sleep 10"));        # 1

while(!$psh->poll) { 
    sleep 1; }

ok($psh->kill()) or die;                   # 2

while($psh->poll) { 
    sleep 1; }

ok(1, "the end");

1;
