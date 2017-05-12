#!/usr/bin/perl

use lib 't/lib';

use Bar ();
use Baz ();
use Foo ();
use strict;
use Test::More tests => 2055;
use warnings;

# direct subclass.
{
    my $t = Bar->new;
    $t->meta->get_method( 'test_4' )->plan( 4 );
    $t->meta->test_objects( [ $t, ], );
    $t->meta->run_tests;
}

# class hierarchy.
{
    my $t = Foo->new;
    $t->meta->test_objects( [
        Foo->new,
        Bar->new,
        Baz->new,
    ], );
    $t->meta->run_tests;
}

# multiple instances.
{
    my $t = Baz->new;
    $t->meta->test_objects( [
        Foo->new,
        Bar->new,
        Baz->new,

        Foo->new,
        Bar->new,
        Baz->new,

        Bar->new,
        Baz->new,
        Baz->new,
        Baz->new,
    ], );
    $t->meta->run_tests;
}
