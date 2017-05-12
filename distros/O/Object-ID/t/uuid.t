#!/usr/bin/perl

# Test the optional object_uuid

use strict;
use warnings;

use Module::Build;
use Test::More;

plan skip_all => "Data::UUID not available for object_uuid" unless do {
    my $build = Module::Build->resume;
    $build->feature("object_uuid");
};

{
    package My::Class;
    use Object::ID;

    sub new {
        my $class = shift;
        bless {}, $class;
    }
}

{
    my $obj = new_ok "My::Class";
    ok $obj->object_uuid;

    my $copy = $obj;
    is $obj->object_uuid, $copy->object_uuid;

    my $obj2 = new_ok "My::Class";
    isnt $obj->object_uuid, $obj2->object_uuid;
}

done_testing;
