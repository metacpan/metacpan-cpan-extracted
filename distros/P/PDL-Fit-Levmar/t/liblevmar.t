#####
# These tests are taken from the demos in the liblevmar distribution.
# The tests are mathematically exactly the same as those
# in liblevmar.

use Data::Dumper;
use PDL;
use PDL::Fit::Levmar;
use PDL::Fit::Levmar::Func;
use PDL::NiceSlice;
use PDL::Core ':Internal'; # For topdl()

use strict;
use vars ( '$testno', '$ok_count', '$not_ok_count', '@g',
            '$Type' );

#  @g is global options to levmar

@g = (  );

$ok_count = 0;
$not_ok_count = 0;

sub tapprox {
        my($a,$b) = @_;
        $a = topdl($a);
        $b = topdl($b);  
        my $c = abs($a -$b);
        my $d = max($c);
#	print "# tapprox: $a, $b : max diff ";
#        printf "%e\n",$d;
        $d < 0.0001;
}

sub tapprox_cruder {
        my($a,$b) = @_;
        $a = topdl($a);
        $b = topdl($b);  
        my $c = abs($a -$b);        
        my $d = max($c);
#	print "# tapprox_cruder: $a, $b : max diff ";
#        printf "%e\n",$d;
        $d < 0.0005;
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

sub check_type {
    my (@d) = @_;
    my $i=0;
    foreach ( @d )  {
	die "$i: not $Type" unless $Type == $_->type;
	$i++;
    }   
}


sub deb  { print STDERR $_[0],"\n" }


#-------------------------------------------------
# Rosebrock
sub rosenbrock {


    my $st = '
#define ROSD 105.0
 function mros
     x =((1.0-p0)*(1.0-p0) + ROSD*(p1-p0*p0)*(p1-p0*p0));

 jacobian jacmros
    d1=(-2 + 2*p0-4*ROSD*(p1-p0*p0)*p0);
    d2=(2*ROSD*(p1-p0*p0));

';
    my $ROSD = 105.0;

    my $rderiv = sub {
       my ($p,$d,$t) = @_;
       my ($p0,$p1) = list $p;
       $d((0)) .= (-2 + 2 * $p0-4 *$ROSD*($p1-$p0*$p0)*$p0);
       $d((1)) .= (2*$ROSD*($p1-$p0*$p0));
   };
    my $rf = sub {
       my ($p,$x,$t) = @_;
       my ($p0,$p1) = list $p;
       $x .= ( (1.0-$p0)**2 +  $ROSD*($p1-$p0*$p0)**2 );
   };

    my $p =  pdl  $Type, [-1.2, 1];
    my $x = pdl $Type, [0,0];
    my $t = pdl $Type, [0,0];
    
    my @opts = ( MAXITS => 5000 );
    my $h1 = levmar($p,$x, FUNC => $st, @opts, @g );
    check_type($h1->{INFO});
    my $h2 = levmar($p,$x, CSRC => 't/ros.c' , @opts,@g );
    check_type($h2->{INFO});
    ok(levmar_report($h1) eq levmar_report($h2), "Rosenbrock  csrc == def");
    my $h3 = levmar($p,$x, FUNC => $rf, JFUNC => $rderiv, @opts, DERIVATIVE => 'analytic',@g);
    check_type($h3->{INFO});
    ok ( tapprox_cruder($h2->{P},$h3->{P}), "Rosenbrock  perl sub == def");


} 

#-------------------------------------------------
# modified Rosenbrock problem
sub modified_rosenbrock {

my $csrc = '
#define MODROSLAM 1E02
/* Modified Rosenbrock problem, global minimum at (1, 1) */
void modros(FLOAT *p, FLOAT *x, int m, int n, void *data)
{
register int i;

  for(i=0; i<n; i+=3){
    x[i]=10*(p[1]-p[0]*p[0]);
	  x[i+1]=1.0-p[0];
	  x[i+2]=MODROSLAM;
  }
}
void jacmodros(FLOAT *p, FLOAT *jac, int m, int n, void *data)
{
register int i, j;

  for(i=j=0; i<n; i+=3){
          jac[j++]=-20.0*p[0];
	  jac[j++]=10.0;

	  jac[j++]=-1.0;
	  jac[j++]=0.0;

	  jac[j++]=0.0;
	  jac[j++]=0.0;
  }
}
';

my  $MODROSLAM  = 1e2;
my $defst = "

    function modros
    x0 = 10 * (p1 -p0*p0);
    x1 = 1.0 - p0;
    x2 = $MODROSLAM;
    loop

    jacobian jacmodros
    d0[0] = -20 * p0;
    d1[0] = 10;
    d0[1] = -1;
    d1[1] = 0;
    d0[2] = 0;
    d1[2] = 0;
    loop
    
";

my $defst2 = "

    function modros
    noloop
    x0 = 10 * (p1 -p0*p0);
    x1 = 1.0 - p0;
    x2 = $MODROSLAM;

    jacobian jacmodros
    noloop
    d0[0] = -20 * p0;
    d1[0] = 10;
    d0[1] = -1;
    d1[1] = 0;
    d0[2] = 0;
    d1[2] = 0;
    
";

    my $p = pdl $Type, [-1.2, 1];
    my $x = pdl $Type, [0,0,0];

    my $maxits = 2000;
    my $h1 = levmar($p,$x, CSRC => $csrc, MAXITS => $maxits, @g);
    my $h2 = levmar($p,$x, CSRC => $csrc, MAXITS => $maxits, DERIVATIVE => 'numeric',@g);
    my $h3 = levmar($p,$x, FUNC => $defst, MAXITS => $maxits, DERIVATIVE => 'numeric',@g);
    my $h4 = levmar($p,$x, FUNC => $defst2, MAXITS => $maxits ,@g);
    check_type($h1->{INFO});
    check_type($h2->{INFO});
    check_type($h3->{INFO});
    check_type($h4->{INFO});

    if ( $Type != float ) {  # float and double differ by maybe %1 
     my $fhand = $h3->{FUNC};
     ok(tapprox($h1->{P},$h2->{P}), "Modified Rosenbrock  analytic == numeric");
     ok(tapprox($h2->{P},$h3->{P}), "Modified Rosenbrock  csrc == def, numeric ");
     ok(tapprox($h3->{P},$h4->{P}), "Modified Rosenbrock  def, analytic ");
     for(my $i=0;$i<1;$i++) {
#      $h3 = levmar($p3,$x, FUNC => $fhand, MAXITS => $maxits, DERIVATIVE => 'numeric',@g);
      $h4 = levmar($p,$x, FUNC => $fhand, MAXITS => $maxits ,@g);
      $h3 = levmar($p,$x, FUNC => $defst, MAXITS => $maxits, DERIVATIVE => 'numeric',@g);
      $h4 = levmar($p,$x, FUNC => $defst2, MAXITS => $maxits ,@g);
      ok(tapprox($h3->{P},$h4->{P}), "Modified Rosenbrock  def,  analytic, noloop syntax");
     }
    }
}

#-------------------------------------------------
# Powell's Problem
sub powell {

    my $csrc = '
/* Powell\'s function, minimum at (0, 0) */
void powell(FLOAT *p, FLOAT *x, int m, int n, void *data)
{
register int i;

  for(i=0; i<n; i+=2){
    x[i]=p[0];
    x[i+1]=10.0*p[0]/(p[0]+0.1) + 2*p[1]*p[1];
  }
}

void jacpowell(FLOAT *p, FLOAT *jac, int m, int n, void *data)
{
register int i, j;

  for(i=j=0; i<n; i+=2){
    jac[j++]=1.0;
    jac[j++]=0.0;

    jac[j++]=1.0/((p[0]+0.1)*(p[0]+0.1));
    jac[j++]=4.0*p[1];
  }
}

';

my $defst = '
    function powell
    noloop
    x0 = p0;
    x1 = 10.0 * p0/(p0+0.1) +2*p1*p1;

    jacobian jacpowell
    noloop
    d0[0] = 1.0;
    d1[0] = 0.0;
    d0[1] = 1.0/((p0+.1)*(p0+.1));
    d1[1] = 4.0*p1;
 
';
 
   my $pf = sub {
       my ($p,$x,$t) = @_;
       my ($p0,$p1) = list $p;
       
   };

   my $pd = sub {
       my ($p,$d,$t) = @_;
       my ($p0,$p1) = list $p;
   };
   my $p = pdl $Type, [ 3, 1];
   my $x = pdl $Type, [ 0, 0];

# Because this function results in some overflow values (see levmar_report),
# There is a difference between letting cc cast ints to FLOATs above
# eg, 4 --> 4.0
# When I put decimal points in the defst, i get different results than without.

    my @opts = ( MAXITS => 1000, DERIVATIVE => 'numeric' );
    my $h0 = levmar($p,$x, CSRC => $csrc, @opts,@g);
    my $h1 = levmar($p,$x, FUNC => $defst, @opts ,@g);
    check_type($h0->{INFO});
    check_type($h1->{INFO});
    ok(levmar_report($h0) eq levmar_report($h1), "Powell  csrc == def"); 
}

#-------------------------------------------------
# Boggs Tolle problem 3
sub boggs_tolle_3 {

    my $csrc =  '
/* Boggs - Tolle problem 3 (linearly constrained),*/
/* minimum at (-0.76744, 0.25581, 0.62791, -0.11628, 0.25581) */
// constr1: p[0] + 3*p[1] = 0;
// constr2: p[2] + p[3] - 2*p[4] = 0;
// constr3: p[1] - p[4] = 0;

void bt3(FLOAT *p, FLOAT *x, int m, int n, void *data)
{
register int i;
FLOAT t1, t2, t3, t4;

  t1=p[0]-p[1];
  t2=p[1]+p[2]-2.0;
  t3=p[3]-1.0;
  t4=p[4]-1.0;

  for(i=0; i<n; ++i)
    x[i]=t1*t1 + t2*t2 + t3*t3 + t4*t4;
}

void jacbt3(FLOAT *p, FLOAT *jac, int m, int n, void *data)
{
register int i, j;
FLOAT t1, t2, t3, t4;

  t1=p[0]-p[1];
  t2=p[1]+p[2]-2.0;
  t3=p[3]-1.0;
  t4=p[4]-1.0;

  for(i=j=0; i<n; ++i){
    jac[j++]=2.0*t1;
    jac[j++]=2.0*(t2-t1);
    jac[j++]=2.0*t2;
    jac[j++]=2.0*t3;
    jac[j++]=2.0*t4;
  }
}

';

   my $pf = sub {
       my ($p,$x,$t) = @_;
       my ($p0,$p1,$p2,$p3,$p4) = list $p;
       my $t1=$p0-$p1;
       my $t2=$p1+$p2-2.0;
       my $t3=$p3-1.0;
       my $t4=$p4-1.0;
       $x .= $t1*$t1 + $t2*$t2 + $t3*$t3 + $t4*$t4;       
   };

   my $pd = sub {
       my ($p,$d,$t) = @_;
       my ($p0,$p1,$p2,$p3,$p4) = list $p;
       my $t1=$p0-$p1;
       my $t2=$p1+$p2-2.0;
       my $t3=$p3-1.0;
       my $t4=$p4-1.0;
       $d((0)) .= 2 * $t1;
       $d((1)) .= 2 * ($t2-$t1);
       $d((2)) .= 2 * $t2;
       $d((3)) .= 2 * $t3;
       $d((4)) .= 2 * $t4;
   };


my $defst = '

  function bt3
  noloop
  FLOAT q1,q2,q3,q4;

  q1=p0-p1;
  q2=p1+p2-2.0;
  q3=p3-1.0;
  q4=p4-1.0;

  jacobian bt3
  FLOAT q1,q2,q3,q4;

  q1=p0-p1;
  q2=p1+p2-2.0;
  q3=p3-1.0;
  q4=p4-1.0;

  loop
  d0 = 2.0*q1;
  d1 = 2.0*(q2-q1);
  d2 = 2.0*q2;
  d3 = 2.0*q3;
  d4 = 2.0*q4;

';
  

   my $x = zeroes($Type,5);
   my $p = ones($Type, 5);
   $p *= 2;
# contraint: A x p = b
   my $A = pdl $Type, [
              [ 1, 3, 0, 0,  0],
              [ 0, 0, 1, 1, -2],
              [ 0, 1, 0, 0, -1]
           ];

   my $b = zeroes($Type, 3);

   my $correct_minimum =  pdl $Type, [-0.76744, 0.25581, 0.62791, -0.11628, 0.25581];

   my @opts = ( MAXITS => 1000 ,@g);

   my $h1 = levmar($p,$x, CSRC => $csrc, A => $A, B => $b , @opts );
   check_type($h1->{INFO});   
   ok(tapprox_cruder($h1->{P},$correct_minimum), "Boggs Tolle " .
          $h1->{P} . "   " .  $correct_minimum );

   
   my $p3 = $p->copy;
   my $h3 = levmar($p3,$x, FUNC => $h1->{FUNC} , A => $A, B => 7, @opts, DERIVATIVE => 'numeric' );
   ok(tapprox($h3->{RET} , -1), "Boggs Tolle, catch error in inputs");


#   my $p4 = $p->copy;
#   my $h4 = levmar($p4,$x, FUNC => $defst, A => $A, B => $b, @opts );
#   ok(tapprox($h4->{P},$correct_minimum), "Boggs Tolle, def  # TODO");

#   my $p5 = $p->copy;
#   my $h5 = levmar($p5,$x, FUNC => $pf, JFUNC=> $pd,
#                       A => $A, B => $b, @opts, DERIVATIVE =>'numeric' );
#   ok(tapprox($h5->{P},$correct_minimum), "Boggs Tolle perl sub, numeric");
   
#   my $p6 = $p->copy;
#   my $h6 = levmar($p6,$x, FUNC => $pf, JFUNC=> $pd,
#                       A => $A, B => $b, @opts );
#   ok(tapprox($h6->{P},$correct_minimum), "Boggs Tolle perl sub, analytic");

   
#   my $p2 = $p->copy;
#   my $h2 = levmar($p2,$x, FUNC => $h1->{FUNC}, A => $A, B => $b, @opts, DERIVATIVE => 'numeric' );
#   ok(tapprox($h2->{P},$correct_minimum), "Boggs Tolle, numeric");
 
}


sub hock_schittkowski {

   my $csrc = '
    
    void mod1hs52(FLOAT *p, FLOAT *x, int m, int n, void *data)
{
  x[0]=4.0*p[0]-p[1];
  x[1]=p[1]+p[2]-2.0;
  x[2]=p[3]-1.0;
  x[3]=p[4]-1.0;
}

void jacmod1hs52(FLOAT *p, FLOAT *jac, int m, int n, void *data)
{
register int j=0;

  jac[j++]=4.0;
  jac[j++]=-1.0;
  jac[j++]=0.0;
  jac[j++]=0.0;
  jac[j++]=0.0;

  jac[j++]=0.0;
  jac[j++]=1.0;
  jac[j++]=1.0;
  jac[j++]=0.0;
  jac[j++]=0.0;

  jac[j++]=0.0;
  jac[j++]=0.0;
  jac[j++]=0.0;
  jac[j++]=1.0;
  jac[j++]=0.0;

  jac[j++]=0.0;
  jac[j++]=0.0;
  jac[j++]=0.0;
  jac[j++]=0.0;
  jac[j++]=1.0;
}
';
    
    my $p = pdl $Type, [ 2, 2, 2, 2, 2];
    my $x = pdl $Type, [ 0, 0, 0, 0];
    my $A = pdl $Type, [
        [ 1, 3, 0, 0,  0],
        [ 0, 0, 1, 1, -2],
        [ 0, 1, 0, 0, -1]
    ];
    my $b = pdl $Type, [ 0, 0, 0 ];

    my $dmax = PDL::Fit::Levmar::get_dbl_max();    
    my $lb = pdl $Type, [-0.09, 0.0, -$dmax, -0.2, 0.0];
    
    my $ub = pdl $Type, [ $dmax, 0.3, ,0.25, 0.3, 0.3 ];
    my $weights = pdl $Type, [2000.0, 2000.0, 2000.0, 2000.0, 2000.0];
    my @opts = ( MAXITS => 5000 );
    my $h = levmar($p,$x, $csrc, A => $A, B => $b , WGHTS => $weights, UB => $ub, LB => $lb,  @opts );
#    print levmar_report($h);
#    exit(0);
}

sub hock_schittkowski_mod2_52 {
 #   Hock - Schittkowski modified #2 problem 52 

  my $csrc = '
void mod2hs52(double *p, double *x, int m, int n, void *data)
{
  x[0]=4.0*p[0]-p[1];
  x[1]=p[1]+p[2]-2.0;
  x[2]=p[3]-1.0;
  x[3]=p[4]-1.0;
  x[4]=p[0]-0.5;
}

void jacmod2hs52(double *p, double *jac, int m, int n, void *data)
{
register int j=0;

  jac[j++]=4.0;
  jac[j++]=-1.0;
  jac[j++]=0.0;
  jac[j++]=0.0;
  jac[j++]=0.0;

  jac[j++]=0.0;
  jac[j++]=1.0;
  jac[j++]=1.0;
  jac[j++]=0.0;
  jac[j++]=0.0;

  jac[j++]=0.0;
  jac[j++]=0.0;
  jac[j++]=0.0;
  jac[j++]=1.0;
  jac[j++]=0.0;

  jac[j++]=0.0;
  jac[j++]=0.0;
  jac[j++]=0.0;
  jac[j++]=0.0;
  jac[j++]=1.0;

  jac[j++]=1.0;
  jac[j++]=0.0;
  jac[j++]=0.0;
  jac[j++]=0.0;
  jac[j++]=0.0;
}
     ';
    
    my $p = pdl $Type, [ 2, 2, 2, 2, 2];
    my $x = pdl $Type, [ 0, 0, 0, 0, 0];

    my $C = pdl $Type, [
        [ 1, 3, 0, 0,  0],
        [ 0, 0, 1, 1, -2],
        [ 0, -1, 0, 0, 1]
    ];
    my $d = pdl $Type, [ -1, -2,  -7 ];

    my @opts = ( MAXITS => 1000 );
    my $h = levmar($p,$x, $csrc, C => $C, D => $d ,  @opts );
    ok(tapprox($h->{P},[0.5, 2, -1.301625e-12, 1, 1 ]), "Hock - Schittkowski modified #2 problem 52 ");
    #    print levmar_report($h);
}

sub hock_schittkowski_mod_76 {
#  /* Hock - Schittkowski modified problem 76 */

 my $csrc = '

#include <math.h>
#include <stdio.h>
void modhs76(double *p, double *x, int m, int n, void *data)
{
  x[0]=p[0];
  x[1]=sqrt(0.5)*p[1];
  x[2]=p[2];
  x[3]=sqrt(0.5)*p[3];
}

void jacmodhs76(double *p, double *jac, int m, int n, void *data)
{
register int j=0;

  jac[j++]=1.0;
  jac[j++]=0.0;
  jac[j++]=0.0;
  jac[j++]=0.0;

  jac[j++]=0.0;
  jac[j++]=sqrt(0.5);
  jac[j++]=0.0;
  jac[j++]=0.0;

  jac[j++]=0.0;
  jac[j++]=0.0;
  jac[j++]=1.0;
  jac[j++]=0.0;

  jac[j++]=0.0;
  jac[j++]=0.0;
  jac[j++]=0.0;
  jac[j++]=sqrt(0.5);
}
';
    
    my $p = pdl $Type, [ 0.5, 0.5, 0.5, 0.5 ];
    my $x = pdl $Type, [ 0, 0, 0, 0 ];
    my $A = pdl $Type, [
        [ 0, 1, 4, 0 ]
    ];
    my $b = pdl $Type, [ 1.5 ];
    my $C = pdl $Type, [
        [ -1, -2, -1, -1],
        [ -3, -1, -2,  1]
    ];
    my $d = pdl $Type, [ -5, -0.4];
    my $lb = pdl $Type, [ 0, 0, 0, 0];
    my @opts = ( MAXITS => 1000 );
    my $h = levmar($p,$x, $csrc, C => $C, D => $d , A => $A, B => $b,
                LB => $lb,  @opts );
    print levmar_report($h);
}


#-------------------------------------------------
# Hatfld b


sub hatfldb {

my $csrc = '

#include<math.h>
#include<stdio.h>

void hatfldb(FLOAT *p, FLOAT *x, int m, int n, void *data)
{
register int i;

  x[0]=p[0]-1.0;

  for(i=1; i<m; ++i)
     x[i]=p[i-1]-sqrt(p[i]);
}

void jachatfldb(FLOAT *p, FLOAT *jac, int m, int n, void *data)
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

   my $pf = sub {
       my ($p,$x,$t) = @_;
       my ($p0,$p1,$p2,$p3) = list $p;
       $x(0) .= $p(0) - 1;
       for(my $i=1; $i<$p->nelem; ++$i) {
          $x($i) .= $p($i-1)-sqrt( $p($i) );
       }
   };

   my $pd = sub {
       my ($p,$d,$t) = @_;
       my ($p0,$p1,$p2,$p3) = list $p;
       $d .= 0;
       $d(0,0) .= 1.0;
       $d(0,1) .= 1.0;
       $d(1,1) .= -.5 / sqrt($p((1)) );
       $d(1,2) .= 1.;
       $d(2,2) .= -.5 / sqrt($p((2)) );
       $d(2,3) .= 1;
       $d(3,3) .= -.5 / sqrt($p((3)) );
   };

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

  my $p = ones($Type, 4);
  $p *=  0.1;
  my $x = zeroes($Type, 4);

  my $lb = zeroes($Type, 4);
  my $dmax = PDL::Fit::Levmar::get_dbl_max();
  my $ub = ones($Type, 4);  
  $ub *=  $dmax;  
  $ub(1) .= 0.8;

  my $correct_minimum = pdl $Type, [0.947214, 0.8, 0.64, 0.4096];
   
  my @opts = ( MAXITS => 5000 ,@g);
  my $h;

  $h = levmar($p,$x, CSRC => $csrc, UB => $ub, LB => $lb, @opts, DERIVATIVE => 'analytic');
  check_type($h->{INFO});   
  ok(tapprox($h->{P},$correct_minimum), "Hatfld b, csrc, analytic");

  $h = levmar($p,$x, FUNC => $defst, UB => $ub, LB => $lb, @opts, DERIVATIVE => 'numeric');
  ok(tapprox($h->{P},$correct_minimum), "Hatfld b, def, numeric");

  $h = levmar($p,$x, FUNC => $defst, UB => $ub, LB => $lb, @opts );
  ok(tapprox($h->{P},$correct_minimum), "Hatfld b, def, analytic");

  $h = levmar($p,$x, FUNC => $pf, JFUNC => $pd , UB => $ub, LB => $lb, @opts,
                      DERIVATIVE => 'numeric' );
  ok(tapprox($h->{P},$correct_minimum), "Hatfld b, perl sub , numeric ");


  $h = levmar($p,$x, FUNC => $pf, JFUNC => $pd , UB => $ub, LB => $lb, @opts,
                      DERIVATIVE => 'analytic' );
  ok(tapprox($h->{P},$correct_minimum), "Hatfld b, perl sub , analytic");

  my $p1 = $p->copy;
  my $p2 = $p->copy;
  $p2 *= 1.3;
  my $p3 = pdl [$p1,$p2];
  $h = levmar($p3,$x, FUNC => $defst, UB => $ub, LB => $lb, @opts,
                      DERIVATIVE => 'analytic' );
# tapprox works here even though these pdls have different dims
  ok(tapprox($h->{P},$correct_minimum), "Hatfld b, lpp , threading over parameters");
#  deb $h->{P};
#  deb $h->{INFO};
}



print "1..25\n";

print "# type double\n";
$Type = double;
rosenbrock();
modified_rosenbrock();
powell();
if ($PDL::Fit::Levmar::HAVE_LAPACK) {
 hock_schittkowski_mod_76();
 hock_schittkowski_mod2_52();
 hock_schittkowski();
 boggs_tolle_3();
}
else {
 ok(1);
 ok(1);
 ok(1);
}
hatfldb();

print "# type float\n";
$Type = float;
rosenbrock();
modified_rosenbrock();
powell();
#boggs_tolle_3();
hatfldb();

=pod

foreach my $name (qw( mros ros powell modros mhatfldb bt3 hatfldb )) {
    foreach my $ext (qw( c o so )) {
#	deb "rm  $name.$ext ";
	system " rm -f $name.$ext ";
    }
}

=cut

print "# Ok count: $ok_count, Not ok count: $not_ok_count\n";

