# NAME

OX::RouteBuilder::REST - OX::RouteBuilder which routes to an action method in a controller class based on HTTP verbs

# VERSION

version 0.004

# SYNOPSIS

    package MyApp;
    use OX;
    use OX::RouteBuilder::REST;

    has thing => (
        is  => 'ro',
        isa => 'MyApp::Controller::Thing',
    );

    router as {
        route '/thing'     => 'REST.thing.root';
        route '/thing/:id' => 'REST.thing.item';
    };


    package MyApp::Controller::Thing;
    use Moose;

    sub root_GET {
        my ($self, $req) = @_;
        ... # return a list if things
    }

    sub root_PUT {
        my ($self, $req) = @_;
        ... # create a new thing
    }

    sub item_GET {
        my ($self, $req, $id) = @_;
        ... # view a thing
    }

    sub item_POST {
        my ($self, $req, $id) = @_;
        ... # update a thing
    }

# DESCRIPTION

This is an [OX::RouteBuilder](https://metacpan.org/pod/OX%3A%3ARouteBuilder) which routes to an action method in a
controller class based on HTTP verbs. It's a bit of a mixture between
[OX::RouteBuilder::ControllerAction](https://metacpan.org/pod/OX%3A%3ARouteBuilder%3A%3AControllerAction) and
[OX::RouteBuilder::HTTPMethod](https://metacpan.org/pod/OX%3A%3ARouteBuilder%3A%3AHTTPMethod).

To enable this RouteBuilder, you need to `use OX::RouteBuilder::REST`
in your main application class.

The `action_spec` should be a string in the form
`"REST.$controller.$action"`, where `$controller` is the name of a
service which provides a controller instance. For each HTTP verb you
want to support you will need to set up an action with the name
`$action_$verb` (e.g. `$action_GET`, `$action_PUT`, etc). If no
matching action-verb-method is found, a 404 error will be returned.

`controller` and `action` will also be automatically added as
defaults for the route, as well as `name` (which will be set to
`"REST.$controller.$action"`).

To generate a link to an action, use `uri_for` with either the name
(eg `"REST.$controller.$action"`), or by passing a HashRef `{
    controller =` $controller, action => $action }>. See `t/test.t`
    for some examples.

# AUTHORS

- Thomas Klausner <domm@plix.at>
- Validad GmbH http://validad.com

# COPYRIGHT AND LICENSE

This software is copyright (c) 2014 - 2021 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
