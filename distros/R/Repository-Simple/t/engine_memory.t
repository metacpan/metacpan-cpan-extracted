# vim: set ft=perl :

use strict;
use warnings;

use Test::More tests => 74;

use Repository::Simple;
use Repository::Simple::Permission;

use IO::Scalar;

use_ok('Repository::Simple::Engine::Memory');

use Repository::Simple::Engine qw( $NODE_EXISTS $PROPERTY_EXISTS );

my %settings = (
    root => {
        node_type => 'mem:generic',
        properties => {
            'foo' => {
                property_type => 'mem:generic-property',
                value => 1,
            },
            'bar' => {
                property_type => 'mem:generic-property',
                value => 2,
            },
        },
        nodes => {
            'baz' => {
                node_type => 'mem:generic',
                nodes => {
                    'qux' => {
                        node_type => 'mem:generic',
                        properties => {
                            quux => {
                                property_type => 'mem:generic-property',
                                value => 3,
                            },
                        },
                    },
                },
            },
        },
    },
);

# Test construction
my $engine = Repository::Simple::Engine::Memory->new(%settings);
ok($engine, 'new');
isa_ok($engine, 'Repository::Simple::Engine', 'engine isa engine');
isa_ok($engine, 'Repository::Simple::Engine', 'engine isa memory');

# Test methods
can_ok($engine, qw(
    new
    node_type_named
    property_type_named
    path_exists
    node_type_of
    property_type_of
    nodes_in
    properties_in
    get_scalar
    set_scalar
    get_handle
    set_handle
    namespaces
    has_permission
    save_property
));

# Test mem:generic-node node type
my $mem_node_type = $engine->node_type_named('mem:generic-node');
ok($mem_node_type, 'mem:generic-node');
isa_ok($mem_node_type, 'Repository::Simple::Type::Node', 
    'mem:generic-node isa node type');
is($mem_node_type->name, 'mem:generic-node', 'mem:generic-node name');
is_deeply([ $mem_node_type->super_types ], [ ], 'mem:generic-node isa [ ]');
is_deeply({ $mem_node_type->node_types }, {
        '*' => [ 'mem:generic-node' ],
    },
    'mem:generic-node * node type'
);
is_deeply({ $mem_node_type->property_types }, {
        '*' => [ 'mem:generic-property' ],
    },
    'mem:generic-node * property type'
);
ok(!$mem_node_type->auto_created, 'mem:generic-node auto_created');
ok($mem_node_type->updatable, 'mem:generic-node updatable');
ok($mem_node_type->removable, 'mem:generic-node removable');
undef $mem_node_type;

# Test mem:generic-property property type
my $mem_property_type = $engine->property_type_named('mem:generic-property');
ok($mem_property_type, 'mem:generic-property');
isa_ok($mem_property_type, 'Repository::Simple::Type::Property', 
    'mem:generic-property isa');
is($mem_property_type->name, 'mem:generic-property', 'mem:generic-property name');
is($mem_property_type->value_type->name, 'rs:scalar', 
    'mem:generic-property value_type');
ok(!$mem_property_type->auto_created, 'mem:generic-property auto_created');
ok($mem_property_type->updatable, 'mem:generic-property updatable');
ok($mem_property_type->removable, 'mem:generic-property removable');
undef $mem_property_type;

my %paths = (
    '/'             => $settings{root},
    '/foo'          => $settings{root}{properties}{foo},
    '/bar'          => $settings{root}{properties}{bar},
    '/baz'          => $settings{root}{nodes}{baz},
    '/baz/qux'      => $settings{root}{nodes}{baz}{nodes}{qux},
    '/baz/qux/quux' 
        => $settings{root}{nodes}{baz}{nodes}{qux}{properties}{quux},
);

for my $path (keys %paths) {
    my $info = $paths{$path};

    # Test nodes
    if (defined $info->{node_type}) {

        # Test has_permission($ADD_NODE) on node
        ok($engine->has_permission($path."/blah", $ADD_NODE));
        
        # Test has_permission($REMOVE) on node
        ok($engine->has_permission($path, $REMOVE));

        # Test has_permission($READ) on node
        ok($engine->has_permission($path, $READ));

        # Test path_exists() on node
        is($engine->path_exists($path), $NODE_EXISTS, "path_exists($path)");

        # Test node_type_of()
        my $node_type = $engine->node_type_of($path);
        is_deeply($node_type, $engine->node_type_named($info->{node_type}),
            "node_type_of($path)");

        # Test properties_in()
        is_deeply(
            [ sort $engine->properties_in($path) ],
            [ sort keys %{ $info->{properties} } ],
            "properties_in($path)");

        # Test nodes_in()
        is_deeply(
            [ sort $engine->nodes_in($path) ],
            [ sort keys %{ $info->{nodes} } ],
            "nodes_in($path)");
    }

    # Test properties
    else {

        # Test has_permission($SET_PROPERTY) on property
        ok($engine->has_permission($path, $SET_PROPERTY));

        # Test has_permission($REMOVE) on property
        ok($engine->has_permission($path, $REMOVE));

        # Test has_permission($READ) on property
        ok($engine->has_permission($path, $READ));
        
        # Test path_exists() on property
        is($engine->path_exists($path), $PROPERTY_EXISTS, "path_exists($path)");

        # Test property_type_of()
        my $property_type = $engine->property_type_of($path);
        is_deeply(
            $property_type, 
            $engine->property_type_named($info->{property_type}),
            "property_type_of($path)");

        # Test get_scalar() and get_handle()
        my $scalar = $engine->get_scalar($path);
        my $handle = $engine->get_handle($path);
        is($scalar, join '', <$handle>);

        # Some test strings we can use
        my $test_str1 =
            qq(Is grandma there?\n);
        my $test_str2 =
            qq(Can you bring me my chapstick?\n);
        my $test_str3 =
            qq(But my lips hurt real bad!\n);

        # Remember the old value
        my $old_value = $engine->get_scalar($path);

        # Test set_scalar()
        $engine->set_scalar($path, $test_str1);
        $engine->save_property($path);
        is($engine->get_scalar($path), $test_str1);

        # Test write with get_handle()
        my $fh = $engine->get_handle($path, ">");
        print $fh $test_str2;
        $engine->save_property($path);
        is($engine->get_scalar($path), $test_str2);

        # Test set_handle()
        $fh = IO::Scalar->new(\$test_str3);
        $engine->set_handle($path, $fh);
        $engine->save_property($path);
        is($engine->get_scalar($path), $test_str3);

        # Return to normal
        $engine->set_scalar($path, $old_value);
        is($engine->get_scalar($path), $old_value);
    }
}

ok(!$engine->path_exists('/foobar'), '!path_exists');

# Test namespaces()
is_deeply($engine->namespaces, {
    mem => 'http://contentment.org/Repository/Simple/Engine/Memory'
});
