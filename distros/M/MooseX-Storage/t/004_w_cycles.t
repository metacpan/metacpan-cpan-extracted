use strict;
use warnings;

use Test::More tests => 17;
use Test::Deep;
use Test::Fatal;


# This test demonstrates two things:
#
# - cycles will not work in the default engine
# - you can use a special metaclass to tell MooseX::Storage to skip an attribute

{
    package Circular;
    use Moose;
    use MooseX::Storage;

    with Storage;

    has 'cycle' => (is => 'rw', isa => 'Circular');
}

{
    my $circular = Circular->new;
    isa_ok($circular, 'Circular');

    $circular->cycle($circular);

    like(exception {
        $circular->pack;
    }, qr/^Basic Engine does not support cycles/,
    '... cannot collapse a cycle with the basic engine');
}

{
    my $packed_circular = { __CLASS__ => 'Circular' };
    $packed_circular->{cycle} = $packed_circular;

    like( exception {
        Circular->unpack($packed_circular);
    }, qr/^Basic Engine does not support cycles/,
    '... cannot expand a cycle with the basic engine');
}

{
    package Tree;
    use Moose;
    use MooseX::Storage;

    with Storage;

    has 'node' => (is => 'rw');

    has 'children' => (
        is      => 'ro',
        isa     => 'ArrayRef',
        default => sub {[]}
    );

    has 'parent' => (
        metaclass => 'DoNotSerialize',
        is        => 'rw',
        isa       => 'Tree',
    );

    sub add_child {
        my ($self, $child) = @_;
        $child->parent($self);
        push @{$self->children} => $child;
    }
}

{
    my $t = Tree->new(node => 100);
    isa_ok($t, 'Tree');

    cmp_deeply(
        $t->pack,
        {
            __CLASS__ => 'Tree',
            node      => 100,
            children  => [],
        },
    '... got the right packed version');

    my $t2 = Tree->new(node => 200);
    isa_ok($t2, 'Tree');

    $t->add_child($t2);

    cmp_deeply($t->children, [ $t2 ], '... got the right children in $t');

    is($t2->parent, $t, '... created the cycle correctly');
    isa_ok($t2->parent, 'Tree');

    cmp_deeply(
        $t->pack,
        {
            __CLASS__ => 'Tree',
            node      => 100,
            children  => [
               {
                   __CLASS__ => 'Tree',
                   node      => 200,
                   children  => [],
               }
            ],
        },
    '... got the right packed version (with parent attribute skipped in child)');

    cmp_deeply(
        $t2->pack,
        {
            __CLASS__ => 'Tree',
            node      => 200,
            children  => [],
        },
    '... got the right packed version (with parent attribute skipped)');
}

### this fails with cycle detection on
{   package Double;
    use Moose;
    use MooseX::Storage;
    with Storage;

    has 'x' => ( is => 'rw', isa => 'HashRef' );
    has 'y' => ( is => 'rw', isa => 'HashRef' );
}

{   my $ref = {};

    my $double = Double->new( 'x' => $ref, 'y' => $ref );

    ### currently, the cycle checker's too naive to figure out this is not
    ### a problem, pass an empty hashref to the 2nd test to make sure it
    ### doesn't warn/die
    TODO: {
        local $TODO = "Cycle check is too naive";
        my $pack = eval { $double->pack; };
        ok( $pack,              "Object with 2 references packed" );
        ok( Double->unpack( $pack || {} ),
                                "   And unpacked again" );
    }

    my $pack = $double->pack( engine_traits => [qw/DisableCycleDetection/] );
    ok( $pack,                  "   Object packs when cycle check is disabled");
    ok( Double->unpack( $pack ),
                                "   And unpacked again" );
}

### the same as above, but now done with a trait
### this fails with cycle detection on
{   package DoubleNoCycle;
    use Moose;
    use MooseX::Storage;
    with Storage( traits => ['DisableCycleDetection'] );

    has 'x' => ( is => 'rw', isa => 'HashRef' );
    has 'y' => ( is => 'rw', isa => 'HashRef' );
}

{   my $ref = {};

    my $double = DoubleNoCycle->new( 'x' => $ref, 'y' => $ref );
    my $pack = $double->pack;
    ok( $pack,              "Object packs with DisableCycleDetection trait");
    ok( DoubleNoCycle->unpack( $pack ),
                            "   Unpacked again" );
}
