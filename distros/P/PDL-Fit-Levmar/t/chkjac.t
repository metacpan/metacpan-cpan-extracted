use Data::Dumper;
use PDL;
use PDL::Fit::Levmar;
use PDL::Fit::Levmar::Func;
use PDL::NiceSlice;
use PDL::Core ':Internal'; # For topdl()
use Test::More;
use strict;

#  @g is global options to levmar
my @g = ( NOCOVAR => undef );

sub tapprox {
        my($a,$b,$eps) = @_;
        $eps = 0.00001 unless $eps;
        my $c = abs(topdl($a)-topdl($b));
        my $d = max($c);
        $d < $eps;
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
       x = p0 * (FLOAT)exp(-t*t * p1);
       jacobian
       FLOAT ex, arg;
       loop
       arg = -t*t * p1;
       ex = exp(arg);
       d0 = ex;
       d1 = -p0 * t*t * ex ;
      ';

sub gauss {
    my ($p,$x,$t) = @_;
    $x .=  $p((0)) * exp(-$t*$t * $p((1)));
}

sub jacgauss {
    my ($p,$d,$t) = @_;
    my $arg = -$t*$t * $p((1)); # uses a lot of memory
    my $exp = exp($arg);
    $d((0)) .= $exp;
    $d((1)) .= -$p((0)) * $t*$t * $exp;
}

# there is a big difference in speed here!

my $Gh = levmar_func(FUNC=>$Gf);

cpr "# Done compiling fit function.";


# This checks the case when t is sent.
# The problems in liblevmar.t have no t (mostly)
# There is an interface for that, but I have not checked it yet.
sub chkjac {
    my ($eps, $Type) = @_;
    $eps ||= 1e-5;
    my $n = 10;
    my $t = zeroes($Type, $n)->xlinvals(map pdl($Type, $_), -2.5,2);
    my $p = pdl $Type, [2.1,1.1];
    my $err = levmar_chkjac($Gh,$p,$t);
    my $fref = \&gauss;
    my $jref = \&jacgauss;
    my $gh2 = levmar_func(FUNC=> $fref, JFUNC => $jref);
    my $err2 = levmar_chkjac($gh2,$p,$t);
    ok(tapprox($err2,$err,$eps), "Chkjac $Type lpp results == perl sub results")
      or diag "err1= $err\nerr2= $err2";
}

chkjac(1e-5, double);
chkjac(1e-4, float);

done_testing;
