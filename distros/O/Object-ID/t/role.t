#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

{
    package My::Class;
    use Object::ID;

    sub new {
        my $class = shift;
        my $ref   = shift;

        bless $ref, $class;
    }
}


# Hashref
{
    my $obj = new_ok "My::Class", [{}];
    ok $obj->object_id;
    is $obj->object_id, $obj->object_id;

    my $copy = $obj;
    is $obj->object_id, $copy->object_id;

    my $obj2 = new_ok "My::Class", [{}];
    isnt $obj->object_id, $obj2->object_id;
}


# Coderef
{
    my $obj = new_ok "My::Class", [sub { 42 }];
    ok $obj->object_id;

    my $copy = $obj;
    is $obj->object_id, $copy->object_id;

    my $obj2 = new_ok "My::Class", [sub { 42 }];
    ok $obj2->object_id;
    isnt $obj->object_id, $obj2->object_id;
}


done_testing();
