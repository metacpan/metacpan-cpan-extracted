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

# used to check some return types to make sure computaton was float
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

=pod
$Gf = '
       function
       x = p0 * exp( -t*t * p1);
      ';
=cut


$Gh = levmar_func(FUNC=>$Gf);

cpr "# Done compiling fit function.";

sub keep_work_space {
    my $n = 100;
    my $A = 10;
    my $t = sequence($Type, $n);
    $t *= $A/$n; $t -= $A/2;
    my $x = zeroes($Type,$n);
    my $p = pdl($Type, 1,2);
    my $ip = pdl($Type, 3,4);
    $x .= $p((0)) * exp(-$t*$t * $p((1)) );
    my $work = PDL->null;
    my $h = levmar($ip,$x,$t,$Gh,@g, WORK =>$work);
    ok(tapprox($h->{P},$p));
    check_type($h->{COVAR});
}

print "1..2\n";

print "# type double\n";
$Type = double;
keep_work_space();

print "# type float\n";

$Type = float;
keep_work_space();


print "# Ok count: $ok_count, Not ok count: $not_ok_count\n";
