# NAME

MooseX::MojoControllerExposingAttributes - Expose controller attributes to Mojolicious

# VERSION

version 1.000001

# SYNOPSIS

    package MyApp::Controller::Example;
    use MooseX::MojoControllerExposingAttributes;

    ...;

    has some_attribute => (
        is     => 'ro',
        traits => ['ExposeMojo'],
    );

    # then later in a template: <%= ctrl->some_attribute %>

# DESCRIPTION

This module is for advanced use.  `$c`/`$self` are already made available in
templates and are likely sufficient for the majority of use cases.  This module
was created in order to expose [Moose](https://metacpan.org/pod/Moose) attributes in a way where you don't
have to stash them every single time you want to use them.

This class allows you to expose _selected_ Moose attributes from your
Mojolicious controller to your templates by marking them with the `ExposeMojo`
trait.

Using this class in a Perl class does several things:

- It makes the class a subclass of Mojolicious::Controller
- It sets up the class with Moose and Moose::NonMoose
- It applies the extra role and metaclass traits to the class so this works with [Mojolicious::Plugin::ExposeControllerMethod](https://metacpan.org/pod/Mojolicious::Plugin::ExposeControllerMethod)
- It sets up the `ExposeMojo` trait

So rather than declaring your controller class a Moose Mojolicious Controller in
the usual way:

    package MyApp::Controller::Example;
    use Mojo::Base 'Mojolicious::Controller';
    use Moose::NonMoose;
    use Moose;

You should simply say:

    package MyApp::Controller::Example;
    use MooseX::MojoControllerExposingAttributes;

Once you've done that then you can define attributes in the class (or in roles
the class consumes) that are exposed to Mojolicious.

    has some_attribute => (
        is     => 'ro',
        traits => ['ExposeMojo'],
    );

    has some_attribute_with_a_really_long_name => (
       is                => 'ro',
       traits            => ['ExposeMojo'],
       expose_to_mojo_as => 'shorter_name',
    );

In order to get the `ctrl` helper you should make sure you've loaded the
[Mojolicious::Plugin::ExposeControllerMethod](https://metacpan.org/pod/Mojolicious::Plugin::ExposeControllerMethod) plugin somewhere in your
Mojolicious application, typically within the `startup` method itself:

    sub startup {
        my $self = shift;

        $self->plugin('ExposeControllerMethod');

        ...
    }

Then you'll be able to access your attributes from within templates that
are rendered from that controller:

    some attribute: <%= ctrl->some_attribute %>
    some attribute with a really long name: <%= ctrl->shorter_name %>

# BUGS

It would be nice to be able to set the baseclass instead of always
using Mojolicious::Controller

# SEE ALSO

[Mojolicious::Plugin::ExposeControllerMethod](https://metacpan.org/pod/Mojolicious::Plugin::ExposeControllerMethod)

[MooseX::MojoControllerExposingAttributes::Trait::Attribute](https://metacpan.org/pod/MooseX::MojoControllerExposingAttributes::Trait::Attribute)

# AUTHOR

Mark Fowler <mfowler@maxmind.com>

# CONTRIBUTORS

- Dave Rolsky <drolsky@maxmind.com>
- Olaf Alders <oalders@maxmind.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2015 - 2016 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
