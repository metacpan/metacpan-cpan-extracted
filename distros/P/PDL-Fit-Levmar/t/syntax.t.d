use Data::Dumper;
use PDL;
use PDL::Fit::Levmar;
use PDL::Fit::Levmar::Func;
use PDL::NiceSlice;
use PDL::Core ':Internal'; # For topdl()

use strict;
use vars ( '$testno', '$ok_count', '$not_ok_count', '@t');

$ok_count = 0;
$not_ok_count = 0;

@t = ( TESTSYNTAX => 1);

sub tapprox {
        my($a,$b) = @_;
        my $c = abs(topdl($a)-topdl($b));
        my $d = max($c);
        $d < 0.0001;
}

sub grepres {
    my ($h,$pat) = @_;
    $h->{SYNTAXRESULTS} =~ /$pat/;
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

sub deb  { print STDERR $_[0],"\n" }

sub test1 {
  my    $str1 = 
'
function gaussian1
x = p0 * exp(-(t-p1)*(t-p1)*p2);

';

  my $f = levmar_func(FUNC=>$str1, @t);

  ok(grepres($f,':LOOP:'));

} # end test1


sub test2 {
    my  $MODROSLAM  = 1e2;

    my $str1 = "

    function modros
    x0 = 10 * (p1 -p0*p0);
    x1 = 1.0 - p0;
    x2 = $MODROSLAM;
    loop

    jacobian jacmodros
    d0[0] = -20 * p0;
    d1[0] = 10;
    d0[1] = -1;
    d1[1] = 0;
    d0[2] = 0;
    d1[2] = 0;
    loop
    
";


    my $str2 = "
    function modros
    noloop
    x0 = 10 * (p1 -p0*p0);
    x1 = 1.0 - p0;
    x2 = $MODROSLAM;

    jacobian jacmodros
    noloop
    d0[0] = -20 * p0;
    d1[0] = 10;
    d0[1] = -1;
    d1[1] = 0;
    d0[2] = 0;
    d1[2] = 0;
    
";

    my $f;
   $f = levmar_func(FUNC=>$str1,@t);
    ok( grepres($f,':LOOP:'), "explicit empty loop via loop directive");
    # I guess I'll let that go for now, because its harmless, even
    # Though there will be an empty loop

    $f = levmar_func(FUNC=>$str2, @t);
    ok(not(grepres($f,':LOOP:')), "no loop via noloop directive");
    
}

sub test3 {
    my $str1 = '
#define ROSD 105.0
 function mros
     x =((1.0-p0)*(1.0-p0) + ROSD*(p1-p0*p0)*(p1-p0*p0));

 jacobian jacmros
    d1=(-2 + 2*p0-4*ROSD*(p1-p0*p0)*p0);
    d2=(2*ROSD*(p1-p0*p0));

';
    my $f = levmar_func(FUNC=>$str1, @t);
    ok( (grepres($f,':PREFUNC:') ), "PREFUNC present");
} 


#test1();
#test2();
test3();


