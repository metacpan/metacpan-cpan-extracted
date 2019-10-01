#!/usr/bin/perl -wT
use Test::More tests => 53;

use 5.010;
use warnings;
use strict;
use lib qw(.);

use Tangle;
use Data::Dumper;

use constant DEBUG   => 1;
use constant VERBOSE => 1;

use constant PACKAGE => 'Tangle';

main->new->go;
sub new { bless {} => shift }

sub d {
   my %a = @_;
   my @k = keys %a;
   my $d = Data::Dumper->new([@a{@k}],[@k]); $d->Purity(1)->Deepcopy(1); print $d->Dump;
}

sub go  {
   my $self = shift;

   print "\n###\n### General class tests ...\n###\n\n";
   can_ok(PACKAGE, qw(new));

   my ($a,$b,$c,$d,$e,$h,$i,$o,$measures);

   $a = Tangle->new(1,2);
   ok($a eq '+1+2i', "(1,2) = $a");
   $b = Tangle->new(3,4);
   ok($b eq '+3+4i', "(3,4) = $b");

   print "\n###\n### Tensor tests ...\n###\n\n";
   $c = $b->tensor($a);
   ok($c eq '+3+4i+6j+8k', "(1,2)⊗ (3,4) = $c");

   $a = Tangle->new(0,1);
   $b = Tangle->new(0,1);
   $c = Tangle->new(1,0);
   $d = $c->tensor($b);
   ok($d eq '+0+1j', "(0,1)⊗ (1,0) = $d");
   $e = $d->tensor($a);
   ok($e eq '+0+1n', "(0,1)⊗ (0,1)⊗ (1,0) = $e");

   $a = Tangle->new(1,0);
   $b = Tangle->new(1,0);
   $c = $b->tensor($a);
   ok($c eq '+1', "(1,0)⊗ (1,0) = |00> = $c");

   $a = Tangle->new(1,0);
   $b = Tangle->new(0,1);
   $c = $b->tensor($a);
   ok($c eq '+0+1i', "(1,0)⊗ (0,1) = |01> = $c");

   $a = Tangle->new(0,1);
   $b = Tangle->new(1,0);
   $c = $b->tensor($a);
   ok($c eq '+0+1j', "(0,1)⊗ (1,0) = |10> = $c");

   $a = Tangle->new(0,1);
   $b = Tangle->new(0,1);
   $c = $b->tensor($a);
   ok($c eq '+0+1k', "(0,1)⊗ (0,1) = |11> = $c");

   $a = Tangle->new(0,1);
   $b = Tangle->new(1,0);
   $c = Tangle->new(1,0);
   $d = $c->tensor($b)->tensor($a);
   ok($d eq '+0+1l', "(0,1)⊗ (1,0)⊗ (1,0) = $d");

   print "\n###\n### gate tests ...\n###\n\n";

   $a = Tangle->new(1,2,3,4);
   $a->b->swap;
   ok($a eq '+1+2i+4j+3k', "SWAP-B(1,2,3,4) = (1,2,4,3)");

   foreach my $set (
      ['cnot |00> = |00> = [1,0,0,0]' => [1,0], [1,0],[1,0,0,0],'+1'   ],
      ['cnot |01> = |01> = [0,1,0,0]' => [1,0], [0,1],[0,1,0,0],'+0+1i'],
      ['cnot |10> = |11> = [0,0,0,1]' => [0,1], [1,0],[0,0,0,1],'+0+1k'],
      ['cnot |11> = |10> = [0,0,1,0]' => [0,1], [0,1],[0,0,1,0],'+0+1j'],
   ) {
      my $label = @$set[0];
      my $c = Tangle->new(@{$set->[1]});
      my $t = Tangle->new(@{$set->[2]});
      my $r = Tangle->new(@{$set->[3]});
      $c->cnot($t);
      ok($t eq $set->[4],$label);
   }

   $a = Tangle->new(1/sqrt(2),1/sqrt(2));
   $b = Tangle->new(1/2,sqrt(3)/2);
   $c = Tangle->new(-1,0);
   $d = Tangle->new(1/sqrt(2),-1/sqrt(2));
   ok($a->a == $a->b, "(√½,√½) = $a");
   #skip($b, "(1/2,√3/2) = $b");
   ok($c eq '-1', "(-1,0) = $c");
   ok($d->a == - $d->b, "(√½,-√½) = $d");

   print "\n###\n### measurements ...\n###\n\n";
   $a = Tangle->new(1/sqrt(2),1/sqrt(2));
   $measures = $a->measures(10000);
   ok((abs($measures->{0}-.5)<.1 and abs($measures->{1}-.5) < .1), "50%/50% measure 0/1 on 10,000 runs of (√½,√½)");

   $b = Tangle->new(1,0);
   $measures = $b->measures(10000);
   ok($measures->{0} eq 1, "100% measure 0 on 10,000 runs of (1,0)");

   $c = Tangle->new(0,1);
   $measures = $c->measures(10000);
   ok($measures->{1} eq 1, "100% measure 1 on 10,000 runs of (0,1)");

   # 50/50 x 50/50 is 1/4,1/4,1/4,1/4
   $a = Tangle->new(1/sqrt(2),1/sqrt(2));
   $b = Tangle->new(1/sqrt(2),1/sqrt(2));
   $h = $a->tensor($b);
   $measures = $h->measures(10000);
   ok((abs($measures->{0}-.25)<.1 and abs($measures->{1}-.25) < .1 and abs($measures->{2}-.25)<.1 and abs($measures->{3}-.25)), "(1/2,1/2,1/2,1/2) has equal 25% probabilities");

   print "\n###\n### Hadamard tests ...\n###\n\n";

   $a = Tangle->new(1/sqrt(2),sqrt(3)/2);
   $b = Tangle->new(sqrt(3)/2,1/sqrt(2));
   $a->swap;
   ok(($a->a eq $b->a and $a->b eq $b->b), 'SWAP(√½,√3/2) = (√3/2,√½)');

   $a = Tangle->new(1,0);
   $a->hadamard;
   ok(abs($a->a-1/sqrt(2) < 0.0000001 and abs($a->b-1/sqrt(2)< 0.0000001)),'Hadamard(|0>) = |+>');

   $b = Tangle->new(0,1);
   $b->hadamard;
   ok(abs($b->a-1/sqrt(2) < 0.0000001 and abs($b->b+1/sqrt(2)< 0.0000001)),'Hadamard(|1>) = |->');

   $a = Tangle->new(1,0);
   $a->hadamard;
   $a->hadamard;
   ok((int $a->a == 1 and int $a->b == 0), "Hadamard(Hadamard(1,0)) = (1,0)");

   $a = Tangle->new(1,1);
   $a->hadamard;
   $a->hadamard;
   ok((int $a->a == 1 and int $a->b == 1), "Hadamard(Hadamard(1,1)) = (1,1)");

   ###################################################
   $a = Tangle->new(1,0);
   $a->x_gate;
   $a->hadamard;
   ok(abs(int $a->a-1/sqrt(2) < 0.0000001 and abs(int $a->b+1/sqrt(2)< 0.0000001)),'Hadamard(XGate(1,0) = (√½,√½)');

   $a = Tangle->new(0,1);
   $a->x_gate;
   $a->hadamard;
   ok(abs(int $a->a-1/sqrt(2) < 0.0000001 and abs(int $a->b-1/sqrt(2)< 0.0000001)),'Hadamard(XGate(0,1) = (√½,-√½)');

   $a = Tangle->new(1/sqrt(2),1/sqrt(2));
   $a->x_gate;
   $a->hadamard;
   ok($a eq '+1', 'Hadamard(XGate(√½,√½)) = (1,0)');

   $a = Tangle->new(-1/sqrt(2),1/sqrt(2));
   $a->x_gate;
   $a->hadamard;
   ok($a eq '+0+1i', 'Hadamard(XGate(-√½,√½)) = (1,0)');

   $a = Tangle->new(1/sqrt(2),-1/sqrt(2));
   $a->x_gate;
   $a->hadamard;
   ok($a eq '+0-1i','Hadamard(XGate(√½,-√½)) = |+>');

   $a = Tangle->new(0,-1);
   $a->x_gate;
   $a->hadamard;
   ok(abs(int $a->a+1/sqrt(2) < 0.0000001 and abs(int $a->b+1/sqrt(2)< 0.0000001)),'Hadamard(XGate(0,1) = (-√½,-√½)');

   $a = Tangle->new(-1,0);
   $a->x_gate;
   $a->hadamard;
   ok(abs(int $a->a+1/sqrt(2) < 0.0000001 and abs(int $a->b-1/sqrt(2)< 0.0000001)),'Hadamard(XGate(-1,0)) = (-√½,√½)');

   $a = Tangle->new(-1/sqrt(2),-1/sqrt(2));
   $a->x_gate;
   $a->hadamard;
   ok($a eq '-1','Hadamard(XGate(-√½,-√½)) = (0,-1)');

   $a = Tangle->new(1,0);
   print "\n###\n### 16 step walk about the complex unit circle ...\n### X(H(X(H(X(H(...))))) = (...)\n###\n\n";
   ok($a eq '+1', "Step 0: Starting value (1,0) = $a");
   $a->x_gate;
   ok($a eq '+0+1i', "Step 1: X(1,0) = (0,1) = $a");
   $a->hadamard;
   ok($a eq '+0.707106781186548-0.707106781186548i', "Step 2: H(0,1) = (√½,-√½) = $a");
   $a->x_gate;
   ok($a eq '-0.707106781186548+0.707106781186548i', "Step 3: X(√½,-√½) = (-√½,√½)) = $a");
   $a->hadamard;
   ok($a eq '+0-1i', "Step 4: H(-√½,√½) = (0,-1) = $a");
   $a->x_gate;
   ok($a eq '-1', "Step 5: X(0,-1) = (-1,0) = $a");
   $a->hadamard;
   ok($a eq '-0.707106781186547-0.707106781186547i', "Step 6: H(-1,0) = (-√½,-√½) = $a");
   $a->x_gate;
   ok($a eq '-0.707106781186548-0.707106781186548i', "Step 7: X(-√½,-√½) = (-√½,-√½) = $a");
   $a->hadamard;
   ok($a eq '-1', "Step 8: H(-√½,-√½) = (-1,0) = $a");
   $a->x_gate;
   ok($a eq '+0-1i', "Step 9: X(-1,) = (0,-1) = $a");
   $a->hadamard;
   ok($a eq '-0.707106781186547+0.707106781186547i', "Step 10: H(0,-1) = (-√½,√½) = $a");
   $a->x_gate;
   ok($a eq '+0.707106781186548-0.707106781186548i', "Step 11: X(-√½,√½) = (√½,-√½) = $a");
   $a->hadamard;
   ok($a eq '+0+1i', "Step 12: H(√½,-√½) = (0,1) = $a");
   $a->x_gate;
   ok($a eq '+1', "Step 13: X(0,1) = (1,0) = $a");
   $a->hadamard;
   ok($a eq '+0.707106781186547+0.707106781186547i', "Step 14: H(1,0) = (√½,√½) = $a");
   $a->x_gate;
   ok($a eq '+0.707106781186548+0.707106781186548i', "Step 15: X(√½,√½) = (√½,-√½) = $a");
   $a->hadamard;
   ok($a eq '+1', "Step 16: H(√½,√½) = (1,0) = $a");

   print "\n###\n### 4 Black box gate actions: constant 1/0, identity and negate ...\n###\n\n";
   $i = Tangle->new(1,0);
   $o = Tangle->new(1,0);
   ok(($i eq '+1'    and $o eq '+1'), "Constant-0 |00> = |00>");

   $i = Tangle->new(0,1);
   $o = Tangle->new(1,0);
   ok(($i eq '+0+1i' and $o eq '+1'), "Constant-0 |10> = |00>");

   $i = Tangle->new(1,0);
   $o = Tangle->new(1,0);
   $o->x_gate;
   ok(($i eq '+1' and $o eq '+0+1i'), "Constant-1 |00> = |01>");

   $i = Tangle->new(0,1);
   $o = Tangle->new(1,0);
   ok(($i eq '+0+1i' and $o eq '+1'), "Constant-1 |10> = |11>");

   $i = Tangle->new(1,0);
   $o = Tangle->new(1,0);
   $i->cnot($o);
   ok(($i eq '+1'), "Identity |00> = |00>");

   $i = Tangle->new(0,1);
   $o = Tangle->new(1,0);
   $i->cnot($o);
   ok(($i eq '+0+1k'), "Identity |11> = |10>");

   $i = Tangle->new(1,0);
   $o = Tangle->new(1,0);
   $i->cnot($o);
   $i->x_gate;
   ok(($i eq '+0+1i'), "Negate |00> = |01>");

   $i = Tangle->new(0,1);
   $o = Tangle->new(1,0);
   $i->cnot($o);
   $i->x_gate;
   ok(($i eq '+0+1j'), "Negate |11> = |11>");
}

sub get_set {
   my $self      = shift;
   my $attribute = ((caller(1))[3] =~ /::(\w+)$/)[0];
   $self->{$attribute} = shift if scalar @_;
   return $self->{$attribute};
}

1;

__END__

