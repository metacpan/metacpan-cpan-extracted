use strict;
use warnings;
use PDL;
use PDL::NiceSlice;
use Photonic::LE::NP::EpsTensor;

use Test::More;
use lib 't/lib';
use TestUtils;

my $eps=1+2*i;
my $eb=1;
#Check haydock coefficients for simple 1D system
my $B=zeroes(11)->xvals<5; #1D system
my $gl=Photonic::Geometry::FromB->new(B=>$B); #long
my $elo=Photonic::LE::NP::EpsTensor->new(geometry=>$gl, nh=>10, epsilon=>$eps);
my $elv=$elo->epsTensor;
my $elx=pdl('[[1+2i]]');
ok(Cagree($elv, $elx), "1D long epsilon");
is($elo->converged,1, "Converged");

#View 2D from 1D superlattice.
my $Bt=zeroes(1,11)->yvals<5; #2D flat system
my $gt=Photonic::Geometry::FromB->new(B=>$Bt); #trans
my $eto=Photonic::LE::NP::EpsTensor->new(geometry=>$gt, nh=>10, epsilon=>$eps);
my $etv=$eto->epsTensor;
my $etx=(1-$gt->f)*$eps+$gt->f*$eb;
my $etenx=pdl(<<'EOF');
[
[1+2i 0]
[0 1+2i]
]
EOF
ok(Cagree($etv, $etenx), "1D trans epsilon") or diag "got:$etv\nexpected:$etenx";
is($eto->converged,1, "Converged");

# Extend 1D superlattice to 4D (why not?)
my $Bt4=zeroes(11,1,1,1)->xvals<5; #2D flat system
my $gt4=Photonic::Geometry::FromB->new(B=>$Bt4); #trans
my $eto4=Photonic::LE::NP::EpsTensor->new(geometry=>$gt4, nh=>10, epsilon=>$eps);
my $etv4=$eto4->epsTensor;
my $etenx4=pdl(<<'EOF');
[
 [1+2i 0 0 0]
 [0 1+2i 0 0]
 [0 0 1+2i 0]
 [0 0 0 1+2i]
]
EOF
ok(Cagree($etv4, $etenx4), "4D trans epsilon") or diag "got:$etv4\nexpected:$etenx4";
is($eto4->converged,1, "Converged");

my $Nk=6;
my $Bk=zeroes(2*$Nk,2*$Nk);
$Bk=((($Bk->xvals<$Nk) & ($Bk->yvals<$Nk))
   | (($Bk->xvals>=$Nk) & ($Bk->yvals>=$Nk)));
my $gk=Photonic::Geometry::FromB->new(B=>$Bk); #trans
my $eko=Photonic::LE::NP::EpsTensor->new(
    geometry=>$gk, nh=>1000, reorthogonalize=>1, epsilon=>$eps);
my $etva=$eko->epsTensor;
my $etvb=$eko->epsTensor;
my $etvr=zeroes(2,2)->r2C;
$etvr->((0),(0)).= $etvb->((1),(1));
$etvr->((0),(1)).=-$etvb->((1),(0));
$etvr->((1),(0)).=-$etvb->((0),(1));
$etvr->((1),(1)).= $etvb->((0),(0));
my $etvar=($etva->(*1)*$etvr->(:,:,*1))->mv(1,0)->sumover;
ok(Cagree($etvar, pdl(<<'EOF'), 1e-3), "Keller");
[
 [-3+4i     0]
 [    0 -3+4i]
]
EOF

done_testing;
