use Modern::Perl; # strict, warnings etc.;
package Mojolicious::Plugin::RESTRoutes;
# ABSTRACT: routing helper for RESTful operations
# VERSION
$Mojolicious::Plugin::RESTRoutes::VERSION = '1.0.0';
use Mojo::Base 'Mojolicious::Plugin';

#pod =encoding utf8
#pod
#pod =head1 DESCRIPTION
#pod
#pod This Mojolicious plugin adds a routing helper for
#pod L<REST|http://en.wikipedia.org/wiki/Representational_state_transfer>ful
#pod L<CRUD|http://en.wikipedia.org/wiki/Create,_read,_update_and_delete>
#pod operations via HTTP to the app.
#pod
#pod The routes are intended, but not restricted to be used by AJAX applications.
#pod
#pod =cut

use Lingua::EN::Inflect qw/PL/;
use Mojo::Util qw( camelize );

#pod =method register
#pod
#pod Adds the routing helper (called by Mojolicious).
#pod
#pod =cut
sub register {
    my ($self, $app) = @_;

#pod =mojo_short rest_routes
#pod
#pod Can be used to easily generate the needed RESTful routes for a resource.
#pod
#pod     my $r = $self->routes;
#pod     my $userroute = $r->rest_routes(name => 'user');
#pod
#pod     # Installs the following routes (given that $r->namespaces == ['My::Mojo']):
#pod     #    GET /users                      --> My::Mojo::User::rest_list()
#pod     #   POST /users                      --> My::Mojo::User::rest_create()
#pod     #    GET /users/:userid              --> My::Mojo::User::rest_show()
#pod     #    PUT /users/:userid              --> My::Mojo::User::rest_update()
#pod     # DELETE /users/:userid              --> My::Mojo::User::rest_remove()
#pod
#pod I<Please note>: the english plural form of the given C<name> attribute will be
#pod used in the route, i.e. "users" instead of "user". If you want to specify
#pod another string, see parameter C<route> below.
#pod
#pod You can also chain C<rest_routes>:
#pod
#pod     $userroute->rest_routes(name => 'hat', readonly => 1);
#pod
#pod     # Installs the following additional routes:
#pod     #    GET /users/:userid/hats         --> My::Mojo::Hat::rest_list()
#pod     #    GET /users/:userid/hats/:hatid  --> My::Mojo::Hat::rest_show()
#pod
#pod The target controller has to implement the following methods:
#pod
#pod =for :list
#pod * C<rest_list>
#pod * C<rest_create>
#pod * C<rest_show>
#pod * C<rest_update>
#pod * C<rest_remove>
#pod
#pod B<Parameters to control the route creation>
#pod
#pod =over
#pod
#pod =item name
#pod
#pod The name of the resource, e.g. a "user", a "book" etc. This name will be used to
#pod build the route URL as well as the controller name (see example above).
#pod
#pod =item readonly (optional)
#pod
#pod If set to 1, no create/update/delete routes will be created
#pod
#pod =item controller (optional)
#pod
#pod Default behaviour is to use the resource name to build the CamelCase controller
#pod name (this is done by L<Mojolicious::Routes::Route>). You can change this by
#pod directly specifying the controller's name via the I<controller> attribute.
#pod
#pod Note that you have to give the real controller class name (i.e. CamelCased or
#pod whatever you class name looks like) including the full namespace.
#pod
#pod     $r->rest_routes(name => 'user', controller => 'My::Mojo::Person');
#pod
#pod     # Installs the following routes:
#pod     #    GET /users         --> My::Mojo::Person::rest_list()
#pod     #    ...
#pod
#pod =item route (optional)
#pod
#pod Specify a name for the route, i.e. prevent automatic usage of english plural
#pod form of the C<name> parameter as the route component.
#pod
#pod     $r->rest_routes(name => 'angst', route => 'aengste');
#pod
#pod     # Installs the following routes (given that $r->namespaces == ['My::Mojo']):
#pod     #    GET /aengste       --> My::Mojo::Angst::rest_list()
#pod
#pod =back
#pod
#pod B<How to retrieve the parameters / IDs>
#pod
#pod There are two ways to retrieve the IDs given by the client in your C<rest_show>,
#pod C<rest_update> and C<rest_remove> methods.
#pod
#pod Example request: C<GET /users/5/hats/no9>
#pod
#pod 1. New way: the stash entry C<fm.ids> holds a hash with all ids:
#pod
#pod     package My::Mojo::Hats;
#pod     use Mojo::Base 'Mojolicious::Controller';
#pod
#pod     sub rest_show {
#pod         use Data::Dump qw(dump);
#pod         print dump($self->stash('fm.ids'));
#pod
#pod         # { user => 5, hat => 'no9' }
#pod     }
#pod
#pod 2. Old way: for each resource there will be a parameter C<***id>, e.g.:
#pod
#pod     package My::Mojo::Hat;
#pod     use Mojo::Base 'Mojolicious::Controller';
#pod
#pod     sub rest_show {
#pod         my ($self) = @_;
#pod         my $user = $self->param('userid');
#pod         my $hat = $self->param('hatid');
#pod         return $self->render(text => "$userid, $hatid");
#pod
#pod         # text: "5, no9"
#pod     }
#pod
#pod Furthermore, the parameter C<idname> holds the name of the last ID in the route:
#pod
#pod     package My::Mojo::Hat;
#pod     use Mojo::Base 'Mojolicious::Controller';
#pod
#pod     sub rest_show   {
#pod         my $p_name = $self->param('idname');
#pod         my $id = $self->param($p_name);
#pod         return $self->render(text => sprintf("%s = %s", $p_name, $id || ''));
#pod
#pod         # text: "hatid = 5"
#pod     }
#pod
#pod =cut
    # For the following TODOs also see http://pastebin.com/R9zXrtCg
    # TODO Add GET /users/new            --> rest_create_user_form
    # TODO Add GET /users/:userid/edit   --> rest_edit_user_form
    # TODO Add GET /users/:userid/delete --> rest_delete_user_form
    # TODO Add GET /users/search         --> rest_search_user_form
    # TODO Add PUT /users/search/:term   --> rest_search_user_form (submit/execution)
    $app->routes->add_shortcut(
        rest_routes => sub {
            my $r = shift;
            my $params = { @_ ? (ref $_[0] ? %{ $_[0] } : @_) : () };

            my $name = $params->{name} or die "Parameter 'name' missing";
            my $readonly = $params->{readonly} || 0;
            my $controller = $params->{controller} || $name;
            my $route_part = $params->{route} || PL($name, 10); # build english plural form

            $app->log->info("Creating REST routes for resource '$name' (controller: ".camelize($controller).")");

            #
            # Generate "/$name" route, handled by controller $name
            #
            my $resource = $r->route("/$route_part")->to(controller => $controller);

            # GET requests - lists the collection of this resource
            $resource->get->to('#rest_list')->name("list_$route_part");
            $app->log->debug("    GET ".$r->to_string."/$route_part   (rest_list)");

            if (!$readonly) {
                # POST requests - creates a new resource
                $resource->post->to('#rest_create')->name("create_$name");
                $app->log->debug("   POST ".$r->to_string."/$route_part   (rest_create)");
            };

            #
            # Generate "/$name/:id" route, also handled by controller $name
            #

            # resource routes might be chained, so we need to define an
            # individual id and pass its name to the controller (idname)
            $resource = $r
            ->under("/$route_part/:${name}id" => sub {
                my ($c) = @_;
                $c->app->log->debug(sprintf("Feeding ID into stash: \$c->stash('fm.ids')->{'%s'} = %s", $name, $c->param("${name}id")));
                $c->stash('fm.ids' => {}) unless $c->stash('fm.ids');
                $c->stash('fm.ids')->{$name} = $c->param("${name}id");
                return 1;
            })
            ->to(controller => $controller, idname => "${name}id");

            # GET requests - lists a single resource
            $resource->get->to("#rest_show")->name("show_$name");
            $app->log->debug("    GET ".$r->to_string."/$route_part/:${name}id   (rest_show)");

            if (!$readonly) {
                # DELETE requests - deletes a resource
                $resource->delete->to('#rest_remove')->name("delete_$name");
                $app->log->debug(" DELETE ".$r->to_string."/$route_part/:${name}id   (rest_delete)");

                # PUT requests - updates a resource
                $resource->put->to('#rest_update')->name("update_$name");
                $app->log->debug("    PUT ".$r->to_string."/$route_part/:${name}id   (rest_update)");
            }

            # return "/$name/:id" route so that potential child routes make sense
            return $resource;
        }
    );
}

1;

__END__

=pod

=head1 NAME

Mojolicious::Plugin::RESTRoutes - routing helper for RESTful operations

=head1 VERSION

version 1.0.0

=head1 DESCRIPTION

This Mojolicious plugin adds a routing helper for
L<REST|http://en.wikipedia.org/wiki/Representational_state_transfer>ful
L<CRUD|http://en.wikipedia.org/wiki/Create,_read,_update_and_delete>
operations via HTTP to the app.

The routes are intended, but not restricted to be used by AJAX applications.

=head1 MOJOLICIOUS SHORTCUTS

=head2 rest_routes

Can be used to easily generate the needed RESTful routes for a resource.

    my $r = $self->routes;
    my $userroute = $r->rest_routes(name => 'user');

    # Installs the following routes (given that $r->namespaces == ['My::Mojo']):
    #    GET /users                      --> My::Mojo::User::rest_list()
    #   POST /users                      --> My::Mojo::User::rest_create()
    #    GET /users/:userid              --> My::Mojo::User::rest_show()
    #    PUT /users/:userid              --> My::Mojo::User::rest_update()
    # DELETE /users/:userid              --> My::Mojo::User::rest_remove()

I<Please note>: the english plural form of the given C<name> attribute will be
used in the route, i.e. "users" instead of "user". If you want to specify
another string, see parameter C<route> below.

You can also chain C<rest_routes>:

    $userroute->rest_routes(name => 'hat', readonly => 1);

    # Installs the following additional routes:
    #    GET /users/:userid/hats         --> My::Mojo::Hat::rest_list()
    #    GET /users/:userid/hats/:hatid  --> My::Mojo::Hat::rest_show()

The target controller has to implement the following methods:

=over 4

=item *

C<rest_list>

=item *

C<rest_create>

=item *

C<rest_show>

=item *

C<rest_update>

=item *

C<rest_remove>

=back

B<Parameters to control the route creation>

=over

=item name

The name of the resource, e.g. a "user", a "book" etc. This name will be used to
build the route URL as well as the controller name (see example above).

=item readonly (optional)

If set to 1, no create/update/delete routes will be created

=item controller (optional)

Default behaviour is to use the resource name to build the CamelCase controller
name (this is done by L<Mojolicious::Routes::Route>). You can change this by
directly specifying the controller's name via the I<controller> attribute.

Note that you have to give the real controller class name (i.e. CamelCased or
whatever you class name looks like) including the full namespace.

    $r->rest_routes(name => 'user', controller => 'My::Mojo::Person');

    # Installs the following routes:
    #    GET /users         --> My::Mojo::Person::rest_list()
    #    ...

=item route (optional)

Specify a name for the route, i.e. prevent automatic usage of english plural
form of the C<name> parameter as the route component.

    $r->rest_routes(name => 'angst', route => 'aengste');

    # Installs the following routes (given that $r->namespaces == ['My::Mojo']):
    #    GET /aengste       --> My::Mojo::Angst::rest_list()

=back

B<How to retrieve the parameters / IDs>

There are two ways to retrieve the IDs given by the client in your C<rest_show>,
C<rest_update> and C<rest_remove> methods.

Example request: C<GET /users/5/hats/no9>

1. New way: the stash entry C<fm.ids> holds a hash with all ids:

    package My::Mojo::Hats;
    use Mojo::Base 'Mojolicious::Controller';

    sub rest_show {
        use Data::Dump qw(dump);
        print dump($self->stash('fm.ids'));

        # { user => 5, hat => 'no9' }
    }

2. Old way: for each resource there will be a parameter C<***id>, e.g.:

    package My::Mojo::Hat;
    use Mojo::Base 'Mojolicious::Controller';

    sub rest_show {
        my ($self) = @_;
        my $user = $self->param('userid');
        my $hat = $self->param('hatid');
        return $self->render(text => "$userid, $hatid");

        # text: "5, no9"
    }

Furthermore, the parameter C<idname> holds the name of the last ID in the route:

    package My::Mojo::Hat;
    use Mojo::Base 'Mojolicious::Controller';

    sub rest_show   {
        my $p_name = $self->param('idname');
        my $id = $self->param($p_name);
        return $self->render(text => sprintf("%s = %s", $p_name, $id || ''));

        # text: "hatid = 5"
    }

=head1 METHODS

=head2 register

Adds the routing helper (called by Mojolicious).

=encoding utf8

=head1 AUTHOR

Jens Berthold <cpan@jebecs.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Jens Berthold.

This is free software, licensed under:

  The MIT (X11) License

=cut
