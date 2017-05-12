use strict;
use Test::Simple tests => 7;
use Number::Format::Calc;
use Number::Format;

my ($n, $m);

print "testing mixing\n";
$n = new Number::Format::Calc ( '1,111.1', -thousands_sep => ",", -decimal_point => "." );
$m = new Number::Format::Calc ( '1.111,1', -thousands_sep => ".", -decimal_point => ",", decimal_digits => 2, decimal_fill=>1 );

ok ( $n eq "1,111.1" );
ok ( $m eq "1.111,10" );

ok ( $n + $m eq "2,222.2" );
ok ( $m + $n eq "2.222,20" );

print "testing methods\n";
ok ( $m->number == 1111.1 );
ok ( $m->fmod (9) eq "4,10" );
ok ( $m->fmod($n) eq "0,00" );
