use strict;
use version 0.77;
use Test::More;

use Redis::Namespace;

subtest 'simple' => sub {
    my $ns = Redis::Namespace->new(redis => bless({},'FakeRedis'), namespace => 'ns');

    is_deeply [$ns->add_namespace('foo', 'bar')],
        ['ns:foo', 'ns:bar'], 'non ref';
    is_deeply [$ns->add_namespace(\'foo', \'bar')],
        [\'ns:foo', \'ns:bar'], 'scalar ref';
    is_deeply [$ns->add_namespace(['foo', 'bar'], ['baz'])],
        [['ns:foo', 'ns:bar'], ['ns:baz']], 'array ref';
    is_deeply [$ns->add_namespace({ foo => 1, bar => 2 }, { baz => 3 })],
        [{ 'ns:foo' => 1, 'ns:bar' => 2}, { 'ns:baz' => 3 }], 'hash ref';

    my ($obj1, $obj2) = (
        bless({},'SomeClass'),
        bless({},'SomeClass'),
    );
    is_deeply [$ns->add_namespace($obj1, $obj2)],
        [$obj1, $obj2], 'others';
};

subtest 'included special chars' => sub {
    my $ns = Redis::Namespace->new(redis => bless({},'FakeRedis'), namespace => 'ns;.+"');

    is_deeply [$ns->add_namespace('foo', 'bar')],
        ['ns;.+":foo', 'ns;.+":bar'], 'non ref';
    is_deeply [$ns->add_namespace(\'foo', \'bar')],
        [\'ns;.+":foo', \'ns;.+":bar'], 'scalar ref';
    is_deeply [$ns->add_namespace(['foo', 'bar'], ['baz'])],
        [['ns;.+":foo', 'ns;.+":bar'], ['ns;.+":baz']], 'array ref';
    is_deeply [$ns->add_namespace({ foo => 1, bar => 2}, { baz => 3 })],
        [{ 'ns;.+":foo' => 1, 'ns;.+":bar' => 2}, { 'ns;.+":baz' => 3 }], 'hash ref';

    my ($obj1, $obj2) = (
        bless({},'SomeClass'),
        bless({},'SomeClass'),
    );
    is_deeply [$ns->add_namespace($obj1, $obj2)],
        [$obj1, $obj2], 'others';
};

done_testing;

