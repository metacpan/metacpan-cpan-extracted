use Data::Dumper;
use PDL;
use PDL::Fit::Levmar;
use PDL::Fit::Levmar::Func;
use PDL::NiceSlice;
use PDL::Core ':Internal'; # For topdl()

use strict;

# Checks doing a multidimensional fit.

use vars ( '$testno', '$ok_count', '$not_ok_count', '@g', '$Gf',
	   '$Gh', '$Type');

#  @g is global options to levmar
@g = ( NOCOVAR => undef );

$ok_count = 0;
$not_ok_count = 0;

sub tapprox {
        my($a,$b,$eps) = @_;
	$eps = 0.0001 unless defined $eps;
        my $c = abs(topdl($a)-topdl($b));
        my $d = max($c);
       	print "# tapprox: $a, $b : max diff ";
        printf "%e\n",$d;
        $d < $eps;
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

sub dimst {
    my $x = shift;
    return  "(" . join(',',$x->dims) . ")";
}

#sub deb  { print STDERR $_[0],"\n" }
#sub cpr  { print $_[0],"\n" }

sub gauss2d {
    my ($p,$xin,$t) = @_;
    my ($p0,$p1,$p2) = list $p;
    my $n = $t->nelem;
    my $t1 = $t(:,*$n); # first coordinate
    my $t2 = $t(*$n,:); # second coordinate
    my $x = $xin->splitdim(0,$n);
    $x .= $p0 * exp( -$p1*$t1*$t1 - $p2*$t2*$t2);
}

sub fit_gauss2d {
    my $n = 101;
    my $scale = 3;
    my $t = sequence($Type,$n);
    $t *= $scale/($n-1);
    $t  -= $scale/2;
    my $x = zeroes($Type,$n,$n);
    my $p = pdl $Type, [ .5,2,3];
    my $p1 = pdl $Type, [ 1,1,1];
    my $xlin = $x->clump(-1);
    gauss2d( $p, $xlin, $t->copy);
    my $h = levmar($p1,$xlin,$t,\&gauss2d);
    ok ( (tapprox($p,$h->{P}) and not  tapprox($p1,$h->{P}) ) , "-- 2-d gaussian");
}


print "1..2\n";

print "# double tests\n";
$Type = double;
fit_gauss2d();

print "# float tests\n";
$Type = float;
fit_gauss2d();
