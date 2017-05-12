#!/usr/bin/perl

BEGIN {
    $DB::single = 1;
}

# For this benchmark, you also need Object::Tiny:
use Object::Tiny          ();

use Object::Tiny::XS      ();
use Class::Accessor::Fast ();
use Foo_Bar_Accessor      ();
use Foo_Bar_Accessor2     ();
use Foo_Bar_Tiny          ();
use Foo_Bar_Tiny2         ();
use Foo_Bar_Tiny_XS       ();
use Foo_Bar_Tiny_XS2      ();

use Benchmark ':all';

print "\nBenchmarking constructor plus accessors...\n";

cmpthese( -2, {
    'tiny' => '
        my $object = Foo_Bar_Tiny->new(
            foo => 1,
            bar => 2,
            baz => 4,
        );
        $object->foo;
        $object->bar;
        $object->baz;
    ',
    'tiny_xs' => '
        my $object = Foo_Bar_Tiny_XS->new(
            foo => 1,
            bar => 2,
            baz => 4,
        );
        $object->foo;
        $object->bar;
        $object->baz;
    ',
    'accessor' => '
        my $object = Foo_Bar_Accessor->new( {
            foo => 1,
            bar => 2,
            baz => 4,
        } );
        $object->foo;
        $object->bar;
        $object->baz;
    ',
} );

sleep 1;
print "\nBenchmarking constructor alone...\n";

cmpthese( -1, {
    'tiny' => '
        Foo_Bar_Tiny->new(
            foo => 1,
            bar => 2,
            baz => 4,
        );
    ',
    'tiny_xs' => '
        Foo_Bar_Tiny_XS->new(
            foo => 1,
            bar => 2,
            baz => 4,
        );
    ',
    'accessor' => '
        Foo_Bar_Accessor->new( {
            foo => 1,
            bar => 2,
            baz => 4,
        } );
    ',
} );

sleep 1;
print "\nBenchmarking accessors alone...\n";

my $tiny = Foo_Bar_Tiny->new(
    foo => 1,
    bar => 2,
    baz => 4,
);

my $tiny_xs = Foo_Bar_Tiny_XS->new(
    foo => 1,
    bar => 2,
    baz => 4,
);


my $accessor = Foo_Bar_Accessor->new( {
    foo => 1,
    bar => 2,
    baz => 3,
} );

cmpthese( -2, {
    'tiny' => sub {
        foreach ( 1 .. 1000 ) {
            $tiny->foo;
            $tiny->bar;
            $tiny->baz;
        }
    },
    'tiny_xs' => sub {
        foreach ( 1 .. 1000 ) {
            $tiny_xs->foo;
            $tiny_xs->bar;
            $tiny_xs->baz;
        }
    },
    'accessor' => sub {
        foreach ( 1 .. 1000 ) {
            $accessor->foo;
            $accessor->bar;
            $accessor->baz;
        }
    },
} );
