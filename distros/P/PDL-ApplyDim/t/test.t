use v5.36;
use Test::More;
use PDL;

BEGIN{use_ok('PDL::ApplyDim');}

my $x=sequence(10,10);
ok(($x->apply_to(\&xvals, 1)==$x->yvals)->all, "apply_to code of PDL method");
ok(($x->apply_to("xvals", 1)==$x->yvals)->all, "apply_to of PDL method");
ok(($x->apply_to("PDL::xvals", 1)==$x->yvals)->all, "apply_to fully qualified PDL method");
ok(($x->apply_to("main::xvals", 1)==$x->yvals)->all, "apply_to fully qualified imported method");
ok((apply_to($x, \&xvals, 1)==$x->yvals)->all, "Call apply_to as function");

sub mult_columns($x, $dx, $m){ # multiply each $dx-th column of $x by $m
    $x->slice("0:-1:$dx")*=$m;
}
(my $b=$x->copy)->apply_to(\&mult_columns, 1, 2, 0); # zero every second row of b
ok(($b->slice(":,0:2:-1")==0)->all, "apply_to code of user function");
(my $c=$x->copy)->apply_to("mult_columns", 1, 2, 0); # zero every second row of c
ok(($c->slice(":,0:2:-1")==0)->all, "apply_to name of user function");

ok(($x->apply_not_to(\&xvals, 0)==$x->yvals)->all, "apply_not_to code of PDL method");

my $y=sequence(2,3,4,5);

ok(($y->apply_to(\&xvals,[2,3])==$y->zvals)->all, "apply_to dims code of PDL method");
ok(($y->apply_not_to(\&xvals,[0,1])==$y->zvals)->all, "apply_not_to dims code of PDL method");

my $rotation=pdl [[0,-1],[1,0]];
sub transform($v){$rotation x $v}
my $z=sequence(3,2,4,2);
my $p=$z->apply_to(\&transform,[3,1]); # interchange i0kl with i1kl and change sign of one
my $q=pdl(-$z->slice(",(1)"),$z->slice(",(0)"))->mv(3,1);
ok(($p==$q)->all, "apply_to dims 90 deg. Rotation");
my $r=$z->apply_not_to(\&transform,[0,2]); # interchange ijk0 with ijk1 and change sign of one
my $s=pdl(-$z->slice(",,,(1)"),$z->slice(",,,(0)"));
ok(($r==$s)->all, "apply_not_to dims 90 deg. Rotation");

done_testing;
