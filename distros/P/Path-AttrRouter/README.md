# NAME

Path::AttrRouter - Path router for URLs using the attributes

# SYNOPSIS

    package MyController;
    use parent 'Path::AttrRouter::Controller';
    

    sub index :Path { }
    sub index2 :Path :Args(2) { }
    sub index1 :Path :Args(1) { }
    sub index3 :Path :Args(3) { }
    

    package MyController::Args;
    use parent 'Path::AttrRouter::Controller';
    

    sub index :Path :Args(1) {
        my ($self, $arg) = @_;
    }
    

    package MyController::Regex;
    use parent 'Path::AttrRouter::Controller';
    

    sub index :Regex('^regex/(\d+)/(.+)') {
        my ($self, @captures) = @_;
    }
    

    package main;
    use Path::AttrRouter;
    

    my $router = Path::AttrRouter->new( search_path => 'MyController' );
    my $m = $router->match('/args/hoge');
    print $m->action->name, "\n";      # => 'index'
    print $m->action->namespace, "\n"; # => 'args'
    print $m->args->[0], "\n";         # hoge

# DESCRIPTION

Path::AttrRouter is a router class specifying definitions by attributes.

This is mainly used for method dispatching in web application frameworks.

# CONSTRUCTOR

## `my $router = Path::AttrRouter->new(%options)`

Options:

- search\_path  :Str(required)

    Base package namespace of your controller

- action\_class :Str(default: Path::AttrRouter::Action)
- action\_cache :Str(optional)

    `action_cache` path if using action caching

    The action cache is aimed at impermanent environment, e.g. CGI or development.

# METHODS

## `$router->get_action($name:Str, $namespace:Str)`

Returns single action object of `$router->action_class`

## `$router->get_actions($name:Str, $namespace:Str)`

Returns action objects of array which is bunch of actions

## `$router->make_action_cache`

Make action cache

## `$router->match($path:Str $condition:HashRef)`

Returns `Path::AttrRouter::Match`\> object

## `$router->print_table`

Draw dispatching table.

# AUTHOR

Daisuke Murase <typester@cpan.org>

# COPYRIGHT AND LICENSE

Copyright (c) 2009 by KAYAC Inc.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.
