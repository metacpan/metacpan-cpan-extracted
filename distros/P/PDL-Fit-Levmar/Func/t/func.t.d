use Data::Dumper;
use PDL;
use PDL::Fit::Levmar;
use PDL::Fit::Levmar::Func;
use PDL::NiceSlice;
use PDL::Core ':Internal'; # For topdl()

use strict;
use vars ( '$testno', '$ok_count', '$not_ok_count');

#----------------------------------------#
$ok_count = 0;
$not_ok_count = 0;
sub tapprox {
        my($a,$b) = @_;
        my $c = abs(topdl($a)-topdl($b));
        my $d = max($c);
        $d < 0.0001;
}
sub ok {  
    my ($v, $s) = @_;
    $testno = 0 unless defined $testno;	
    $testno++;
    $s = '' unless defined $s;
    if ( not $v ) {
	print "not ";
	$s = " *** " . $s;
	$not_ok_count++;
    }
    else {
	$ok_count++;
    }
    print "ok - $testno $s\n";   
}
#----------------------------------------#


sub deb  { print STDERR $_[0],"\n" }

sub test1 {
    my $f = levmar_func( FUNC => '
             function testf
             x =  t;
             jacobian testf
             d0 = j;
             d2 = j;
             d3 = j;
             d4 = j;
          ', NOCLEAN => 1);
    
    my $t = sequence(3)+1;
    my $p = sequence(4)+1;
    my $x;
    
    for (my $i=0;$i<1;$i++)  {
	$x = $f->jac_of_t($p,$t);
	$t *= 1.1;
#	deb  $x;
    }
}


sub hatfldb {

my $csrc = '

#include<math.h>
#include<stdio.h>

void hatfldb(double *p, double *x, int m, int n, void *data)
{
register int i;

  x[0]=p[0]-1.0;

  for(i=1; i<m; ++i)
     x[i]=p[i-1]-sqrt(p[i]);
}

void jachatfldb(double *p, double *jac, int m, int n, void *data)
{
register int j=0;

//  fprintf(stderr,"n=%d, m=%d\n", n,m);
  jac[j++]=1.0;
  jac[j++]=0.0;
  jac[j++]=0.0;
  jac[j++]=0.0;

  jac[j++]=1.0;
  jac[j++]=-0.5 / sqrt(p[1]);
  jac[j++]=0.0;
  jac[j++]=0.0;

  jac[j++]=0.0;
  jac[j++]=1.0;
  jac[j++]=-0.5/sqrt(p[2]);
  jac[j++]=0.0;

  jac[j++]=0.0;
  jac[j++]=0.0;
  jac[j++]=1.0;
  jac[j++]=-0.5/sqrt(p[3]);
}
';

my $defst = '
   function mhatfldb
   noloop
   x0 = p0 -1.0;
   x1 = p0 -sqrt(p1);
   x2 = p1 -sqrt(p2);
   x3 = p2 -sqrt(p3);

   jacobian mhatfldb
   noloop
//  fprintf(stderr,"n=%d, m=%d\n", n,m);

    d0[0] = 1.0;
    d1[0] =  0.0;
    d2[0] =  0.0;
    d3[0] = 0.0;

    d0[1] = 1.0;
    d1[1] = -0.5 / sqrt(p1);
    d2[1] = 0.;
    d3[1] = 0.;

    d0[2] = 0.;
    d1[2] = 1.;
    d2[2] = -0.5/sqrt(p2);
    d3[2] = 0.;

    d0[3] = 0.;
    d1[3] = 0.;
    d2[3] = 1.;
    d3[3] = -0.5 / sqrt(p3);

';

  my $p = ones(4) * 0.1;
  my $x = zeroes(4);
  my $t = zeroes($x); # dummy

  my $f1 = levmar_func(CSRC=>$csrc);
  my $f2 = levmar_func(FUNC=>$defst, NOCLEAN=>1);
  
  my $x1 = $f1->jac_of_t1($p,$t);
  my $x2 = $f2->jac_of_t1($p,$t);
  ok(tapprox($x1,$x2), " Fixed bug in def to c jacobian");
#  deb $x1;
#  deb $x2;
}


print "1..1\n";

hatfldb();
#test1();



