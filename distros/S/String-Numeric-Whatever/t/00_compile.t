use strict;
use warnings;
use Test::More 0.98 tests => 11;

use lib "lib";

use_ok("String::Numeric::Whatever");    # 1

note 'where value is a Str';
my $str = new_ok( "String::Numeric::Whatever", ["strings"] );    # 2
cmp_ok( $str, "eq", "strings", 'compared with strings by "eq"' );    # 3
cmp_ok( $str, "==", "strings", 'compared with strings by "=="' );    # 4
cmp_ok( $str, "ne", 100,       'compared with strings by "ne"' );    # 5
cmp_ok( $str, "!=", 100,       'compared with Int by "!="' );        # 6

note 'where value is an Int';
my $num = new_ok( "String::Numeric::Whatever", [100] );              # 7
cmp_ok( $num, "eq", "100", 'compared with strings by "eq"' );        # 8
cmp_ok( $num, "eq", 100,   'compared with Int by "eq"' );            # 9
cmp_ok( $num, "==", 100,   'compared with Int Int by "=="' );        #10
cmp_ok( $num, "==", "100", 'compared with strings by "=="' );        #11

done_testing;
