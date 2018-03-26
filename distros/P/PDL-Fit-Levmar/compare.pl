use Data::Dumper;
use PDL;
use PDL::Fit::Levmar;
use PDL::Fit::Levmar::Func;
use PDL::NiceSlice;

# Levenberg Marquadt distributed with PDL
use PDL::Fit::LM;

# Benchmark Levmar somewhat and compare to LM

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

sub example1 {
    
    my $n = 10;
    my $t = 10.0*(sequence($n)/$n -1/2);
    my $x = 3 * exp(-$t*$t * .3  );
    my $p = pdl [ 1, 1 ]; # initial guesses

    print levmar($p,$x,$t, FUNC =>
          '   function sin1
              x = p0 * exp( -t*t * p1);
           ')->{REPORT};
}


sub expdec {
      my ($x,$par,$ym,$dyda) = @_;
      my ($a,$b,$c) = map {$par->slice("($_)")} (0..2);
      my $arg = $x/$a;
      my $ex = exp($arg);
      $ym .= $b*$ex+$c;
      my (@dy) = map {$dyda->slice(",($_)")} (0..2);
      $dy[0] .= -$b*$ex*$arg/$a;
      $dy[1] .= $ex;
      $dy[2] .= 1;
}

sub levexpjac {
    my ($p,$d,$t) = @_;
    my ($p0,$p1,$p2) = list($p);
    my $arg = $t/$p0;
    my $ex = exp($arg);
    $d((0)) .= -$p1*$ex*$arg/$p0;
    $d((1)) .= $ex;
    $d((2)) .= 1.0;
}


sub mylevmarexp {
    my ($p,$x,$t) = @_;
    my ($p0,$p1,$p2) = list($p);
    $x .= $p1 * exp($t/$p0) + $p2;
}

# slightly faster
sub mylevmarexp2 {
    my ($p,$x,$t) = @_;
    my ($p0,$p1,$p2) = list($p);
    $x .= exp($t/$p0);
    $x *= $p1;
    $x += $p2 
}

sub mysimp {
    my ($p,$x,$t) = @_;
    my ($p0,$p1, $p2) = list($p);
    $x .= $p0 * $t + $p1 + $p2 * $t*$t;
#    deb $t;
}

sub mysimpjac {
    my ($p,$d,$t) = @_;
    my @dims = $d->dims;
    deb "** perl deriv sub d dims  $dims[0], $dims[1]";
    my ($p0,$p1,$p2) = list($p);
    $d((0)) .= $t;
    $d((1)) .= 1;
    $d((2)) .= $t*$t;
    deb $t;
    deb $d;

}


sub other_mod_fit {
    my $n =10;
    my ($ym,$covar,$iters);
    my $x = sequence($n)/$n;
    my $y = 2 * exp($x/3) + 1;
    my $a = pdl [ .5, 1, 1];
    my $a0 = $a->copy;
    my $ntimes = 10000;

    my $method = 3;

    if ( 1 == $method ) {
	deb "Doing LM";
        for(my $i=0;$i<$ntimes;$i++) {
	    $a = $a0->copy;
	    ($ym,$a,$covar,$iters)=
		lmfit $x, $y, 1,\&expdec, $a, {Maxiter => 100, Eps => 1e-15};
	}
    }
    elsif ( 2 == $method ) {
	deb "Doing String";
	my $f = levmar_func(  FUNC=> '
                        function myexp
                        loop
                        x = p1 * exp(t/p0) + p2;
                        jacobian myexp
                        double ex,arg;
                        loop
                        arg = t/p0;
                        ex = exp(arg);
                        d0 = -p1 * ex *arg/p0;
                        d1 = ex;
                        d2 = 1.0;
          ',
	 NOCLEAN => 1);

	  for(my $i=0;$i<$ntimes;$i++) {
	      $a = $a0->copy;
#	      my $h = levmar($a,$y,$x, FUNC=> $f , 'DERIVATIVE' => 'numeric');
	      my $h = levmar($a,$y,$x, FUNC=> $f );
	  }
    }

    elsif ( 3  ==  $method) {
   	  deb "Doing pure perl";
	  for(my $i=0;$i<$ntimes;$i++) {
	      $a = $a0->copy;
	      my $h = levmar($a,$y,$x, FUNC=> \&mylevmarexp2, JFUNC => \&levexpjac,
#			     DERIVATIVE => 'numeric' );
			     DERIVATIVE => 'analytic' );
	      
	  }
      }
    deb $a;
}

sub newtest {
    my $n = 10;
    my $t = sequence($n);
    my $x =  2*$t + 7 + 5*$t*$t;
    my $a0 = pdl [ 3 , 2, 2];
    my $a = $a0->copy;
    my $h = levmar($a,$x,$t, FUNC=> \&mysimp, JFUNC => \&mysimpjac,
		   DERIVATIVE => 'numeric' );
#		   DERIVATIVE => 'analytic' );
#    deb $a;
}


#example1();

other_mod_fit();
#newtest();
