package Foo;
use Test::More tests => 4;
use lib 't/modules/';
use Module::Pluggable::Ordered search_dirs => ['t/modules'], 
                               search_path => ['Foo'],
                               sub_name    => "test_plugins";
ok(eq_set([Foo->test_plugins],
    ["Foo::One", "Foo::Two", "Foo::Three"]), "We have three test plugins");

$main::order = 1;
Foo->call_plugins("mycallback");
is($main::order, 3, "Only two plugins have been called");
