use Test::More tests => 5;

my $pkg = 'Module::Locate';

use_ok( $pkg );
ok( defined $pkg->VERSION, 'version has been set');
can_ok( $pkg, 'locate' );

$pkg->import(Cache => 1, 'get_source');
ok( ${"$pkg\::Cache"}, "Cache was enabled in import" );
can_ok( 'main', 'get_source' );
