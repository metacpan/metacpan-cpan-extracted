#! perl

use strict;
use warnings;

use DynaLoader;
use File::Spec::Functions;

use Test::More tests => 19;
use Test::Exception;

my $module = 'P5NCI::Library';
use_ok( $module ) or exit;

ok( $INC{'P5NCI.pm'}, 'P5NCI::Library should load P5NCI' );

can_ok( $module, 'new' );
throws_ok { $module->new() } qr/No library given/,
	'new() should throw exception without library file named';

throws_ok { $module->new( library => 'not a real lib' ) } qr/No library found/,
	'... or if it cannot locate the library';

push @DynaLoader::dl_library_path, 'src';

my $lib;
my %args = ( library => 'nci_test' );
lives_ok { $lib = $module->new( %args ) }
	'... but should load a real library appropriately';
ok( $lib->{lib}, '... pointing to the real library' );

isa_ok( $lib, $module );

can_ok( $lib, 'load_function' );
throws_ok { $lib->load_function() } qr/No function given/,
	'load_function() should throw an exception without a function name';

throws_ok { $lib->load_function( 'foo' ) } qr/No signature given/,
	'... or without a signature';

throws_ok { $lib->load_function( 'foo', 'invalid' ) }
	qr/Don't understand NCI signature 'invalid'/,
	'... or with an invalid signature';

my $nci_func = $lib->load_function( 'double_int', 'ii' );
is( ref( $nci_func ), 'CODE', '... returning a code ref if it all works' );

can_ok( $lib, 'package' );
is( $lib->package(), 'main', "package() should return default of 'main'" );

$args{package} = 'NCI::Funcs';
$lib = $module->new( %args );
is( $lib->package(), 'NCI::Funcs', '... or package set in constructor' );

can_ok( $lib, 'install_function' );
$nci_func = $lib->install_function( 'double_int', 'ii' );
ok( NCI::Funcs->can( 'double_int' ),
	'install_function() should install the named function into the package' );
is( $nci_func, \&NCI::Funcs::double_int,
	'... returning the installed function' );
