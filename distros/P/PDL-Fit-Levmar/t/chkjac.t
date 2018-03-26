use Data::Dumper;
use PDL;
use PDL::Fit::Levmar;
use PDL::Fit::Levmar::Func;
use PDL::NiceSlice;
use PDL::Core ':Internal'; # For topdl()
use strict;
use vars ( '$testno', '$ok_count', '$not_ok_count', '@g', '$Gf',
	   '$Gh', '$Type');

#  @g is global options to levmar
@g = ( NOCOVAR => undef );

$ok_count = 0;
$not_ok_count = 0;

sub tapprox {
        my($a,$b,$eps) = @_;
        $eps = 0.00001 unless $eps;
        my $c = abs(topdl($a)-topdl($b));
        my $d = max($c);
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

sub deb  { print STDERR $_[0],"\n" }
sub cpr  { print $_[0],"\n" }

cpr "# Test implicit threading over lemvar()";
cpr "# Compiling fit function...";

# Need to use jacobian so fitting is more robust
$Gf = '
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

$Gh = levmar_func(FUNC=>$Gf);

cpr "# Done compiling fit function.";


# This checks the case when t is sent.
# The problems in liblevmar.t have no t (mostly)
# There is an interface for that, but I have not checked it yet.
sub chkjac {
    my ($eps) = @_;
    $eps = 1e-5 unless $eps;
    my $n = 10;
    my $r = 5;
    my $t = sequence $Type, $n;
    $t *= $r / $n;
    $t += -$r/2;
    my $p = pdl $Type, [2.1,1.1];
    my $err = levmar_chkjac($Gh,$p,$t);
    my $fref = \&gauss;
    my $jref = \&jacgauss;
    my $gh2 = levmar_func(FUNC=> $fref, JFUNC => $jref);
    my $err2 = levmar_chkjac($gh2,$p,$t);
    ok(tapprox($err2,$err,$eps), "Chkjac  lpp results == perl sub results");
    print "# err1= $err\n";
    print "# err2= $err2\n";
}

print "1..2\n";

print "# type double\n";
$Type = double;

chkjac(1e-5);

print "# type float\n";
$Type = float;

chkjac(1e-4);

print "# Ok count: $ok_count, Not ok count: $not_ok_count\n";

