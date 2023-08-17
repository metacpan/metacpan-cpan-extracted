#!perl

package
    Local::Test::Module1;

use strict;
use warnings;

sub new { my $class = shift; bless {@_}, $class }
sub foo { my $self = shift; $self->{foo} }
sub bar { 5 }

package main;
use strict 'subs', 'vars';
use warnings;
use Test::Exception;
use Test::More 0.98;

use FindBin '$Bin';
use lib "$Bin/lib";

use Module::Load::Util
    'load_module_with_optional_args',
    'instantiate_class_with_optional_args',
    ;

subtest load_module_with_optional_args => sub {
    dies_ok { load_module_with_optional_args("Module::Load::Util::Test::NotFound") } 'not found -> dies';
    dies_ok { load_module_with_optional_args("Module::Load::Util::Test::Module=qux") } 'import() error -> dies';
    dies_ok { load_module_with_optional_args({module=>"Module::Load::Util::Test::Module"}) } 'unknown form -> dies';
    dies_ok { load_module_with_optional_args(["Module::Load::Util::Test::Module", [], undef]) } 'array but not 2 elements (3) -> dies';
    dies_ok { load_module_with_optional_args(["Module::Load::Util::Test::Module", "x"]) } '2-element array: args not hashref/arrayref -> dies';
    dies_ok { load_module_with_optional_args("Foo Bar") } 'invalid syntax in module name -> dies (1)';
    dies_ok { load_module_with_optional_args(["Foo Bar", []]) } 'invalid syntax in module name -> dies (2)';

    subtest "opt:import=0" => sub {
        load_module_with_optional_args({import=>0}, "Module::Load::Util::Test::Module");
        ok(!defined(&{"foo"}));
        ok(!defined(&{"bar"}));
        ok(!defined(&{"baz"}));
        ok(!defined(&{"foo2"}));
        ok(!defined(&{"foo3"}));
        ok(!defined(&{"foo4"}));
        ok(!defined(&{"foo5"}));
        ok(!defined(&{"foo6"}));
    };

    subtest "default import" => sub {
        load_module_with_optional_args("Module::Load::Util::Test::Module");
        ok( defined(&{"foo"}));
        ok(!defined(&{"bar"}));
        ok(!defined(&{"baz"}));
        ok(!defined(&{"foo2"}));
        ok(!defined(&{"foo3"}));
        ok(!defined(&{"foo4"}));
        ok(!defined(&{"foo5"}));
        ok(!defined(&{"foo6"}));
    };

    subtest "import #1" => sub {
        my $res = load_module_with_optional_args("Module::Load::Util::Test::Module=bar,baz");
        is_deeply($res, {module=>"Module::Load::Util::Test::Module", args=>["bar","baz"]});
        ok( defined(&{"bar"}));
        ok( defined(&{"baz"}));
        ok(!defined(&{"foo2"}));
        ok(!defined(&{"foo3"}));
        ok(!defined(&{"foo4"}));
        ok(!defined(&{"foo5"}));
        ok(!defined(&{"foo6"}));
    };

    subtest "import #2 (array form, arrayref)" => sub {
        load_module_with_optional_args(["Module::Load::Util::Test::Module", ["foo2"]]);
        ok( defined(&{"foo2"}));
        ok(!defined(&{"foo3"}));
        ok(!defined(&{"foo4"}));
        ok(!defined(&{"foo5"}));
        ok(!defined(&{"foo6"}));
    };

    subtest "import #2 (array form, hashref)" => sub {
        load_module_with_optional_args(["Module::Load::Util::Test::Module", {"foo3"=>"foo4"}]);
        ok( defined(&{"foo3"}));
        ok( defined(&{"foo4"}));
        ok(!defined(&{"foo5"}));
        ok(!defined(&{"foo6"}));
    };

    subtest "opt:ns_prefix" => sub {
        load_module_with_optional_args({ns_prefix=>"Module::Load::Util"}, "Test::Module=foo5");
        ok( defined(&{"foo5"}));
        ok(!defined(&{"foo6"}));
    };

    subtest "opt:ns_prefixes" => sub {
        load_module_with_optional_args({ns_prefixes=>["Module::Load::Util::Test", "Module::Load::Util::Test2"]}, "Module2=foo6");
        ok( defined(&{"foo6"}));
    };

    subtest "opt:target_package" => sub {
        load_module_with_optional_args({target_package=>"Module::Load::Util::Test::Target"}, "Module::Load::Util::Test::Module=foo5");
        ok( defined(&{"Module::Load::Util::Test::Target::foo5"}));
        ok(!defined(&{"Module::Load::Util::Test::Target::foo6"}));
    };

    subtest "opt:load=0" => sub {
        load_module_with_optional_args({load=>0}, ["Local::Test::Module1" => {}]);
        is(Local::Test::Module1::bar(), 5);
    };
};

subtest instantiate_class_with_optional_args => sub {
    subtest "basics" => sub {
        my $obj = instantiate_class_with_optional_args("Module::Load::Util::Test::Class=arg1,1");
        is(ref $obj, 'Module::Load::Util::Test::Class');
        is($obj->{arg1}, 1);
    };
    subtest "opt:construct=0" => sub {
        my $res = instantiate_class_with_optional_args({construct=>0}, "Module::Load::Util::Test::Class=arg1,1");
        is_deeply($res, {class=>"Module::Load::Util::Test::Class", args=>["arg1", 1]});
    };
    subtest "opt:constructor" => sub {
        my $obj = instantiate_class_with_optional_args({constructor=>"new_array"}, "Module::Load::Util::Test::Class=arg1,1");
        is(ref $obj, 'Module::Load::Util::Test::Class');
        is($obj->[0], "arg1");
        is($obj->[1], "1");
    };
    subtest "opt:load=0" => sub {
        my $obj = instantiate_class_with_optional_args({load=>0}, ["Local::Test::Module1" => {foo=>3}]);
        is(ref $obj, 'Local::Test::Module1');
        is($obj->foo, 3);
    };
};

done_testing;
