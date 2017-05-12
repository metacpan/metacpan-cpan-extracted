use Test::More tests => 3;

BEGIN {
	use_ok( 'Module::Starter::Plugin::DirStore' );
	use_ok( 'Module::Starter::Plugin::InlineStore' );
	use_ok( 'Module::Starter::Plugin::ModuleStore' );
}

diag( "Testing Module-Starter-Plugin-SimpleStore $Module::Starter::Plugin::DirStore::VERSION" );
