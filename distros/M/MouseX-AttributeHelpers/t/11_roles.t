use Test::More tests => 17;
use Test::Deep;

{
    package Configurable;
    use Mouse::Role;
    use MouseX::AttributeHelpers;

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

    package Pluggable;
    use Mouse::Role;
    use MouseX::AttributeHelpers;

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

    package MyClass;
    use Mouse;

    with 'Configurable', 'Pluggable';
}

my $obj = MyClass->new(
    config  => { foo => 1, bar => 2, baz => 3 },
    plugins => [qw(Foo Bar Baz)],
);

my @methods = qw(
    config plugins
    has_config_for get_config_for set_config_for delete_config_for num_configs has_configs
    add_plugins clear_plugins num_plugins has_plugins plugins_for
);
for my $method (@methods) {
    can_ok $obj => $method;
}

ok $obj->has_configs, 'Collection::Hash "empty" from Role ok';
is $obj->num_configs => 3, 'Collection::Hash "count" from Role ok';

ok $obj->has_plugins, 'Collection::Array "empty" from Role ok';
is $obj->num_plugins => 3, 'Collection::Array "count" from Role ok';
