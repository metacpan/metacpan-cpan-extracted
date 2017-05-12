#!perl
use warnings FATAL => 'all';
use strict;

use Scope::OnExit::Wrap;
use Test::More tests => 3;

ok 1;

my $i = 1;
{  my $foo = on_scope_exit {$i++};
   $i += 2;
   last;
   $i += 2;
}
is $i, 4;
 
my $sum = 0;
foreach my $i (1 .. 9) {
    my $foo = on_scope_exit {$sum += $i};
    next;
}
is $sum, 45;
