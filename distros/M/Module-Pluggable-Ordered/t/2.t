package Foo;
use Test::More tests => 3;
use lib 't/modules/';
use Module::Pluggable::Ordered search_dirs => ['t/modules'], 
                               search_path => ['Foo'],
                               sub_name    => "test_plugins",
							   except      => ["Foo::One"];


ok(eq_set([Foo->test_plugins],
    ["Foo::Two", "Foo::Three"]), "We have two test plugins");

$main::order = 1;
Foo->call_plugins("mycallback");
is($main::order, 2, "Only two plugins have been called");
