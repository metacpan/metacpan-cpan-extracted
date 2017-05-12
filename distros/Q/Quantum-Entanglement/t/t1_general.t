# Simple tests of Quantum::Entanglement

use strict;
use warnings;
use Test;
BEGIN {plan tests => 17, todo =>[]}

use Quantum::Entanglement qw(:DEFAULT :complex :QFT);

{ # entangle + boolean
  my $foo = entangle(1,1);
  my $bar = 0;
  $bar = 1 if $foo;
  ok(1,$bar);
}

{ # entangle + boolean + i
  my $foo = entangle(1*i,1);
  my $bar = 0;
  $bar = 1 if $foo;
  ok(1,$bar);
}

{ # stringification and operators
  my $foo = entangle(1,1,1*i,1);
  my $bar = entangle(1,2,1*i,2);
  { # *
    my $c = $foo * $bar;
    ok("$c",2);
  }
  {
    my $c = $foo + $bar;
    ok("$c",3);
  }  {
    my $c = $bar / $foo;
    ok("$c",2);
  }  {
    my $c = $foo % $bar;
    ok("$c",1);
  }  {
    my $c = $foo - $bar;
    ok("$c",-1);
  }  {
    my $c = $foo << $bar;
    ok("$c",4);
  }  {
    my $c = $foo >> $bar;
    ok("$c",0);
  } {
    my $c = $foo ** $bar;
    ok("$c",1);
  } {
    my $c = $foo x $bar;
    ok("$c",'11');
  }  {
    my $c = $foo . $bar;
    ok("$c",'12');
  }  {
    my $c = $foo & $bar;
    ok("$c",'0');
  }  {
    my $c = $foo | $bar;
    ok("$c",'3');
  }
}
{ # p_op
  my $foo = entangle(1,1,1*i,1);
  my $bar = entangle(1,2,1*i,2);
  {
    my $c = p_op($foo, '>', $bar, sub {'yes'}, sub {'no'});
    ok("$c", 'no');
  } {
    my $c = p_op($foo, '<', $bar, sub {'yes'}, sub {'no'});
    ok("$c", 'yes');
  } {
    my $c = p_op($foo, '<', $bar, sub {$QE::arg1 . $QE::arg2},
		                  sub {$QE::arg2 . $QE::arg1});
    ok("$c", '12');
  }
}
