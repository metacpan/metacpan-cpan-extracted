package Foo;
use Test::More tests => 3;
use lib 't/modules/';
use Module::Pluggable::Ordered search_dirs => ['t/modules'], 
                               search_path => ['Foo'],
                               sub_name    => "test_plugins",
							   only        => ["Foo::Two"];
ok(eq_set([Foo->test_plugins],
    ["Foo::Two"]), "We have one test plugin");

$main::order = 1;
Foo->call_plugins("mycallback");
is($main::order, 2, "Only 1 plugin have been called");
