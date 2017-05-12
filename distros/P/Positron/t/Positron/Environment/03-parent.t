#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
    use_ok('Positron::Environment');
}

# parent, immutable, with data
# child, mutable, with data

my $parent = Positron::Environment->new(
    { 'key1' => 'value1', 'key2' => ['value2a','value2b'], 'key3' => 'value3' },
    { immutable => 1 },
);

my $child = Positron::Environment->new(
    { 'key1' => 'value4', 'key2' => ['value5a','value5b'], 'key4' => 'value6' },
    { parent => $parent },
);

is( $parent->get('key1'), 'value1', "Parent value got normally");
ok( !defined($parent->get('key4')), "Parent knows nothing of child's key");
dies_ok { $parent->set('key4'); }  "Parent still immutable";

is( $child->get('key4'), 'value6', "Child value got normally");
is( $child->get('key1'), 'value4', "Value from child for shared key");
is_deeply( $child->get('key2'), ['value5a','value5b'], "Non-scalar from child for shared key");
is( $child->get('key3'), 'value3', "Child gets parent value");

lives_ok { $child->set('key5', 'value7'); } "Child is mutable";
is( $child->get('key5'), 'value7', "Value can be retrieved");
ok (!defined($parent->get('key5')), "Parent knows nothing of new key");

my $grandchild = Positron::Environment->new(
        { 'key1' => 'value8' },
        { parent => $child }
);
is ($grandchild->get('key1'), 'value8', "Grandchild's own value");
is ($grandchild->get('key4'), 'value6', "Grandchild's parent value");
is ($grandchild->get('key3'), 'value3', "Grandchild's grandparent value");


done_testing();

