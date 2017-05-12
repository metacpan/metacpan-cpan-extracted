#!/usr/bin/env perl
use strict;
use lib 't/lib';
use Test::More;

use Rubyish::Class;
use Rubyish::Object;
use Rubyish::Module;
use Cat;

plan tests => 17;

{
    my $obj = Cat->new;

    # diag "The class of an object of Cat is " . $obj->class;
    # diag "The superclass of an object of Cat is " . $obj->superclass;

    ok $obj->is_a("Cat") , "An object of Cat is a Cat";
    ok $obj->is_a("Animal") , "An object of Cat is a Animal";
    ok $obj->is_a("Rubyish::Object") , "An object of Cat is a Rubyish::Object";

    ok !$obj->is_a("Rubyish::Module"), "An object of Cat is not a Rubyish::Module";
    ok !$obj->is_a("Rubyish::Class"),  "An object of Cat is not a Rubyish::Class";
}

{
    # Object is Class. Class is Object.
    TODO : {
        local $TODO = "...";
        ok( Rubyish::Object->is_a( "Rubyish::Class" ) , "Object is a Class");
    }

    ok( Rubyish::Class->is_a( "Rubyish::Object" ) , "Class is a Object");
}

{
    is(Rubyish::Object->class, "Rubyish::Class", "Object.class == Class");
    is(Rubyish::Module->class, "Rubyish::Class", "Module.class == Class");
    is(Rubyish::Class->class, "Rubyish::Class",  "Class.class == Class");

    is(Rubyish::Object->superclass, undef, "Object.sperclass == nil");
    is(Rubyish::Module->superclass, "Rubyish::Object", "Module.superclass == Object");
    is(Rubyish::Class->superclass, "Rubyish::Module", "Class.superclass == Module");
}

{
    my $pet = Cat->new;
    $pet->__send__(name => "oreo");

    is $pet->name, "oreo", "__send__ method works";

    $pet->send(weight => "5kg");

    is $pet->weight, "5kg", "send method also works";
}

{
    my $pet = Cat->new->name("jj");
    my $pig = $pet->clone;
    is ref($pig), "Cat";
    is $pig->name, "jj", "Object#clone works";
}
