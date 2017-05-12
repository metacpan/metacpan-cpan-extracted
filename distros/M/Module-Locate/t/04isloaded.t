use Test::More tests => 6;

use strict;

use Module::Locate qw/is_mod_loaded is_pkg_loaded/;

ok( is_mod_loaded('Test::More'), 'is_mod_loaded() found Test::More' );
ok( is_mod_loaded('Module::Locate'), 'is_mod_loaded() found Module::Locate') ;
ok(!is_mod_loaded('please::dont::exist'), "is_mod_loaded() didn't find non-module");

ok( is_pkg_loaded('Test::More'), 'is_pkg_loaded() found Test::More' );
ok( is_pkg_loaded('Module::Locate'), 'is_pkg_loaded() found Module::Locate' );
ok(!is_pkg_loaded('an::unlikely::pkg'), "is_pkg_loaded() didn't non-package" );
