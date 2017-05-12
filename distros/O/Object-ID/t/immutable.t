#!/usr/bin/perl

# Demonstrate that the ID does not change with the object's contents.

use strict;
use warnings;

use Test::More;

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
    my $id = $obj->object_id;
    $obj->{foo} = 42;
    is $obj->object_id, $id, "ID is independent of object content";
}

done_testing;
