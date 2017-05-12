use Test::More tests => 19;
use Test::Deep;

SKIP: {
    eval "use Any::Moose 0.05 ()";
    skip "Any::Moose 0.05 required for testing", 19 if $@;

    BEGIN { $ENV{ANY_MOOSE} = 'Mouse' }

    do {
        package MyClass;

        use Any::Moose;
        use Any::Moose 'X::AttributeHelpers';

        has 'config' => (
            metaclass => 'Collection::Hash',
            is        => 'rw',
            isa       => 'HashRef',
            default   => sub { +{} },
            provides  => {
                exists => 'has_config_for',
                get    => 'get_config_for',
                set    => 'set_config_for',
                delete => 'delete_config_for',
                count  => 'num_configs',
                empty  => 'has_configs',
            },
        );

        has 'plugins' => (
            metaclass => 'Collection::Array',
            is        => 'rw',
            isa       => 'ArrayRef',
            default   => sub { [] },
            provides  => {
                push    => 'add_plugins',
                clear   => 'clear_plugins',
                count   => 'num_plugins',
                empty   => 'has_plugins',
                grep    => 'plugins_for',
            },
        );
    };


    my $obj = MyClass->new(
        config  => { foo => 1, bar => 2, baz => 3 },
        plugins => [qw(Foo Bar Baz)],
    );
    isa_ok $obj->meta => 'Mouse::Meta::Class';

    # Collection::Hash
    ok $obj->has_configs, 'hash empty ok';
    is $obj->num_configs => 3, 'hash count ok';

    is $obj->get_config_for('foo') => 1, 'hash get ok';
    is $obj->get_config_for('bar') => 2, 'hash get ok';
    is $obj->get_config_for('baz') => 3, 'hash get ok';

    ok $obj->has_config_for('foo'), 'hash exists ok';
    ok !$obj->has_config_for('quux'), 'hash exists ok, not exist keys';

    $obj->set_config_for(foo => 100);
    is $obj->get_config_for('foo') => 100, 'hash set and get ok';

    $obj->delete_config_for('foo');
    is $obj->num_configs => 2, 'hash delete and count ok';
    ok !$obj->has_config_for('foo'), 'hash delete and exists ok';
    ok $obj->has_config_for('bar'), 'hash delete and exists ok';
    ok $obj->has_config_for('baz'), 'hash delete and exists ok';

    # Collection::Array
    ok $obj->has_plugins, 'array empty ok';
    is $obj->num_plugins => 3, 'array count ok';

    $obj->add_plugins('Quux');
    is $obj->num_plugins => 4, 'array push ok';

    cmp_deeply [ $obj->plugins_for(sub { /^B/ }) ] => [qw(Bar Baz)], 'array grep ok';

    $obj->clear_plugins;
    ok !$obj->has_plugins, 'array clear and empty ok';
    is $obj->num_plugins => 0, 'array clear and count ok';
};
