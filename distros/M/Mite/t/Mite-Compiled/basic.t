#!/usr/bin/perl

use lib 't/lib';
use Test::Mite;

tests "new" => sub {
    my $source   = sim_source;
    my $compiled = $source->compiled;

    is $compiled->file, $source->file . '.mite.pm';
};

tests "classes" => sub {
    my $source   = sim_source;
    my $foo = $source->class_for("Foo");
    my $bar = $source->class_for("Bar");

    my $compiled = $source->compiled;

    is_deeply [sort values %{$compiled->classes}], [sort($foo, $bar)];
};

tests "write" => sub {
    my $source   = sim_source;
    my $foo = $source->class_for("Foo");
    my $bar = $source->class_for("Bar");

    my $compiled = $source->compiled;

    $compiled->write;
    require $compiled->file;
    new_ok "Foo";
    new_ok "Bar";

    $compiled->remove;
    ok !-e $compiled->file;
};

done_testing;
