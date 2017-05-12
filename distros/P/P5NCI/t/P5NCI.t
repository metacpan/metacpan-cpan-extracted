#! perl

use strict;
use warnings;

use File::Spec::Functions;
use Test::More tests => 12;

use_ok( 'P5NCI' ) or exit;

P5NCI::add_path( 'src' );

my $lib_path       = P5NCI::find_lib( 'nci_test' );
my $double_lib     = P5NCI::load_lib( $lib_path  );
ok( $double_lib, 'test library should be loadable' ) or exit;
my  $double_double = P5NCI::load_func( $double_lib, 'double_double', 'dd' );
my $result         = $double_double->( 1.0 ) - 2.0;
cmp_ok( $result,  '<', 0.0001, 'dd call should work'  );
$result            = $double_double->( 3.14 ) - 6.28;
cmp_ok( $result,  '<', 0.0001, '... for multiple calls'  );

my  $double_int = P5NCI::load_func( $double_lib, 'double_int', 'ii' );
is( $double_int->( 1 ), 2, 'ii call should work' );
is( $double_int->( 3 ), 6, '... for multiple calls' );

my  $double_float = P5NCI::load_func( $double_lib, 'double_float', 'ff' );
is( $double_float->( 1.0 ),   2.0, 'ff call should work'   );
ok( abs( $double_float->(0.314) - 0.628) < 0.00001, '... for multiple calls' );

my  $multiply_ints = P5NCI::load_func( $double_lib, 'multiply_ints', 'iii' );
is( $multiply_ints->( 10, 20 ), 200, 'iii call should work'   );
is( $multiply_ints->(  5,  5 ),  25, '... for multiple calls' );

my $change_string = P5NCI::load_func( $double_lib, 'change_string', 'tt' );
is( $change_string->( 'a' ), "a string\n", 'tt call should work' );
is( $change_string->( '1' ), "1 string\n", '... for multiple calls' );
