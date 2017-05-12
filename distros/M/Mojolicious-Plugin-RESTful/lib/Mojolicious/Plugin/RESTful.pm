package Mojolicious::Plugin::RESTful;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Exception;
use Mojo::Util qw(decamelize);
use List::Util qw(any);
use Lingua::EN::Inflect 'PL';

our $VERSION = '0.1.4'; # VERSION
# ABSTRACT: A Mojolicious Plugin for RESTful HTTP Actions



has crud2http => sub {
  {
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
    nonresource => {
      search => 'get',
      count => 'get',
    }
  }
};


sub register {
  my ($self, $app) = @_;
  $app->routes->add_shortcut(
    restful => sub {
      my $route = shift;
      my $prefix = $route->name ? $route->name.'_' : '';

      # params to hash
      my $params = { @_ ? ( ref $_[0] ? %{ $_[0] } : @_ eq 1 ? (name => $_[0]) : @_ ) : () };

      Mojo::Exception->throw('Route name is required in rest') unless defined $params->{name};
      # name setting
      my $route_name = lc $params->{name}; # must be lower case.
      my $route_plural = PL( $route_name );
      my $root_methods = $params->{root} // "lcrudpo";

      # Controller
      my $controller = $params->{controller} // ucfirst($route_name);

      # Non-resource routes
      my $nonresource = $params->{nonresource} // $self->crud2http->{nonresource};

      if (($route ne $route->root) and $root_methods =~/\A[lcrudpo]+\z/) {
        my %methods = map { lc($_) => 1 } split //, $root_methods;
        $route->root->restful(
          name => $route_name,
          methods => $root_methods,
          controller => $controller,
          nonresource => $nonresource,
          root => ''
        );
      }

      my %methods = map { lc($_) => 1 } split //, ($params->{methods} // "lcrudpo");

      foreach my $collection_method (sort keys %{$self->crud2http->{collection}}) {
        next unless $methods{substr($collection_method, 0, 1)};
        my $http = $self->crud2http->{collection}->{$collection_method};
        my $url = "/$route_plural";
        my $action = $prefix . $route_plural . '_' . $collection_method;
        next if $route->find($action);
        $route->route($url)->via($http)->to(
          controller => $controller, action => $action
        )->name($action);
      }

      foreach my $nonresource_method (sort keys %{$nonresource}) {
        my $http = $nonresource->{$nonresource_method};
        my $url = "/$route_plural/$nonresource_method";
        my $action = $prefix . $route_plural . '_' . $nonresource_method;
        next if $route->find($action);
        $route->route($url)->via($http)->to(
          controller => $controller, action => $action
        )->name($action);
      };

      for my $resource_method (sort keys %{$self->crud2http->{resource}}) {
        next unless $methods{substr($resource_method, 0, 1)};
        my $http = $self->crud2http->{resource}->{$resource_method};
        my $url = "/$route_plural/:$route_name";
        my $action = $prefix . $route_name . '_' . $resource_method;
        next if $route->find($action);
        $route->route($url)->via($http)->to(
          controller => $controller, action => $action
        )->name($action);
      }

      # Return chained route.
      if (any { /[rudp]/ } keys %methods) {
        return $route->route("/$route_plural/:$route_name")->name("$prefix$route_name");
      } else {
        return $route->route("/$route_plural")->name("$prefix$route_plural");
      }
    }
  );
}
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::RESTful - A Mojolicious Plugin for RESTful HTTP Actions

=head1 VERSION

version 0.1.4

=head1 SYNOPSIS

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

=head1 DESCRIPTION

This is a L<Mojolicious> plugin adding a RESTful CRUD helper C<restful>
to L<Mojolicious Route|https://metacpan.org/pod/Mojolicious::Routes::Route>.

The idea and some code comes from L<Mojolicious::Plugin::REST>.

The differences are:

=over 4

=item * No C<under> needed.

=item * No C<types> support.

=back

This is more convenient for me, feel free to use L<Mojolicious::Plugin::REST> in your stuff.

=head1 CONFIGRATION

=head2 crud2http

L<Mojolicious::Plugin::RESTful> will generate the methods by default, set this in
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

=head3 collection

By default L<Mojolicious::Plugin::RESTful> generate three routes for collections:

=over 4

=item * list => 'get'

This is used to list collection contains.

=item * create => 'post'

Create an resource should use 'POST'.

=item * options => 'options'

Use this to list options for collection.

=back

=head3 resource

By default L<Mojolicious::Plugin::RESTful> generate five routes for resources:

=over 4

=item * retrieve => 'get'

To retrieve or read resource from a collection.

=item * update => 'put'

To totally update a resource.

=item * delete => 'delete'

To delete a resource.

=item * patch => 'patch',

To update part of the resource.

=item * options => 'options'

To list options for the resource.

=back

=head1 METHODS

=head2 register

Mojolicious plugin register method.

=head1 AUTHOR

Huo Linhe <huolinhe@berrygenomics.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Berry Genomics.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
