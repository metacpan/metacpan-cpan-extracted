use Data::Dumper;
use PDL;
use PDL::Fit::Levmar;
use PDL::Fit::Levmar::Func;
use PDL::NiceSlice;
use PDL::Core ':Internal'; # For topdl()
use Test::More;

use strict;

# Checks doing a multidimensional fit.

#  @g is global options to levmar
my @g = ( NOCOVAR => undef );

sub tapprox {
        my($a,$b,$eps) = @_;
	$eps = 0.0001 unless defined $eps;
        my $c = abs(topdl($a)-topdl($b));
        my $d = max($c);
       	print "# tapprox: $a, $b : max diff ";
        printf "%e\n",$d;
        $d < $eps;
}

sub dimst {
    my $x = shift;
    return  "(" . join(',',$x->dims) . ")";
}

sub gauss2d {
    my ($p,$xin,$t) = @_;
    my ($p0,$p1,$p2) = list $p;
    my $n = $t->nelem;
    my $t1 = $t(:,*$n); # first coordinate
    my $t2 = $t(*$n,:); # second coordinate
    my $x = $xin->splitdim(0,$n);
    $x .= ($p0 * exp( -$p1*$t1*$t1 - $p2*$t2*$t2))->convert($x->type->enum);
}

sub fit_gauss2d {
    my ($Type) = @_;
    my $n = 101;
    my $scale = 3;
    my $t = zeroes($Type, $n)->xlinvals(map pdl($Type, $_), -1.5,1.5);
    my $xlin = zeroes($Type,$n*$n);
    my $p = pdl $Type, [ .5,2,3];
    my $p1 = pdl $Type, [ 1,1,1];
    gauss2d( $p, $xlin, $t->copy);
    my $h = levmar($p1,$xlin,$t,\&gauss2d);
    ok ( (tapprox($p,$h->{P}) and not  tapprox($p1,$h->{P}) ) , "-- 2-d gaussian");
}

fit_gauss2d(double);
fit_gauss2d(float);

done_testing;
