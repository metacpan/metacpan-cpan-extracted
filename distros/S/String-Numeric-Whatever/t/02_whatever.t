use strict;
use warnings;
use Test::More 0.98 tests => 14;

use lib "lib";
use String::Numeric::Whatever;

note 'where value is a Str';
my $str = String::Numeric::Whatever->new("string");
cmp_ok( $str, "==",  "string",  'compared with strings by "=="' );     # 1
cmp_ok( $str, "!=",  "str",     'compared with strings by "!="' );     # 2
cmp_ok( $str, "<",   "strings", 'compared with strings by "<"' );      # 3
cmp_ok( $str, "<=",  "string",  'compared with strings by "<="' );     # 4
cmp_ok( $str, ">",   "strin",   'compared with strings by ">"' );      # 5
cmp_ok( $str, ">=",  "string",  'compared with strings by ">="' );     # 6
cmp_ok( $str, "<=>", "strin",   'compared with strings by "<=>"' );    # 7

note 'where value is an Int';
my $num = String::Numeric::Whatever->new(100);
cmp_ok( $num, "eq",  100, 'compared with numbers by "eq"' );           # 8
cmp_ok( $num, "ne",  0,   'compared with numbers by "ne"' );           # 9
cmp_ok( $num, "lt",  101, 'compared with numbers by "lt"' );           #10
cmp_ok( $num, "le",  100, 'compared with numbers by "le"' );           #11
cmp_ok( $num, "gt",  99,  'compared with numbers by "gt"' );           #12
cmp_ok( $num, "ge",  100, 'compared with numbers by "ge"' );           #13
cmp_ok( $num, "cmp", 99,  'compared with numbers by "cmp"' );          #14

done_testing;
