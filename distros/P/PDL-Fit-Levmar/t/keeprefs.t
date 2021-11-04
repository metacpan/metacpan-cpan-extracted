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
        my($a,$b) = @_;
        my $c = abs(topdl($a)-topdl($b));
        my $d = max($c);
        $d < 0.0001;
}

# used to check some return types to make sure computaton was float
sub check_type {
    my ($Type, @d) = @_;
    my $i=0;
    foreach ( @d )  {
	die "$i: not $Type, ", $_->info unless $Type == $_->type;
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


my $Gh = levmar_func(FUNC=>$Gf);

cpr "# Done compiling fit function.";

sub keep_work_space {
    my ($Type) = @_;
    my $n = 100;
    my $t = zeroes($Type, $n)->xlinvals(map pdl($Type, $_), -5,4.9);
    my $x = zeroes($Type,$n);
    my $p = pdl($Type, 1,2);
    my $ip = pdl($Type, 3,4);
    $x .= $p((0)) * exp(-$t*$t * $p((1)) );
    my $work = PDL->null;
    my $h = levmar($ip,$x,$t,$Gh,@g, WORK =>$work);
    ok(tapprox($h->{P},$p));
    check_type($Type, $h->{COVAR});
}

keep_work_space(double);
keep_work_space(float);

done_testing;
