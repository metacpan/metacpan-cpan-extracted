#!perl

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use ScriptX ();

subtest _unflatten_import => sub {
    is_deeply([ScriptX::_unflatten_import('')], []);
    is_deeply([ScriptX::_unflatten_import('-Foo')], ['Foo']);
    is_deeply([ScriptX::_unflatten_import('-Foo,-Bar')], ['Foo', 'Bar']);
    is_deeply([ScriptX::_unflatten_import('-Foo,x,y,z,a')], ['Foo'=>{x=>"y",z=>"a"}]);
    is_deeply([ScriptX::_unflatten_import('-Foo,x,y,z,a,-Bar')], ['Foo'=>{x=>"y",z=>"a"}, 'Bar']);
    dies_ok  { ScriptX::_unflatten_import('Foo') };
};

done_testing;
