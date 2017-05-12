# NAME

Stepford::Grapher - produce graphs of Stepford Dependencies

# VERSION

version 1.01

# SYNOPSIS

From the shell:

    foo@bar:~/steps$ graph-stepford.pl --step-namespace=My::Step --step=My::Step::ExampleStep --output='diagram.png'

Or from code:

    my $grapher = Stepford::Grapher->new(
        step  => 'My::Step::ExampleStep',
        step_namespaces => ['My::Steps'],
        renderer => Stepford::Grapher::Renderer::Graphviz->new(
            output => 'diagram.png',
        ),
    );
    $grapher->run;

# DESCRIPTION

STOP: The most common usage for this module is to use the command line `graph-
stepford.pl` program. You should read the documentation for `graph-stepford.pl`
to see how that works.

# ATTRIBUTES

## step

A string containing the class name of the step you wish to create a diagram for.

Required.

## step\_namespace

An array of strings containing the prefixes of step class names that should
be loaded.  This must contain the step class passed in the `step` parameter.

For example, if you have the steps `My::Step::Foo`, `My::Step::Bar`,
`ThirdyParty::Step::Baz` you would need to pass
`['My::Step','ThirdParty::Step']`

All classes under the prefix will be loaded and it is an error if any of those
classes are do not consume the [Stepford::Role::Step](https://metacpan.org/pod/Stepford::Role::Step) role (this is the same
behavior as Stepford itself.)

Required.

## depth

If this is provided, the graph will not go more than this number of levels
back from the target step.

By default, this is zero and all levels are included.

## renderer

The renderer instance (i.e. an instance of something that consumes the
[Stepford::Grapher::Role::Renderer](https://metacpan.org/pod/Stepford::Grapher::Role::Renderer) role.)

Required.

# METHOD

## run

Use the renderer to render the dependencies graph.

# SUPPORT

Bugs may be submitted through [https://github.com/maxmind/Stepford-Grapher/issues](https://github.com/maxmind/Stepford-Grapher/issues).

# AUTHOR

Mark Fowler <mfowler@maxmind.com>

# CONTRIBUTOR

Dave Rolsky <drolsky@maxmind.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2016 - 2017 by MaxMind, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
