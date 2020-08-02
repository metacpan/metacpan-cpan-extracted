use strict;
use warnings;
use Test::More 0.98 tests => 14;

use lib "lib";
use String::Numeric::Whatever;

note 'where value is a Str';
tie my $str, "String::Numeric::Whatever", "string";
cmp_ok( $str, "eq",  "string",  'compared with strings by "eq"' );     # 1
cmp_ok( $str, "ne",  "str",     'compared with strings by "ne"' );     # 2
cmp_ok( $str, "lt",  "strings", 'compared with strings by "lt"' );     # 3
cmp_ok( $str, "le",  "string",  'compared with strings by "le"' );     # 4
cmp_ok( $str, "gt",  "strin",   'compared with strings by "gt"' );     # 5
cmp_ok( $str, "ge",  "string",  'compared with strings by "ge"' );     # 6
cmp_ok( $str, "cmp", "strin",   'compared with strings by "cmp"' );    # 7

note 'where value is an Int';
tie my $num, "String::Numeric::Whatever", 100;
cmp_ok( $num, "==",  100, 'compared with numbers by "=="' );           # 8
cmp_ok( $num, "!=",  0,   'compared with numbers by "!="' );           # 9
cmp_ok( $num, "<",   101, 'compared with numbers by "<"' );            #10
cmp_ok( $num, "<=",  100, 'compared with numbers by "<="' );           #11
cmp_ok( $num, ">",   99,  'compared with numbers by ">"' );            #12
cmp_ok( $num, ">=",  100, 'compared with numbers by ">="' );           #13
cmp_ok( $num, "<=>", 99,  'compared with numbers by "<=>"' );          #14

done_testing;
