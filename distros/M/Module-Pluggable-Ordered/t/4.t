package Foo;
use Test::More tests => 1;
use lib 't/modules/';
use Module::Pluggable::Ordered search_dirs => ['t/modules'], 
                               search_path => ['Foo'],
                               sub_name    => "test_plugins";
is_deeply(
		[Foo->test_plugins_ordered],
		["Foo::Two", "Foo::Three", "Foo::One"],
		'Three test pluggins in order'
	);

