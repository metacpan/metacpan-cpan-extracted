#! perl

use strict;
use warnings;

use File::Spec::Functions;
use Test::More tests => 14;

my $module = 'P5NCI::Library';

use_ok( $module ) or exit;

my $lib = P5NCI::Library->new(
	library  => 'nci_test',
	package  => 'NCI',
	path     => 'src',
);

ok( $lib->isa( $module ), 'test library should be loadable' ) or exit;

my  $double_double = $lib->load_function( 'double_double', 'dd' );

my $result         = $double_double->( 1.0 ) - 2.0;
cmp_ok( $result,  '<', 0.0001, 'dd call should work'  );
$result            = $double_double->( 3.14 ) - 6.28;
cmp_ok( $result,  '<', 0.0001, '... for multiple calls'  );

my  $double_int = $lib->install_function( 'double_int', 'ii' );
is( $double_int->( 1 ), 2, 'ii call should work' );
is( $double_int->( 3 ), 6, '... for multiple calls' );

$lib->install_function( 'double_float', 'ff' );
is( NCI::double_float( 1.0 ),   2.0, 'ff call should work'   );
ok( abs( NCI::double_float(0.314) - 0.628) < 0.0001, '... for multiple calls' );

$lib = P5NCI::Library->new( library => 'nci_test' );

$lib->install_function( 'multiply_ints', 'iii' );
is( multiply_ints( 10, 20 ), 200, 'iii call should work'   );
is( multiply_ints(  5,  5 ),  25, '... for multiple calls' );

$lib->install_function( 'change_string', 'tt' );
is( change_string( 'b'   ), "b string\n", 'tt call should work'    );
is( change_string( 'XXX' ), "X string\n", '... for multiple calls' );

$lib->install_function( 'square_root', 'ff' );
is( square_root( 9.0 ), 3.0, 'square_root() should work' );

$lib->install_function( 'make_struct', 'pv' );
$lib->install_function( 'set_x_value', 'vpi' );
$lib->install_function( 'get_x_value', 'ip' );
$lib->install_function( 'free_struct', 'vp' );
$lib->install_function( 'inspect_struct', 'ip' );

my $struct = make_struct();
set_x_value( $struct, 100 );
is( get_x_value( $struct ), 100, 'pointer access should work' );
free_struct( $struct );
