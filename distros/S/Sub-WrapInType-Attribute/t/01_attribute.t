use Test2::V0;

use Sub::WrapInType::Attribute;
use Types::Standard -types;
use attributes;
use Sub::Util ();

subtest ':WrapSub' => sub {
    sub foo :WrapSub([Int] => Str) { 'foo' }
    my $foo = \&foo;
    isa_ok $foo, 'Sub::WrapInType';
    is $foo->params, ["Int"];
    is $foo->returns, "Str";
    ok !$foo->is_method;
    is foo(123), 'foo';
    ok dies { foo('aaa') }, 'invalid case';

    ok !attributes::get($foo);
    ok !Sub::Util::prototype($foo);
};

subtest ':WrapMethod' => sub {
    sub bar :WrapMethod([Int] => Str) { 'bar' }
    my $bar = \&bar;
    isa_ok $bar, 'Sub::WrapInType';
    is $bar->params, ["Int"];
    is $bar->returns, "Str";
    ok $bar->is_method;
    is __PACKAGE__->bar(123), 'bar';

    ok !attributes::get($bar);
    ok !Sub::Util::prototype($bar);
};

subtest 'attributes' => sub {
    sub baz :method :WrapSub([Int] => Str) { 'baz' }
    is [attributes::get(\&baz)], ['method'];
};

subtest 'prototype' => sub {
    sub boo($) :WrapSub([Int] => Str) { 'baz' }
    is Sub::Util::prototype(\&boo), '$';
};

done_testing;
