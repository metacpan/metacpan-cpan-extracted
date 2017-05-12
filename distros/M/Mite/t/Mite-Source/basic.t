#!/usr/bin/perl

use lib 't/lib';
use Test::Mite;

tests "class_for" => sub {
    my $source = sim_source;

    my $foo = $source->class_for("Foo");
    my $bar = $source->class_for("Bar");

    is $foo->source, $source;
    is $bar->source, $source;

    isnt $foo, $bar;
    is $foo, $source->class_for("Foo"), "classes are cached";
    is $bar, $source->class_for("Bar"), "  double check that";

    ok $source->has_class("Foo");
    ok $source->has_class("Bar");
    ok !$source->has_class("Baz");
};

tests "add_classes" => sub {
    my $source = sim_source;

    my @classes = (sim_class, sim_class);
    $source->add_classes( @classes );

    for my $class (@classes) {
        ok $source->has_class($class->name);
        is $class->source, $source;
    }
};

tests "compiled" => sub {
    my $source = sim_source;
    my $compiled = $source->compiled;

    isa_ok $compiled, "Mite::Compiled";
    is $compiled->source, $source;

    is $source->compiled, $compiled, "compiled is cached";
};

tests "project" => sub {
    my $source = sim_source;
    isa_ok $source->project, "Mite::Project";
};

done_testing;
