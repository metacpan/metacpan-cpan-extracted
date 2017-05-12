#!/usr/bin/perl

use lib 't/lib';
use Test::Mite;

use Mite::Project;

tests "class() and source()" => sub {
    my $project = Mite::Project->new;

    my @sources = (sim_source, sim_source);
    $project->add_sources(@sources);

    my @classes = (
        $sources[0]->class_for( "Foo" ),
        $sources[1]->class_for( "Bar" ),
        $sources[1]->class_for( "Baz" )
    );

    cmp_deeply $project->classes, {
        map { ($_->name, $_) } @classes
    };

    for my $class (@classes) {
        is $project->class($class->name), $class;
    }

    for my $source (@sources) {
        is $project->source($source->file), $source;
    }
};

done_testing;
