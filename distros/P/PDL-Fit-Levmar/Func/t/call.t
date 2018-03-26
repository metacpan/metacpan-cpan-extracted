use Data::Dumper;
use PDL;
#use PDL::Fit::Levmar;
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


sub test1 {
    
    $Gf = levmar_func( FUNC => '
       function	   
       x = p0 * t * t;
     ');
    
    my $x =  $Gf->call([2],sequence(10));
    
    ok(tapprox($x, [0, 2, 8, 18, 32, 50, 72, 98, 128, 162]), " call func from lpp");
}

print "# testing call method from Func\n";
print "1..1\n";
test1();




