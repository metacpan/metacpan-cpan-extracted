use Test2::V0;

use Sub::Meta;

subtest 'exceptions' => sub {
    my $meta = Sub::Meta->new;
    ok dies { $meta->set_subinfo('Foo::Bar', 'baz') }, 'list';
    ok dies { $meta->set_subinfo({}) }, 'hashref';
    ok dies { $meta->set_subinfo(sub {}) }, 'coderef';
};

my @tests = (
    # message               # arguments                 # expected
    'normal'                => ['Foo::Bar', 'baz']      => ['Foo::Bar', 'baz'],
    'one arguments'         => ['Foo::Bar',      ]      => ['Foo::Bar', undef],
    'one arguments/undef'   => ['Foo::Bar', undef]      => ['Foo::Bar', undef],
    'undef stashname'       => [undef, 'foo']           => [undef, 'foo'],
    'empty'                 => []                       => [undef, undef],
    'undef'                 => [undef]                  => [undef, undef],
    'three arguments'       => ['a', 'b', 'c']          => ['a', 'b'],
);

while (@tests) {
    my ($message, $args, $expected) = splice @tests, 0, 3;

    my $meta = Sub::Meta->new;
    subtest $message => sub {
        is $meta->set_subinfo($args), $meta;
        is $meta->subinfo, $expected;
    };
}

done_testing;
