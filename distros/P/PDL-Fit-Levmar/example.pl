use Data::Dumper;
use PDL;
use PDL::Fit::Levmar;
use PDL::Fit::Levmar::Func;
use PDL::NiceSlice;
use PDL::Core ':Internal'; # For topdl()

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
          '   function gaussian
              x = p0 * exp( -t*t * p1);
           ')->{REPORT};
}

sub myexp {
    my ($p,$x,$t) = @_;
    my $p0 = $p->at(0);
    my $p1 = $p->at(1);
    $x .= $p0 * exp(-$t*$t * $p1);
}

sub example2 {
    
    my $n = 100000;
    my $t = 10.0*(sequence($n)/$n -1/2);
    my $x = 3 * exp(-$t*$t * .3  );
    my $p = pdl [ 1, 1 ]; # initial guesses

    my $h = levmar($p,$x,$t, FUNC => \&myexp);
    deb $h->{REPORT};

}



example1();
example2();
