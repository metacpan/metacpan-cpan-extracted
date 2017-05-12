#!/usr/bin/env perl

BEGIN {
    $DB::single = 1;
}

use Object::Tiny   ();
use Moose::Tiny    ();
use Foo_Bar_Moose  ();
use Foo_Bar_Moose2 ();
use Foo_Bar_Tiny   ();
use Foo_Bar_Tiny2  ();

use Benchmark ':all';

print "\nBenchmarking constructor plus accessors...\n";

cmpthese(
    1000000,
    {
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
        'moose' => '
        my $object = Foo_Bar_Moose->new( 
            foo => 1,
            bar => 2,
            baz => 4,
         );
        $object->foo;
        $object->bar;
        $object->baz;
    ',
    }
);

sleep 1;
print "\nBenchmarking constructor alone...\n";

cmpthese(
    1000000,
    {
        'tiny' => '
        Foo_Bar_Tiny->new(
            foo => 1,
            bar => 2,
            baz => 4,
        );
    ',
        'moose' => '
        Foo_Bar_Moose->new( 
            foo => 1,
            bar => 2,
            baz => 4,
         );
    ',
    }
);

sleep 1;
print "\nBenchmarking accessors alone...\n";

my $tiny = Foo_Bar_Tiny->new(
    foo => 1,
    bar => 2,
    baz => 4,
);

my $accessor = Foo_Bar_Moose->new(
    {
        foo => 1,
        bar => 2,
        baz => 3,
    }
);

cmpthese(
    1000,
    {
        'tiny' => sub {
            foreach ( 1 .. 1000 ) {
                $tiny->foo;
                $tiny->bar;
                $tiny->baz;
            }
        },
        'moose' => sub {
            foreach ( 1 .. 1000 ) {
                $accessor->foo;
                $accessor->bar;
                $accessor->baz;
            }
        },
    }
);
