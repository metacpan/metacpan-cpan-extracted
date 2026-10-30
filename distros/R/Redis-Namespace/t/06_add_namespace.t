use strict;
use version 0.77;
use Test::More;

use Redis::Namespace;

# an object that is stringified to the given value
{
    package StringifiedObject;
    use overload '""' => sub { ${$_[0]} }, fallback => 1;
    sub new { my ($class, $value) = @_; bless \$value, $class }
}

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
        ["ns:$obj1", "ns:$obj2"], 'others';
};

subtest 'false values' => sub {
    my $ns = Redis::Namespace->new(redis => bless({},'FakeRedis'), namespace => 'ns');

    is_deeply [$ns->add_namespace('0', 0, '')],
        ['ns:0', 'ns:0', 'ns:'], 'non ref';
    is_deeply [$ns->add_namespace(\'0', \'')],
        [\'ns:0', \'ns:'], 'scalar ref';
    is_deeply [$ns->add_namespace(['0', 0, ''])],
        [['ns:0', 'ns:0', 'ns:']], 'array ref';
    is_deeply [$ns->add_namespace({ '0' => 1, '' => 2 })],
        [{ 'ns:0' => 1, 'ns:' => 2 }], 'hash ref';
    is_deeply [$ns->add_namespace(StringifiedObject->new('0'), StringifiedObject->new(''))],
        ['ns:0', 'ns:'], 'objects';
    is_deeply [$ns->add_namespace(undef)],
        [undef], 'undef';
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
        ["ns;.+\":$obj1", "ns;.+\":$obj2"], 'others';
};

done_testing;

