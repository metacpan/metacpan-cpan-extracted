use Data::Dumper;
use PDL;
use PDL::Fit::Levmar;
use PDL::Fit::Levmar::Func;
use PDL::NiceSlice;
use PDL::Core ':Internal'; # For topdl()
use Test::More;

use strict;

# Check pdl 'threading'. That is, automatically looping over
# extra dimensions in pdls

#  @g is global options to levmar
my @g = ( NOCOVAR => undef );

sub tapprox {
        my($a,$b) = @_;
        my $c = abs(topdl($a)-topdl($b));
        my $d = max($c);
        print "# tapprox: a=$a, b=$b\n";
        $d < 0.0001;
}

sub tapprox_cruder {
        my($a,$b) = @_;
        my $c = abs(topdl($a)-topdl($b));
        my $d = max($c);
	print "# tapprox: a=$a, b=$b\n";
        $d < 0.001;
}

sub check_type {
    my ($Type, @d) = @_;
    my $i=0;
    foreach ( @d )  {
	die "$i: not $Type" unless $Type == $_->type;
	$i++;
    }   
}

sub dimst {
    my $x = shift;
    return  "(" . join(',',$x->dims) . ")";
}

sub deb  { print STDERR $_[0],"\n" }
sub cpr  { print $_[0],"\n" }

cpr "# Test implicit threading over levmar()";
cpr "# Compiling fit function...";

# Need to use jacobian so fitting is more robust
my $Gf = '
       function
       x = p0 * exp( -t*t * p1);
       jacobian
       FLOAT ex, arg;
       loop
       arg = -t*t * p1;
       ex = exp(arg);
       d0 = ex;
       d1 = -p0 * t*t * ex ;
      ';

=pod

$Gf = '
       function
       x = p0 * exp( -t*t * p1);
      ';


=cut

# there is a big difference in speed here!

my $Gh = levmar_func(FUNC=>$Gf);

cpr "# Done compiling fit function.";

# Thread x. Try the same parameters on different sets of data.
# Also test workspace allocation.
sub thread1 {
    my ($Type) = @_;
    my $n = 10000;
    my $t = zeroes($Type, $n)->xlinvals(map pdl($Type, $_), -5,4.999);
    my $params =  [ [3,.2], [ 9, .1] , [2,.01], [3,.3] ];
    my $x = zeroes($Type,$n,scalar @$params);
    my $i = 0;
    map {  $x(:,$i++)  .= $_->[0] * exp(-$t*$t * $_->[1]  ) }  @$params;
    my $p = pdl $Type, [ 5, 1]; # starting guess 
    check_type($Type, $p,$x,$t);
    my $w = PDL->null;
    my $h = levmar(  $p, $x, $t, $Gh, @g, WORK => $w, DERIVATIVE => 'numeric');
    check_type($Type, $h->{INFO});
    ok(tapprox($h->{P}, pdl($Type, $params)), "Thread x, 1 thread dim ($Type)")
        or diag "got=", $h->{P}, "expected=", pdl($Type, $params),
            "report=", levmar_report($h);
    my $m = 2;
    my $s = 4*$n+4*$m + $n*$m + $m*$m;
    ok($s == $w->nelem, " Workspace, numeric,  allocated correctly in pp_def");
    $h = levmar(  $p, $x, $t, $Gh, @g, WORK => $w);
    ok($s == $w->nelem, " Workspace from numeric accepted when analytic");
    $w = PDL->null;
    $h = levmar(  $p, $x, $t, $Gh, @g, WORK => $w);
    $s = 2*$n+4*$m + $n*$m + $m*$m;
    ok($s == $w->nelem, " Workspace, analytic, allocated correctly in pp_def");
    check_type($Type, $w);
}

# Change the following routines to use map the same way

# Thread p. Not the right expression, I think.
# ie, try multiple parameters a single data set.
sub thread2 {
    my ($Type) = @_;
    my $n = 10000;
    my $t = zeroes($Type, $n)->xlinvals(map pdl($Type, $_), -5,4.999);
    my $x = zeroes($Type, $n);
    my $params =   [[0,3,.2]]; # only 1 dimension
    map {  $x(:,$_->[0])  .= $_->[1] * exp(-$t*$t * $_->[2]  ) }  @$params;
    my $p = pdl $Type, [ [ 5, 1], [ 2,4] ]; # starting guess 
    my $outp = pdl ($Type, $params);
    my $correct =  pdl $Type, [$outp(1:2,(0)), $outp(1:2,(0))]; #x Ugly
    check_type($Type, $p,$x,$t);
    my $h = levmar($p, $x, $t, $Gh, @g);
    check_type($Type, $h->{INFO});
# Disabled for levmar-2.5 , not working 
    ok( tapprox($h->{P}, $correct ), "Thread p, 1 thread dim");
}

# This one threads over both p and x, with one
# extra dimension
sub thread3 {
    my ($Type) = @_;
    my $n = 10000;
    my $t = zeroes($Type, $n)->xlinvals(map pdl($Type, $_), -5,4.999);
    my $params =  [ [0,3,.2], [1, 2, .1] ];
    my $x = zeroes($Type, $n,scalar(@$params));
    my $res =  pdl $Type, $params;
    map {  $x(:,$_->[0])  .= $_->[1] * exp(-$t*$t * $_->[2]  ) }  @$params;
    my $p = pdl $Type, [ [ 5, 1], [2,4]] ; # starting guess 
    check_type($Type, $p,$x,$t);
    my $h = levmar($Gh , $p,$x,$t,  @g );
    check_type($Type, $h->{INFO});
    ok( tapprox($h->{P}, $res(1:2,:)) ,
	"Thread both x and p, 1 thread dim");
}

sub thread4 {
    my ($Type) = @_;
    my $n = 1000;
    my $t = zeroes($Type, $n)->xlinvals(map pdl($Type, $_), -5,4.999);
# Put any number of triples of actual parameters here.
    my $params =  [ [0,3,.2], [1, 28, .1] , [2,2,.01], [3,3,.3] ];
    my $nx = scalar(@$params);
    my $x = zeroes($Type, $n,$nx);
    my $res =  pdl $Type, $params;
    map {  $x(:,$_->[0])  .= $_->[1] * exp(-$t*$t * $_->[2]  ) }  @$params;
# put any number of initial parameter pairs here
    my $p = pdl $Type, [ [ 5, 1], [2,4], [2,3], [1,1], [1.5, 3] ] ; # starting guess 
    my $np = $p->dim(1);
    cpr "# Trying x" . dimst $x->dummy(-1,$np);
    cpr "# input  p" . dimst $p->dummy(1,$nx);
    check_type($Type, $p,$x,$t);
    my $h = levmar($p->dummy(1,$nx), $x->dummy(-1,$np), $t, $Gh , @g );
    cpr "# check that output p has correct shape and values";

# Disabled for levmar-2.5 , not working    
#    ok( tapprox($h->{P}, $res(1:,:)->dummy(-1,$np)),
#	"Thread both x and p, 2 thread dims");

    cpr "# returned  p" . dimst $h->{P};
    cpr "# and  covar" . dimst $h->{COVAR};

    my $covar = PDL->null;
    my $save_covar = $covar;
    check_type($Type, $p,$x,$t);
    $h = levmar($p->dummy(1,$nx), $x->dummy(-1,$np), $t, $Gh , @g,
		   COVAR => $covar);
    check_type($Type, $h->{INFO});
    my $count = $h->{COVAR}->nelem;
    $h = levmar($p->dummy(1,$nx), $x->dummy(-1,$np), $t, $Gh , @g,
		   COVAR => $covar);
    check_type($Type, $h->{INFO});
    $save_covar .= 1;
    my $sum = $h->{COVAR}->sum;
    ok( $sum == $count, "Test passing null COVAR pdl");
}

sub thread5 {
    my ($Type) = @_;
    my $n = 10000;
    my $t = zeroes($Type, $n)->xlinvals(map pdl($Type, $_), -5,4.999);
    my $x = zeroes($Type, $n,4);
    my $params =  [ [3,.2], [ 28, .1] , [2,.01], [3,.3] ];
    my $i = 0;
    map {  $x(:,$i++)  .= $_->[0] * exp(-$t*$t * $_->[1]  ) }  @$params;
    my $p = pdl $Type, [ 5, 1]; # starting guess 
    check_type($Type, $p,$x,$t);
    my $h = levmar(  $p, $x, $t, $Gh, FIX=> [1,0], @g);
    check_type($Type, $h->{INFO});
    my $outp = pdl $Type, [[ 5, 0.4730849], [5, 1 ],
		   [5, 0.16286478],  [5, 0.70962698], ];

    ok( tapprox_cruder($h->{P}, $outp) , 
	"Thread x, 1 thread dim, FIX=>[1,0] (linear constr.)" );

#   ok( tapprox_cruder($h->{P}, $outp) , 
#	"Thread x, 1 thread dim, FIX=>[1,0] (linear constr.)  " .
#          $h->{P} . "  " . $outp );

}

# same but easier to read
sub thread6 {
    my ($Type) = @_;
    my $n = 1000;
    my $t = zeroes($Type, $n)->xlinvals(map pdl($Type, $_), -5,4.999);
# Put any number of pairs of actual parameters here.
    my $params =  [ [500,.01], [3, .1] , [2,.01], [50,.3] ];
    my $nx = scalar(@$params);
    my $x = zeroes($n,$nx);
    my $i = 0;
    foreach( @$params ) {
	$x(:,$i++) .= $_->[0] * exp(-$t*$t * $_->[1]  );
    }
# put any number of initial parameter pairs here
   my $p = pdl [ [ 5, 1], [2,1], [2,3], [40,1], [1.5, 3] ] ; # starting guess 
    my $np = $p->dim(1);
    cpr "# Trying x" . dimst $x->dummy(-1,$np);
    cpr "# input  p" . dimst $p->dummy(1,$nx);
    my $pd = $p->dummy(1,$nx);
    my $xd = $x->dummy(-1,$np);
    my $h = levmar($p->dummy(1,$nx), $x->dummy(-1,$np), $t, $Gh , @g );
    cpr "# check that output p has correct shape and values";
    ok( tapprox($h->{P}, pdl($params)->dummy(-1,$np)),
	"Thread both x and p, 2 thread dims");
    cpr "# returned  p" . dimst $h->{P};
    cpr "# and  covar" . dimst $h->{COVAR};
    cpr "# and  info " . dimst $h->{INFO}->slice('(0),:,:');
    deb $h->{INFO}->slice('(0),:,:');
    my $inf = $h->{INFO};
    cpr "# and  info " . dimst $h->{INFO}->slice('(0)');
    cpr "# finally ".  dimst $inf->((0));
    cpr "# finally ".  dimst $h->{REASON};
    my $r = $h->{REASON};
    deb $r;
    my $inds = which($r != 6);
    deb  pdl( [ $inds % $nx, $inds / $nx])->transpose;
    deb  pdl( [ $inds % $nx, $inds / $nx])->transpose;
#    deb $h->{RET};
}

#thread6(double);
thread1(double);
thread2(double);
thread3(double);
thread4(double);

if ($PDL::Fit::Levmar::HAVE_LAPACK) {
 thread5(double);
}

#thread1(float);
#thread2(float);
#thread3(float);
#thread4(float);
#thread5(float);

done_testing;
