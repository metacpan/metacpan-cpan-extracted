# NAME

Mojolicious::Plugin::RESTful - A Mojolicious Plugin for RESTful HTTP Actions

# VERSION

version 0.1.4

# SYNOPSIS

In your RESTful application:

    package MyRest;
    use Mojo::Base 'Mojolicious';

    sub startup {
      my $self = shift;
      $self->plugin("RESTful");

      my $routes = $self->routes;
      $routes->restful("Person");
    }

    1;

The following routes should be installed:

    #
    # HTTP    ROUTE             CONTROLLER#ACTION      NAME
    #
    # ------------Collection-------------
    # GET     /people           Person#people_list     "people_list"
    # POST    /people           Person#people_create   "people_create"
    # OPTIONS /people           Person#people_options  "people_options"
    # GET     /people/search    Person#people_search   "people_search"
    # GET     /people/count     Person#people_count    "people_count"
    #
    # -------------Resource--------------
    # GET     /people/:person   Person#person_retrieve "person_retrieve"
    # DELETE  /people/:person   Person#person_delete   "person_delete"
    # PUT     /people/:person   Person#person_update   "person_update"
    # PATCH   /people/:person   Person#person_patch    "person_patch"
    # OPTIONS /people/:person   Person#person_options  "person_options"
    #

For a longer version of parameters:

    #
    # @param name       is the route identity
    # @param controller is the controller class, default is @param name.
    # @param methods    is the methods short name for routes
    #   l: list,     collection
    #   c: create,   collection
    #   r: retrieve, resource
    #   u: update,   resource
    #   d: delete,   resource
    #   p: patch,    resource
    #   o: options,  collection/resource
    #   `lcrudp` is used to detemine to return collection route or resource route.
    #
    # @param root       is the methods for root routes, used only in chained/nested route.
    #   set root as empty('') to disable generating routes in root.
    # @param nonresource
    #   A HASH ref like:  { search => 'get', convert => 'post' }, which is used to generate the nonresource methods.
    #   By default, `restful` short cut will generate `search` and `count` for collection routes.
    #   Set nonresource as empty hash ref ({}) to disable nonresource generating methods.
    #
    # @param under      supposed to support, not funtionally yet.
    #
    # @return           the chained route for collection or resource
    #
    $routes->restful(
      name => 'Person',
      controller => 'Person',
      methods => 'lcrudpo',
      root => 'lcrudpo',
      nonresource => {
        search => 'get',
        count => 'get',
      }
    );

A chained RESTful routes sample:

    $routes->restful('person')->restful('cat'); # name is case-insensitive

generates these routes (person routes not listed):

    #
    # HTTP    ROUTE             CONTROLLER#ACTION      NAME
    #
    # GET     /people/:person/cats      Cat#person_cats_list    person_cats_list
    # POST    /people/:person/cats      Cat#person_cats_create  person_cats_create
    # OPTION  /people/:person/cats      Cat#person_cats_options person_cats_options
    #
    # GET     /people/:person/cats/:cat Cat#person_cat_retrieve person_cat_retrieve
    # PUT     /people/:person/cats/:cat Cat#person_cat_update   person_cat_update
    # DELETE  /people/:person/cats/:cat Cat#person_cat_delete   person_cat_delete
    # PATCH   /people/:person/cats/:cat Cat#person_cat_patch    person_cat_patch
    # OPTION  /people/:person/cats/:cat Cat#person_cat_options  person_cat_options
    # *       /people/:person/cats/:cat (chained)               person
    #
    # GET     /cats                     Cat#cats_list           cats_list
    # POST    /cats                     Cat#cats_create         cats_create
    # OPTION  /cats                     Cat#cats_options        cats_options
    #
    # GET     /cats/:cat                Cat#cat_retrieve        cat_retrieve
    # PUT     /cats/:cat                Cat#cat_update          cat_update
    # DELETE  /cats/:cat                Cat#cat_delete          cat_delete
    # PATCH   /cats/:cat                Cat#cat_patch           cat_patch
    # OPTION  /cats/:cat                Cat#cat_options         cat_options
    # *       /cats/:cat                (chained)               cat
    #

# DESCRIPTION

This is a [Mojolicious](https://metacpan.org/pod/Mojolicious) plugin adding a RESTful CRUD helper `restful`
to [Mojolicious Route](https://metacpan.org/pod/Mojolicious::Routes::Route).

The idea and some code comes from [Mojolicious::Plugin::REST](https://metacpan.org/pod/Mojolicious::Plugin::REST).

The differences are:

- No `under` needed.
- No `types` support.

This is more convenient for me, feel free to use [Mojolicious::Plugin::REST](https://metacpan.org/pod/Mojolicious::Plugin::REST) in your stuff.

# CONFIGRATION

## crud2http

[Mojolicious::Plugin::RESTful](https://metacpan.org/pod/Mojolicious::Plugin::RESTful) will generate the methods by default, set this in
plugin options:

    $app->plugin('RESTful' => {
        crud2http => {
          collection => {
            list => 'get',
            create => 'post',
            options => 'options',
          },
          resource => {
            retrieve => 'get',
            update => 'put',
            delete => 'delete',
            patch => 'patch',
            options => 'options',
          },
        }
      }
    );

### collection

By default [Mojolicious::Plugin::RESTful](https://metacpan.org/pod/Mojolicious::Plugin::RESTful) generate three routes for collections:

- list => 'get'

    This is used to list collection contains.

- create => 'post'

    Create an resource should use 'POST'.

- options => 'options'

    Use this to list options for collection.

### resource

By default [Mojolicious::Plugin::RESTful](https://metacpan.org/pod/Mojolicious::Plugin::RESTful) generate five routes for resources:

- retrieve => 'get'

    To retrieve or read resource from a collection.

- update => 'put'

    To totally update a resource.

- delete => 'delete'

    To delete a resource.

- patch => 'patch',

    To update part of the resource.

- options => 'options'

    To list options for the resource.

# METHODS

## register

Mojolicious plugin register method.

# AUTHOR

Huo Linhe <huolinhe@berrygenomics.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Berry Genomics.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
