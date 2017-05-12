use strict;
use Test::Simple tests => 66;
use Number::Format::Calc;

my ($n, $m);

$n = new Number::Format::Calc ( '1.111,5'  , -thousands_sep=>".", -decimal_point=>",", decimal_digits=>99 );
$m = new Number::Format::Calc ( '2.222,45' , -thousands_sep=>".", -decimal_point=>",", decimal_digits=>99 );

print "addition/precision 999/no trailing zeroes:\n";
ok ( $n + $m eq '3.333,95');                                     # 1
ok ( $n + 10 eq '1.121,5');                                      # 2
ok ( $n + 10.1234 eq '1.121,6234');                              # 3
ok ( $n + 0 eq '1.111,5');                                       # 4
ok ( ++$n eq '1.112,5');                                         # 5
$n++;
ok ( $n eq '1.113,5');                                           # 6

print "substraction/precision 999/no trailing zeroes:\n";
$n--;
ok ( $n eq '1.112,5');                                           # 7
ok ( --$n eq '1.111,5');                                         # 8
ok ( $n - $m eq '-1.110,95');                                    # 9
ok ( $m - $n eq '1.110,95');                                     # 10
ok ( $n - 10 eq '1.101,5');                                      # 11
ok ( $n - 10.1234 eq '1.101,3766');                              # 12

print "multiplication/precision 999/no trailing zeroes:\n";
ok ( $n * $m eq '2.470.253,175');                                # 13
ok ( $n * 10 eq '11.115');                                       # 14
ok ( $n * 10.1 eq '11.226,15');                                  # 15
ok ( $n * 0 eq '0');                                             # 16

print "division/precision 999/no trailing zeroes:\n";
ok ( $n / $m eq '0,500123737316925');                            # 17
ok ( $n / 10.1 eq '110,049504950495');                           # 18

print "power/precision 999/no trailing zeroes:\n";
ok ( $n ** 2 eq $n * $n);                                        # 19
ok ( $n ** 3 eq $n * $n  * $n);                                  # 20
ok ( $n ** 0.5 eq '33,3391661563393' );                          # 21

$n = new Number::Format::Calc ( '1.111,501' , -thousands_sep=>".", -decimal_point=>",", decimal_digits=>2 );
$m = new Number::Format::Calc ( '2.222,452' , -thousands_sep=>".", -decimal_point=>",", decimal_digits=>2 );

print "addition/precision 2/no trailing zeroes:\n";
ok ( $n + $m eq '3.333,95');                                     # 22
ok ( $n + 10 eq '1.121,5');                                      # 23
ok ( $n + 10.1234 eq '1.121,62');                                # 24
ok ( $n + 0 eq '1.111,5');                                       # 25
ok ( ++$n eq '1.112,5');                                         # 26
$n++;
ok ( $n eq '1.113,5');                                           # 27

print "substraction/precision 2/no trailing zeroes:\n";
$n--;
ok ( $n eq '1.112,5');                                           # 28
ok ( --$n eq '1.111,5');                                         # 29
ok ( $n - $m eq '-1.110,95');                                    # 30
ok ( $m - $n eq '1.110,95');                                     # 31
+
ok ( $n - 10 eq '1.101,5');                                      # 32
ok ( $n - 10.1234 eq '1.101,38');                                # 33

print "multiplication/precision 2/no trailing zeroes:\n";
ok ( $n * $m eq '2.470.257,62');                                 # 34
ok ( $n * 10 eq '11.115,01');                                    # 35
ok ( $n * 10.124 eq '11.252,84');                                # 36 -> 11.252,836
ok ( $n * 0 eq '0');                                             # 37

print "division/precision 2/no trailing zeroes:\n";
ok ( $n / $m eq '0,5');                                          # 38
ok ( $n / 10.1 eq '110,05');                                     # 39

print "power/precision 2/no trailing zeroes:\n";
ok ( $n ** 2 eq $n * $n);                                        # 40
ok ( $n ** 3 eq $n * $n  * $n);                                  # 41
ok ( $n ** 0.5 eq '33,34' );                                     # 42

$n = new Number::Format::Calc ( '1.111,501' , -thousands_sep=>".", -decimal_point=>",", decimal_digits=>2, decimal_fill=>1  );
$m = new Number::Format::Calc ( '2.222,452' , -thousands_sep=>".", -decimal_point=>",", decimal_digits=>2, decimal_fill=>1 );

print "addition/precision 2/trailing zeroes:\n";
ok ( $n + $m eq '3.333,95');                                     # 43
ok ( $n + 10 eq '1.121,50');                                     # 44
ok ( $n + 10.1234 eq '1.121,62');                                # 45
ok ( $n + 0 eq '1.111,50');                                      # 46
ok ( ++$n eq '1.112,50');                                        # 47
$n++;
ok ( $n eq '1.113,50');                                          # 48

print "substraction/precision 2/trailing zeroes:\n";
$n--;
ok ( $n eq '1.112,50');                                          # 49
ok ( --$n eq '1.111,50');                                        # 50
ok ( $n - $m eq '-1.110,95');                                    # 51
ok ( $m - $n eq '1.110,95');                                     # 52
+
ok ( $n - 10 eq '1.101,50');                                     # 53
ok ( $n - 10.1234 eq '1.101,38');                                # 54

print "multiplication/precision 2/trailing zeroes:\n";
ok ( $n * $m eq '2.470.257,62');                                 # 55
ok ( $n * 10 eq '11.115,01');                                    # 56
ok ( $n * 10.124 eq '11.252,84');                                # 57-> 11.252,836
ok ( $n * 0 eq '0,00');                                          # 58

print "division/precision 2/trailing zeroes:\n";
ok ( $n / $m eq '0,50');                                         # 59
ok ( $n / 10.1 eq '110,05');                                     # 60

print "power/precision 2/trailing zeroes:\n";
ok ( $n ** 2 eq $n * $n);                                        # 61
ok ( $n ** 3 eq $n * $n  * $n);                                  # 62
ok ( $n ** 0.5 eq '33,34' );                                     # 63

print "modulo/precision 2/trailing zeroes:\n";
ok ($n % $m eq "1.111,00" );                                     # 64
ok ($n % 9 eq "4,00" );                                          # 65
ok ($n % $n eq "0,00" );                                         # 66

