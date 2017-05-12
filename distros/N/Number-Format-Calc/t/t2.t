use strict;
use warnings;

use Data::Dumper;
use Test::Simple tests => 22;
use Number::Format::Calc;

my ($n, $m);

$n = new Number::Format::Calc ( '1.111,5',  -decimal_digits => 2, -thousands_sep => ".", -decimal_point => "," );
$m = new Number::Format::Calc ( '2.222,45', -decimal_digits => 2, -thousands_sep => ".", -decimal_point => "," );

print "arithmetrics with assign\n";
$n += $m;
ok ( $n eq '3.333,95');                                     # 1

$m += 10;
ok ( $m eq '2.232,45');                                     # 2

$m -= 10;
ok ( $m eq '2.222,45');                                     # 3

$m *= -2;
ok ( $m eq '-4.444,9');                                     # 4

$m /= -2;
ok ( $m eq '2.222,45');                                     # 5

print "arithmetic comparisons\n";
ok ( $n >  $m  );                                           # 6
ok ( $n >=  $m );                                           # 7
ok ( $n >=  $n );                                           # 8

ok ( $m <  $n );                                            # 9
ok ( $m <= $n );                                            # 10
ok ( $m <= $m );                                            # 11

ok ( $n == $n );                                            # 11
ok ( $n != $m );                                            # 12

print "arithmetic functions\n";
$m *= -1;
ok ( abs($m) eq '2.222,45');                                # 14
$m *= -1;

ok ( sqrt($m) eq '47,14');                                  # 15
ok ( sin($m) eq '-0,97');                                   # 16
ok ( cos($m) eq '-0,22');                                   # 17
ok ( log($m) eq '7,71');                                    # 18
ok ( exp($m-2200) eq '5.622.262.500,51');                   # 19



print "sorting\n";

my @a ;

for (my $i=1000; $i<2000; $i+=222)
{
    push @a, new Number::Format::Calc($i, -decimal_digits=>1, -decimal_fill => 1, -thousands_sep => ".", -decimal_point => "," );
}
ok ( join ("*", @a) eq "1.000,0*1.222,0*1.444,0*1.666,0*1.888,0" ); #20

@a = sort { $b <=> $a } @a;
ok ( join ("*", @a) eq "1.888,0*1.666,0*1.444,0*1.222,0*1.000,0" ); #21

@a = sort { $a <=> $b } @a;
ok ( join ("*", @a) eq "1.000,0*1.222,0*1.444,0*1.666,0*1.888,0" ); #22
