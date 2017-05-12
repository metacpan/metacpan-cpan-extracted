# NAME

Mojolicious::Plugin::ExposeControllerMethod - expose controller method

# SYNOPSIS

    # in your app
    $app->plugin('ExposeControllerMethod');

    # Then in a template:
    Hi <%= ctrl->name %>

# DESCRIPTION

This module is for advanced use.  `$c`/`$self` are already made available in
templates and are likely sufficient for the majority of use cases.  This module
was created in order to expose [Moose](https://metacpan.org/pod/Moose) attributes in a way where you don't
have to stash them every single time you want to use them.

This module exposes _selected_ methods from the current controller to
Mojolicious templates via the `ctrl` helper.

In order to expose methods to Mojolicious templates your controller must
implement the `controller_method_name` method which will be passed the name of
the method Mojolicious wishes to call on the controller.  This method should
return either false (if the method cannot be called), or the name the method
that should be called ( which is probably the same as the name of the method
passed in.)

For example:

    package MyApp::Controller::Example;
    use Mojo::Base 'Mojolicious::Controller';

    sub name           { return "Mark Fowler" }
    sub any_other_name { return "Still smells sweet" }
    sub reverse        { my $self = shift; return scalar reverse join '', @_ }

    sub controller_method_name {
        my $self = shift;
        my $what = shift;

        return $what if $what =~ /\A(test1|reverse)\z/;
        return 'any_other_name' if $what eq 'rose';
        return;
    }

    ...

The results of `controller_method_name` are expected to be consistent for
a given Mojolicious Controller class for a given method name (this module
is optimized on this assumption, caching method name calculations.)

# SUPPORT

Please report all issues with this code using the GitHub issue tracker at
[https://github.com/maxmind/Mojolicious-Plugin-ExposeControllerMethod/issues](https://github.com/maxmind/Mojolicious-Plugin-ExposeControllerMethod/issues).

# SEE ALSO

[MooseX::MojoControllerExposingAttributes](https://metacpan.org/pod/MooseX::MojoControllerExposingAttributes) - uses this mechanism to expose
attributes marked with a trait from Moose Mojolicious controllers

[Mojolicious](https://metacpan.org/pod/Mojolicious)
