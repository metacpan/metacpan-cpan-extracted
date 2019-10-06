#!/usr/bin/perl -wT
use Test::More tests => 24;

use 5.010;
use warnings;
use strict;
use lib qw(./lib/Tangle ./lib/CayleyDickson);

use CayleyDickson;
use Data::Dumper;

use constant DEBUG   => 0;
use constant VERBOSE => 0;
use constant PRECISION => 0.0001;

use constant PACKAGE => 'CayleyDickson';

sub d {
   my %a = @_;
   my @k = keys %a;
   my $d = Data::Dumper->new([@a{@k}],[@k]); $d->Purity(1)->Deepcopy(1); print $d->Dump;
}

sub leq {
   my @a = @{(shift)};
   my @b = @{(shift)};
   my $success = 0;
   if ($success = scalar @a == scalar @b) {
      foreach my $i (0 .. @a - 1) {
         #$success = $a->[$i] == $b->[$i];
	 #printf "compare [%s] with [%s]: ", $a[$i], $b[$i];
         last unless $success = ($a[$i] - $b[$i] < PRECISION);
	 #print "works\n";
      }
   }
   $success;
}

my ($a,$b,$c,$d,$e,$h,$i,$o,$measures,$t);

print "\n###\n### class method tests ...\n###\n\n" if VERBOSE;
foreach my $method (qw(new add subtract multiply divide conjugate inverse norm tensor)) {
   can_ok(PACKAGE, $method);
}


print "\n###\n### new() tests ...\n###\n\n" if VERBOSE;
foreach my $set (
   [1,0,0,0],
   [0,1,],
   [0,0,1,0],
   [0,0,0,1],
   [0,-1,2,0],
   [0,0,0,3],
   [1,4,2,9,0,3,2,5],
) {
   $a = CayleyDickson->new(@$set);
   ok(leq([$a->flat], $set), sprintf "CayleyDickson->new(%16s) = $a", join(',', @$set));
}

print "\n###\n### tensor() tests ...\n###\n\n" if VERBOSE;
foreach my $set (
   [ [sqrt(1/2),sqrt(1/2)], [1,0], [sqrt(1/2),0,sqrt(1/2),0] ]
) {
   $a = CayleyDickson->new(@{$set->[0]});
   $b = CayleyDickson->new(@{$set->[1]});
   $t = CayleyDickson->new(@{$set->[2]});
   ok(leq([$a->tensor($b)->flat], [$t->flat]), sprintf("[%s] × [%s] = [%s]", otss($a, $b, $t)));
}

$a = CayleyDickson->new(1,0);
$b = CayleyDickson->new(0,-1);
$c = CayleyDickson->new(1,3);
$d = CayleyDickson->new(2,5);

print "\n###\n### add() test ...\n###\n\n" if VERBOSE;

ok(leq([($a+$b)->flat],[1,-1]), sprintf("[%s] + [%s] = [%s]", otss($a,$b,($a+$b))));

print "\n###\n### Quaternion tests ...\n###\n\n" if VERBOSE;

$a = CayleyDickson->new(3.4,5.34,-0.28,1.239);
$b = CayleyDickson->new(7.34,-6.17,-6.11,9.84);
$c = CayleyDickson->new(2,4,8,-2);
$d = CayleyDickson->new(1,0,2,-1);

printf "calculated a+b = %s\n", $a+$b if VERBOSE;
ok(j([($a+$b)->flat]) eq j([10.74,-0.83,-6.39,11.079]), sprintf("[%s] + [%s] = [%s]", otss($a,$b,$a+$b)));

printf "calculated a-b = %s\n", $a-$b if VERBOSE;
ok(j([($a-$b)->flat]) eq j([-3.94,11.51,5.83,-8.601]), sprintf("[%s] - [%s] = [%s]", otss($a,$b,$a+$b)));

printf "calculated a*b = %s\n", $a*$b if VERBOSE;
ok(($a*$b - CayleyDickson->new(44.00124,23.03269,-83.01943,8.19526))->norm < PRECISION, sprintf("[%s] * [%s] = [%s]", otss($a,$b,$a*$b)));

printf "calculated c/d = %s\n", $c/$d if VERBOSE;
ok(leq([($c/$d)->flat],[10/3,4/3,0,-4/3]), sprintf("[%s] / [%s] = [%s]", otss($a,$b,$a/$b)));

printf "calculated c/d = %s\n", $c*$d if VERBOSE;
ok(j([($c*$d)->flat],[-16,0,16,4]), sprintf("[%s] + [%s] = [%s]", otss($c,$d,$c*$d)));



#printf("[%s] + [%s] = [%s]\n\n", ots($a,$b,($a+$b)));

$a = CayleyDickson->new(3.4,5.34,-0.28,1.239,6.54,-12,-2.19,1.12);
$b = CayleyDickson->new(7.34,-6.17,-6.11,9.84,-4.5,-6.8,-0.3,8.07);

print "\n###\n### Octonion Tests ...\n###\n\n" if VERBOSE;

print "let a = $a\n";
print "let b = $b\n";

d('a*b' => $a*$b) if DEBUG;
printf "calculated a+b = %s\n", $a*$b if VERBOSE;
ok(leq([($a+$b)->flat],[10.74,-0.83,-6.39,11.079,2.04,-18.8,-2.49,9.19]), sprintf("[%s] + [%s] = [%s]", otss($a,$b,$a+$b)));



sub j    { join ', ', @{$_[0]}    }
sub ots  { join ', ', $_[0]->flat }
sub otss { map ots($_), @_        }


1;

__END__

