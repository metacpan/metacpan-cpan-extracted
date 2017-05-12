use strict;
use Test::Simple tests => 2;
use Number::Format::Calc (-thousands_sep => ".", -decimal_point=>",", -decimal_digits=>2 );
use Number::Format;

my ($n, $m);

print "testing defaults\n";
$n = new Number::Format::Calc ( '1.111,511' );
ok ( $n+10.1234 eq "1.121,63" );

$n = new Number::Format::Calc ( '1.111,511', -decimal_digits=>4 );
ok ( $n+10.1234 eq "1.121,6344" );