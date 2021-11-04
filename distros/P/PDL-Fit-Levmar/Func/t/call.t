use PDL;
use PDL::Fit::Levmar::Func;
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

my $Gf = levmar_func( FUNC => '
   function
   x = p0 * t * t;
 ');
my $x =  $Gf->call([2],sequence(10));
ok(tapprox($x, [0, 2, 8, 18, 32, 50, 72, 98, 128, 162]), " call func from lpp");

$Gf = levmar_func( FUNC => '
#include<string.h>
   function
   memset( x, 0, n );
   loop
   x = p0 * t * t;
 ');
my $x =  $Gf->call([2],sequence(10));
ok(tapprox($x, [0, 2, 8, 18, 32, 50, 72, 98, 128, 162]), "lpp func with #include");

done_testing;
