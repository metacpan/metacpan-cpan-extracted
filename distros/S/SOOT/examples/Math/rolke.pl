use strict;
use warnings;
use SOOT ':all';

my $bm = 0.0;
my $tau = 2.5;
my $mid = 1;
my $m = 100;
my $z = 50;
my $y = 10;
my $x = 5;

# Initialize parameters not used.
my $e = 0.0;
my $em = 0.0;
my $sde=0.0;
my $sdb=0.0;
my $b = 0.0;

my $g = TRolke->new();
$g->SetCL(0.90);
 
my $ul = $g->CalculateInterval($x,$y,$z,$bm,$em,$e,$mid,$sde,$sdb,$tau,$b,$m);
my $ll = $g->GetLowerLimit();
 
print "Assuming MODEL 1\n"; 
print "the Profile Likelihood interval is :\n";
print "[", $ll, ",", $ul, "]\n";

$tau = 2.5;
$mid = 2;
$y = 3;
$x = 10;
$em=0.9;
$sde=0.05;

$g->SetCL(0.95);

$ul = $g->CalculateInterval($x,$y,$z,$bm,$em,$e,$mid,$sde,$sdb,$tau,$b,$m);
$ll = $g->GetLowerLimit();
 
print "Assuming MODEL 2\n"; 
print "the Profile Likelihood interval is :\n";
print "[", $ll, ",", $ul, "]\n";

$mid = 3;
$bm = 5.0;
$x = 10;
$em = 0.9;
$sde=0.05;
$sdb=0.5;

$g->SetCL(0.99);

$ul = $g->CalculateInterval($x,$y,$z,$bm,$em,$e,$mid,$sde,$sdb,$tau,$b,$m);
$ll = $g->GetLowerLimit();

print "Assuming MODEL 3\n"; 
print "the Profile Likelihood interval is :\n";
print "[", $ll, ",", $ul, "]\n";

$tau = 5;
$mid = 4;
$y = 7;
$x = 1;
$e = 0.25;

$g->SetCL(0.68);
$ul = $g->CalculateInterval($x,$y,$z,$bm,$em,$e,$mid,$sde,$sdb,$tau,$b,$m);
$ll = $g->GetLowerLimit();
 
print "Assuming MODEL 4\n"; 
print "the Profile Likelihood interval is :\n";
print "[", $ll, ",", $ul, "]\n";

$mid = 5;
$bm = 0.0;
$x = 1;
$e = 0.65;
$sdb=1.0;

$g->SetCL(0.80);
$ul = $g->CalculateInterval($x,$y,$z,$bm,$em,$e,$mid,$sde,$sdb,$tau,$b,$m);
$ll = $g->GetLowerLimit();

print "Assuming MODEL 5\n"; 
print "the Profile Likelihood interval is :\n";
print "[", $ll, ",", $ul, "]\n";
 
$y = 1;
$mid = 6;
$m = 750;
$z = 500;
$x = 25;
$b = 10.0;

$g->SetCL(0.90);
$ul = $g->CalculateInterval($x,$y,$z,$bm,$em,$e,$mid,$sde,$sdb,$tau,$b,$m);
$ll = $g->GetLowerLimit();
print "Assuming MODEL 6\n"; 
print "the Profile Likelihood interval is :\n";
print "[", $ll, ",", $ul, "]\n";
  

$mid = 7;
$x = 15;
$em = 0.77;
$sde=0.15;
$b = 10.0;

$g->SetCL(0.95);
$ul = $g->CalculateInterval($x,$y,$z,$bm,$em,$e,$mid,$sde,$sdb,$tau,$b,$m);
$ll = $g->GetLowerLimit();

print "Assuming MODEL 7\n"; 
print "the Profile Likelihood interval is :\n";
print "[", $ll, ",", $ul, "]\n";

