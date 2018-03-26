# This script needs cleaning up, particulary
# by using 'use strict';


use PDL;
use PDL::Fit::Levmar;
use PDL::Fit::Levmar::Func;
use PDL::Core ':Internal'; # For topdl()
#use strict;


$ok_count = 0;
$not_ok_count = 0;

print "1..26\n";
ok(1, "Levmar and Levmar::Func Modules loaded"); # If we made it this far, we're ok.

# set to 0 or 1, for no/yes commentary
# 0 is required for 'make test' which uses harness
$pinfo = 0;

# for quick diagnostic
sub pinfo { 
    print STDERR $_[0],"\n" if $pinfo;
}

sub deb { 
    print STDERR $_[0],"\n";
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

sub tapprox {
        my($a,$b) = @_;
        $a = topdl($a);
        $b = topdl($b);
        my $c = abs($a-$b);
        my $d = max($c);
        print "# tapprox: $a, $b : max diff ";
        printf "%e\n",$d;
        $d < 0.0001;
}

# diagnostic lines for harness.
# compare to pinfo above
sub pri {
    my $s = shift;
    print "\# $s\n";
}



# Generate gaussian data.
# $N = number of data points
# $p = actual parameters
# $pfac = factors multiply by $p to make wrong guesses
# $noise = noise amplitude on data
sub make_gaussian {
    my ($N,$parg,$pfac,$noise) = @_; 
    my ($p0, $p1, $p2) = list($parg);  # three model parameters
    my $t =(sequence($N)-$N/2)/$N; # ordinates
    my $x = $p0 *  exp(-($t-$p1)*($t-$p1)*$p2); # co-ordinates
    my $p_actual = $parg->copy;
    my $p = $parg->copy;
    $p *= $pfac;
    my $ip = $p->copy;  # may want to save initial guess, because $p is changed in place
    if ( $noise > 0 ) {
	$x += $p0 * $noise * grandom($x);
    }

#    deb "## in make_gaussian";
    return ($t,$x,$p,$ip,$p_actual);
}    

# disable this normally
sub prep {
    return ;
    my @p = list $p;
    my @ip = list $ip;
    my @pact = list $p_actual;
    deb "ip   [" . join(",",@ip) . "]";
    deb "p    [" . join(",",@p) . "]";
    deb "pact [" . join(",",@pact) . "]";
    my $s = "[" . join(",",@p) . "]";
    deb " tapprox(\$p, $s ), "
}

srand(1); # must call this so that sequence of random numbers is reproducible
#make_gaussian(1000, pdl(1,.1,1), pdl(1.2, .9, 1.3), 0);
($t,$x,$p,$ip,$p_actual) = make_gaussian(1000, pdl(2.0, 0.1, 1.0), pdl(1.3, .99, 1.002), 0);
prep();

# Create a model function from C-like definition
$func1 = 
'
function gaussian1
x = p0 * exp(-(t-p1)*(t-p1)*p2);

jacobian jacgaussian1
FLOAT arg, expf;
loop
arg = t - p1;
expf = exp(-arg*arg*p2);
d0 = expf;
d1 = p0 * 2 * arg * p2 *expf;
d2 = p0*(-arg*arg)*expf;

' ;

# No jacobian
$func2 = 
'
function gaussian2
FLOAT arg;
loop
arg = t[i] - p[1];
x[i] = p[0] * exp(-arg*arg*p[2]);
end function

' ;

$func3 = 
'
function gaussian3
FLOAT arg;
loop
arg = t[i] - p[1];
x[i] = p[0] * exp(-arg*arg*p[2]);
end function

jacobian jacgaussian3
FLOAT arg, expf;
loop
arg = t[i] - p[1];
expf = exp(-arg*arg*p[2]);
d0 = expf;
d1 = p[0]*2*arg*p[2]*expf;
d2 = p[0]*(-arg*arg)*expf;
end jacobian 
' ;



# no blank line; d2[i] , not d2
$func4 = 
'
function gaussian4
FLOAT arg;
loop
arg = t[i] - p[1];
x[i] = p[0] * exp(-arg*arg*p[2]);
end function
jacobian jacgaussian4
FLOAT arg, expf;
loop
arg = t[i] - p[1];
expf = exp(-arg*arg*p[2]);
d0[i] = expf;
d1 = p[0]*2*arg*p[2]*expf;
d2[i] = p[0]*(-arg*arg)*expf;
end jacobian 

' ;

$func5 =  '
       function gaussian5
       FLOAT arg;	
       loop
       arg = t[i] - p[1];
       x[i] = p[0] * exp(-arg*arg*p[2]);

       jacobian jacgaussian4
       FLOAT arg, expf;
       loop
       arg = t[i] - p[1];
       expf = exp(-arg*arg*p[2]);
       d0[i] = expf;
       d1 = p[0]*2*arg*p[2]*expf;
       d2[i] = p[0]*(-arg*arg)*expf;

';

$func6 =  '
       function gaussian5
       x[i] = p[0] * exp(-(t[i]-p[1])*(t[i]-p[1])*p[2]);

       jacobian jacgaussian4
       FLOAT arg, expf;
       loop
       arg = t[i] - p[1];
       expf = exp(-arg*arg*p[2]);
       d0[i] = expf;
       d1 = p[0]*2*arg*p[2]*expf;
       d2[i] = p[0]*(-arg*arg)*expf;

';


$cfunc = '
#include <math.h>
#include <stdio.h>

void gauss_from_c(FLOAT *p, FLOAT *x, int m, int n, void *data)
{
  int i;
  FLOAT *t = (FLOAT *) data;
  for(i=0; i<n; ++i){
  x[i] = p[0] * exp(-(t[i] - p[1])*(t[i] - p[1])*p[2]);
  }
}
void jacgauss_from_c(FLOAT *p, FLOAT *jac, int m, int n, void *data)
{
  int i,j;
  FLOAT *t = (FLOAT *) data;
   FLOAT arg, expf;
  for(i=j=0; i<n; ++i){
   arg = t[i] - p[1];
   expf = exp(-arg*arg*p[2]);
   jac[j++] = expf;
   jac[j++] = p[0]*2*arg*p[2]*expf;
   jac[j++] = p[0]*(-arg*arg)*expf;
  }
}
';


#---TEST------------------------------------------------



# Do the fit.
$hout = levmar($p,$x,$t, FUNC => $func1 , NOCLEAN=>1);

# see if all parameters are found correctly
ok( tapprox( $hout->{P},$p_actual) , "Function def as string");

#---TEST------------------------------------------------
# The same thing, but with the function definition in a file, rather than a string.
# Definition file must end in '.lpp'
$hout = levmar($p,$x,$t, FUNC => './t/gauss_from_def.lpp');
ok ( tapprox( $hout->{P} ,$p_actual), "Function def from file");

#---TEST------------------------------------------------
# Now use $func1 from above to create the Func object ourselves rather
# than letting levmar do it so we can manipulate it.

$funch1 = levmar_func( FUNC => $func1 ); # create the function and return handle (pointer or whatever)
# Lets look at the commands that compiled and linked the function...'
pinfo join( "\n" , $funch1->get_cc_str  ), "\n" ;

# Lets look at the filenames
@filenames = $funch1->get_file_names;
pinfo join( "\n" , @filenames ), "\n" ;

# But these files no longer exist
ok ( not ( -e $filenames[0] and -e $filenames[1] and -e $filenames[2] ),
     "Make Func object, check that temp files are gone" );

# Check again the the fit works on this Func object
$hout = levmar($p,$x,$t, FUNC => $funch1 ); # now we are passing the function handle
ok ( tapprox( $hout->{P} ,$p_actual), "Fit with Func object");

#---TEST------------------------------------------------
# Pass NOCLEAN so that the files used in compiling are not removed.

$funch1 = levmar_func( FUNC => $func3, NOCLEAN => 1 ); 
@filenames = $funch1->get_file_names;
pinfo join( "\n" , @filenames ), "\n" ;
ok ( -e $filenames[0] and -e $filenames[1] and -e $filenames[2] ,
     "Check that NOCLEAN does not remove files");


$p = $ip->copy;
$hout = levmar($p,$x,$t, FUNC => $funch1 ); # now we are passing the function handle
ok ( tapprox ( $hout->{P},$p_actual),
     "Pass Func object");

# Now remove them
unlink @filenames;

#---TEST------------------------------------------------
# Try with numeric derivative
$p = $ip->copy;
$hout = levmar($p,$x,$t, FUNC => $func1, DERIVATIVE => 'numeric' );
ok ( tapprox ( $hout->{P},$p_actual), "Numeric derivative");

#---TEST------------------------------------------------
# Try with explicit analytic derivative
$p = $ip->copy;
$hout = levmar($p,$x,$t, FUNC => $func1, DERIVATIVE => 'analytic');
ok ( tapprox(  $hout->{P},$p_actual),  "Ask explicitly for analytic");

#---TEST------------------------------------------------
# Try with numeric derivative
$p = $ip->copy;
$hout = levmar($p,$x,$t, FUNC => $func2, DERIVATIVE => 'numeric' );
ok ( tapprox ( $hout->{P},$p_actual), "Numeric derivative, no jacobian");

#---TEST------------------------------------------------
# Try with explicit analytic derivative
# Since there is no jacobian, levmar will use 'numeric' even
# though analytic is asked for.
$p = $ip->copy;
$hout = levmar($p,$x,$t, FUNC => $func2, DERIVATIVE => 'analytic' );
ok ( tapprox( $hout->{P} ,$p_actual), "Don't give jacobian and ask for analytic derivative");

#---TEST------------------------------------------------
# func4 tests syntax changes in def file
$p = $ip->copy;
$hout = levmar($p,$x,$t, FUNC => $func4);
ok ( tapprox ( $hout->{P},$p_actual), "def syntax: No end function statement is ok");

#---TEST------------------------------------------------
# func5 more syntax changes
$p = $ip->copy;
$hout = levmar($p,$x,$t, FUNC => $func6);
ok ( tapprox ( $hout->{P},$p_actual), "def syntnax: No loop statement if not needed.");

#---TEST------------------------------------------------
# func5 more syntax changes
$p = $ip->copy;
$hout = levmar($p,$x,$t, FUNC => $func5);
ok ( tapprox ( $hout->{P},$p_actual), "def syntax:  d1 --> d1[i], etc.");

#---TEST------------------------------------------------
$p = $ip->copy;
$hout = levmar($p,$x,$t, CSRC => 't/gauss_from_c.c' );
ok ( tapprox($hout->{P},$p_actual), " CSRC => 't/gauss_from_c.c'");

#---TEST------------------------------------------------
$p = $ip->copy;
$hout = levmar($p,$x,$t, FUNC => 't/gauss_from_c.c' );
ok ( tapprox($hout->{P},$p_actual), " FUNC => 't/gauss_from_c.c'");


#---TEST------------------------------------------------
$p = $ip->copy;
$hout = levmar($p,$x,$t, CSRC => $cfunc );
ok ( tapprox($hout->{P} ,$p_actual), " C source in string ");

#---TEST------------------------------------------------
$p = $ip->copy;
$hout = levmar($p,$x,$t, FUNC => $cfunc );
ok ( tapprox($hout->{P},$p_actual), " C source in string , but passed as FUNC ");


#---TEST------------------------------------------------
# Fix some of the parameter and let the others vary
#($t,$x,$p,$ip,$p_actual) = make_gaussian(1000, pdl(2.0, 0.1, 1.0), pdl(1.3, .99, 1.002), 0);
($t,$x,$p,$ip,$p_actual) = make_gaussian(1000, pdl(2.0, .5, 1.0), pdl(1.1, .9, 1.2), 0);

if ($PDL::Fit::Levmar::HAVE_LAPACK) {

$p = $ip->copy;
$hout = levmar($p,$x,$t, FUNC => $func1,  FIX => [1,0,0] );
ok ( tapprox( $hout->{P}, [2.2,0.74393499048208,0.66570905852215] ), 
     "FIX => [1,0,0], Fix a parameter or two" );
prep();

#---TEST------------------------------------------------
$p = $ip->copy;
$hout = levmar($p,$x,$t, FUNC => $func1,  FIX => [0,1,0] );
ok ( tapprox( $hout->{P}, [1.97020240277861,0.45,1.11726869724001] ), 
     "FIX => [0,1,0]" );
prep();


#---TEST------------------------------------------------
$p = $ip->copy;
$hout = levmar($p,$x,$t, FUNC => $func1,  FIX => [1,0,1], DERIVATIVE => 'numeric' );
ok (  tapprox( $hout->{P}, [2.2,0.527550816516417,1.2] ), 
     "FIX => [1,0,1], and numeric derivative" );
prep();

# Linear constraints determined through A x p = b
# where $A->dims = ($k,$m);
# If we have one constraint, ie k=1, we can also use a 1-d piddle
$A =  [ 1,0,0];
$b =  [ $ip->at(0) ];
$p = $ip->copy;
$hout = levmar($p,$x,$t, FUNC => $func1, A => $A, B => $b );
ok (  tapprox( $hout->{P}, [2.2,0.74393499048208,0.66570905852215] ), 
     "A =>  [1,0,0] , B =>  [ \$p->at(0)], linear constraints " );
prep();

$A = [ [ 1,0,0], [0,0,1 ] ];
$b =  [ $ip->at(0), $ip->at(2) ];
$p = $ip->copy;
$hout = levmar($p,$x,$t, FUNC => $func1, A => $A, B => $b );
ok (   tapprox( $hout->{P}, [2.2,0.527550911537348,1.2] ), 
     "A => [[ 1,0,0], [0,0,1 ]] , B => [ 1.2, 1.3 ],".
      "(last 2 tests same as 2 FIX's above)" );
prep();

#$p = $ip->copy;
#$hout = levmar($p,$x,$t, FUNC => $func1, FIXB => [1,0,0]);
# something broken here. remove temporarily
#ok ( tapprox( $hout->{P}, [2.2, 0.68758166, 0.75296237], ),
#     "FIXB [1,0,0] " . $hout->{P} . " [2.2 0.68758166 0.75296237] "  );

#ok ( tapprox( $hout->{P}, [2.2, 0.69986757, 0.75522784] ),
#     "FIXB [1,0,0] " . $hout->{P} . " [2.2, 0.69986757, 0.75522784] "  );

$p = $ip->copy;
print "# init p " , $p, "\n";
$hout = levmar($p,$x,$t, FUNC => $func1, FIXB => [1,0,1]);
ok ( tapprox( $hout->{P}, [2.2, 0.52755091, 1.2] ), "FIXB [1,0,1]");
prep();

}
else {
ok(1);
ok(1);
ok(1);
ok(1);
ok(1);
ok(1);
}

$p = $ip->copy;
$hout = levmar($p,$x,$t, FUNC => $func1, UB => [2.3, .5, 3 ], LB => [ 0,-.1, .5] );
ok ( tapprox( $hout->{P}, $p_actual ),
     "UB , LB; Box constraints  ");
prep();

$p = $ip->copy;
$hout = levmar($p,$x,$t, FUNC => $func1, UB => [2.3, .5, 3 ], LB => [ 0,-.1, .5], 
   DERIVATIVE => 'numeric' );
ok ( tapprox( $hout->{P}, $p_actual ),
     "UB , LB ; Box constraints, numeric derivative");
prep();


print "# Ok count: $ok_count, Not ok count: $not_ok_count\n";
