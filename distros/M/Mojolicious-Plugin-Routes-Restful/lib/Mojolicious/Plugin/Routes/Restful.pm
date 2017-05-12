package Mojolicious::Plugin::Routes::Restful;
use Lingua::EN::Inflect 'PL';
use Data::Dumper;

#Oh dear, she's stuck in an infinite loop and he's an idiot! Oh well, that's love

BEGIN {
    $Mojolicious::Plugin::Routes::Restful::VERSION = '0.03';
}
use Mojo::Base 'Mojolicious::Plugin';

sub _reserved_words {
    my $self = shift;
    return {
        NO_ROOT  => 1,
        DEBUG    => 1,
        API_ONLY => 1
    };
}

sub _get_methods {
    my $self = shift;
    my ($via) = @_;

    return ['GET']
      unless ($via);
    my $valid = {
        GET    => 1,
        POST   => 1,
        PUT    => 1,
        PATCH  => 1,
        DELETE => 1
    };

    my @uc_via = map( uc($_), @{$via} );

    return \@uc_via

}

sub _is_reserved_word {
    my $self = shift;
    my ($word) = @_;

}

sub register {
    my ( $self, $app, $args ) = @_;
    $args ||= {};
    for my $sub_ref (qw/ PARENT CONFIG /) {
        die __PACKAGE__, ": missing '$sub_ref' hash in parameters\n"
          unless exists( $args->{$sub_ref} );
    }

    for my $sub_ref (qw/ NAMESPACES /) {
        die __PACKAGE__, ": missing '$sub_ref' Array in CONFIG has parameter\n"
          unless ( exists( $args->{CONFIG}->{$sub_ref} )
            and ref( $args->{CONFIG}->{$sub_ref} ) eq 'ARRAY' );
    }

    my $config = $args->{CONFIG};
    my $rapp   = $app->routes;
    $rapp = $args->{ROUTE}
      if (exists($args->{ROUTE}));
    
    my $routes = $args->{PARENT};

    $app->routes->namespaces( $config->{'NAMESPACES'} );

    foreach my $key ( keys( %{$routes} ) ) {

        my $resource =
          $self->_make_routes( "PARENT", $rapp, $key, $routes->{$key}, $config,
            $key, $key );

        my $route = $routes->{$key};

        foreach my $inline_key ( keys( %{ $route->{INLINE} } ) ) {

            die __PACKAGE__, ": INLINE must be a Hash Ref\n"
              if ( ref( $route->{INLINE} ) ne 'HASH' );

            $self->_make_routes( "INLINE", $rapp, $inline_key,
                $route->{INLINE}->{$inline_key},
                $config, $key, $resource, $routes->{$key}->{STASH} );

        }

        foreach my $sub_route_key ( keys( %{ $route->{CHILD} } ) ) {

            $self->_make_routes(
                "CHILD",        $rapp,
                $sub_route_key, $route->{CHILD}->{$sub_route_key},
                $config,        $key,
                $resource,      $config,
                $routes->{$key}->{STASH}
            );

        }
    }
    return $rapp;

}

sub _make_routes {
    my $self = shift;
    my ( $type, $rapp, $key, $route, $config, $parent, $resource,
        $parent_stash ) = @_;

#warn("type=$type, rapp=$rapp, key=$key, route=$route,confo= $config,  parent=$parent,resource=$resource, staths=   $parent_stash ");

    my $route_stash = $route->{STASH} || {};

    $route_stash = { %{$parent_stash}, %{$route_stash}  }
      if ($parent_stash);
    my $action     = $route->{ACTION}     || "show";
    my $controller = $route->{CONTROLLER} || $key;
    my $methods    = $self->_get_methods( $route->{VIA} );
    my $methods_desc = join( ',', @{$methods} );

    if ( $type eq 'PARENT' ) {

        unless ( exists( $route->{NO_ROOT} ) || exists( $route->{API_ONLY} ) ) {
            $rapp->route("/$key")->via($methods)
              ->to( "$controller#$action", $route_stash );

            warn(
"$type  Route = /$key->Via->[$methods_desc]->$controller#$action"
            ) if ( $route->{DEBUG} );
        }

        unless ( exists( $route->{NO_ID} ) || exists( $route->{API_ONLY} ) ) {
            $rapp->route("/$key/:id")->via($methods)
              ->to( "$controller#$action", $route_stash );

            warn(
"$type  Route = /$key/:id->Via->[$methods_desc]->$controller#$action"
            ) if ( $route->{DEBUG} );
        }

        $resource =
          $self->_api_routes( $rapp, $key, $route->{API}, $config->{API} )
          if ( exists( $route->{API} ) );

        return $resource || $key;

    }

    $controller = $route->{CONTROLLER} || $parent;    #aways use parent on kids

    $route_stash->{parent} = $resource;
    $route_stash->{child}  = $key;

    if ( $type eq 'INLINE' ) {

        $action = $route->{ACTION} || $key;

        $self->_inline_api_routes( $rapp, $resource, $key, $route->{API},
            $config->{API} )
          if ( exists( $route->{API} ) );

        return
          if ( exists( $route->{API_ONLY} ) );

        warn(
"$type Route = /$parent/:id/$key->Via->[$methods_desc]->$controller#$action"
        ) if ( $route->{DEBUG} );

        if ( exists( $route->{NO_ID} ) ) {

            warn(
"$type    Route = /$parent/$key->Via->[$methods_desc]->$controller#$action"
            ) if ( $route->{DEBUG} );
            $rapp->route("/$parent/$key")->via($methods)
              ->to( "$parent#$key", $route_stash );

        }
        else {
            $rapp->route("/$parent/:id/$key")->via($methods)
              ->to( "$controller#$action", $route_stash );
        }
    }
    elsif ( $type eq 'CHILD' ) {
        $action = $route->{ACTION} || $key;

        $self->_sub_api_routes( $rapp, $resource, $key, $route->{API},
            $config->{API} )
          if ( exists( $route->{API} ) );

        return
          if ( exists( $route->{API_ONLY} ) );

        $rapp->route("/$parent/:id/$key")->via($methods)
          ->to( "$controller#$action", $route_stash );
        $rapp->route("/$parent/:id/$key/:child_id")->via($methods)
          ->to( "$controller#$action", $route_stash );

        warn(
"$type    Route = /$parent/:id/$key->Via->[$methods_desc]->$controller#$action"
        ) if ( $route->{DEBUG} );
        warn(
"$type    Route = /$parent/:id/$key/:child_id->Via->[$methods_desc]->$controller#$action"
        ) if ( $route->{DEBUG} );

    }

}

sub _api_url {
    my $self = shift;
    my ( $resource, $config ) = @_;
    my $ver    = $config->{VERSION}         || "";
    my $prefix = $config->{RESOURCE_PREFIX} || "";
    my $url = join( "/", grep( $_ ne "", ( $ver, $prefix, $resource ) ) );
    return $url;
}

sub _api_routes {

    my $self = shift;
    my ( $rapi, $key, $api, $config ) = @_;

    my $resource         = $api->{RESOURCE} || PL($key);
    my $verbs            = $api->{VERBS};
    my $stash            = $api->{STASH} || {};
    my $contoller        = $api->{CONTROLLER} || $resource;
    my $contoller_prefix = $config->{PREFIX} || "api";

    my $url = $self->_api_url( $resource, $config );

    warn(   "API PARENT  ->/" 
          . $url
          . "->Via->GET-> $contoller_prefix-$contoller#get" )
      if ( $verbs->{RETRIEVE} )
      and ( $api->{DEBUG} );

    $rapi->route( "/" . $url )->via('GET')
      ->to( "$contoller_prefix-$contoller#get", $stash )
      if ( $verbs->{RETRIEVE} );

    warn(   "API PARENT  ->/" 
          . $url
          . "/:id->Via->GET-> $contoller_prefix-$contoller#get" )
      if ( $verbs->{RETRIEVE} )
      and ( $api->{DEBUG} );

    $rapi->route( "/" . $url . "/:id" )->via('GET')
      ->to( "$contoller_prefix-$contoller#get", $stash )
      if ( $verbs->{RETRIEVE} );

    warn(   "API PARENT  ->/" 
          . $url
          . "/:id->Via->POST-> $contoller_prefix-$contoller#create" )
      if ( $verbs->{CREATE} )
      and ( $api->{DEBUG} );

    $rapi->route( "/" . $url )->via('POST')
      ->to( "$contoller_prefix-$contoller#create", $stash )
      if ( $verbs->{CREATE} );

    warn(   "API PARENT  ->/" 
          . $url
          . "/:id->Via->PATCH-> $contoller_prefix-$contoller#update" )
      if ( $verbs->{UPDATE} )
      and ( $api->{DEBUG} );

    $rapi->route( "/" . $url . "/:id" )->via('PATCH')
      ->to( "$contoller_prefix-$contoller#update", $stash )
      if ( $verbs->{UPDATE} );

    warn(   "API PARENT  ->/" 
          . $url
          . "/:id->Via->PUT-> $contoller_prefix-$contoller#replace" )
      if ( $verbs->{REPLACE} )
      and ( $api->{DEBUG} );

    $rapi->route( "/" . $url . "/:id" )->via('PUT')
      ->to( "$contoller_prefix-$contoller#replace", $stash )
      if ( $verbs->{REPLACE} );

    warn(   "API PARENT  ->/" 
          . $url
          . "/:id->Via->DELETE-> $contoller_prefix-$contoller#delete" )
      if ( $verbs->{DELETE} )
      and ( $api->{DEBUG} );

    $rapi->route( "/" . $url . "/:id" )->via('DELETE')
      ->to( "$contoller_prefix-$contoller#delete", $stash )
      if ( $verbs->{DELETE} );

    return $resource;

}

sub _sub_api_routes {

    my $self = shift;
    my ( $rapi, $parent, $key, $api, $config ) = @_;

    my $child_resource   = $api->{RESOURCE} || PL($key);
    my $verbs            = $api->{VERBS};
    my $stash            = $api->{STASH} || {};
    my $child_controller = $api->{CONTROLLER} || $child_resource;
    my $contoller_prefix = $config->{PREFIX} || "api";
    $stash->{parent} = $parent;
    $stash->{child}  = $child_resource;
    my $url = $self->_api_url( $parent, $config );

    warn(
"API CHILD   ->/$url/:id/$child_resource ->Via->GET-> $contoller_prefix-$parent#$child_resource"
      )
      if ( $verbs->{RETRIEVE} )
      and ( $api->{DEBUG} );

    $rapi->route( "/" . $url . "/:id/" . $child_resource )->via('GET')
      ->to( "$contoller_prefix-$parent#$child_resource", $stash )
      if ( $verbs->{RETRIEVE} );

    warn(   "API CHILD   ->/" 
          . $url
          . "/:id/$child_resource/:child_id->Via->GET-> $contoller_prefix-$child_controller#get"
      )
      if ( $verbs->{RETRIEVE} )
      and ( $api->{DEBUG} );

    $rapi->route( "/" . $url . "/:id/" . $child_resource . "/:child_id" )
      ->via('GET')->to( "$contoller_prefix-$child_controller#get", $stash )
      if ( $verbs->{RETRIEVE} );

    warn(   "API CHILD   ->/" 
          . $url
          . "/:id/$child_resource ->Via->POST-> $contoller_prefix-$child_controller#create"
      )
      if ( $verbs->{CREATE} )
      and ( $api->{DEBUG} );

    $rapi->route( "/" . $url . "/:id/" . $child_resource )->via('POST')
      ->to( "$contoller_prefix-$child_controller#create", $stash )
      if ( $verbs->{CREATE} );

    warn(   "API CHILD   ->/" 
          . $url
          . "/:id/$child_resource/:child_id->Via->PUT-> $contoller_prefix-$child_controller#replace"
      )
      if ( $verbs->{REPLACE} )
      and ( $api->{DEBUG} );

    $rapi->route( "/" . $url . "/:id/" . $child_resource . "/:child_id" )
      ->via('PUT')->to( "$contoller_prefix-$child_controller#replace", $stash )
      if ( $verbs->{REPLACE} );

    warn(   "API CHILD   ->/" 
          . $url
          . "/:id/$child_resource/:child_id->Via->PATCH-> $contoller_prefix-$child_controller#update"
      )
      if ( $verbs->{UPDATE} )
      and ( $api->{DEBUG} );

    $rapi->route( "/" . $url . "/:id/" . $child_resource . "/:child_id" )
      ->via('PATCH')->to( "$contoller_prefix-$child_controller#update", $stash )
      if ( $verbs->{UPDATE} );

    warn(   "API CHILD   ->/" 
          . $url
          . "/:id/$child_resource/:child_id->Via->DELETE-> $contoller_prefix-$child_controller#delete"
      )
      if ( $verbs->{DELETE} )
      and ( $api->{DEBUG} );

    $rapi->route( "/" . $url . "/:id/" . $child_resource . "/:child_id" )
      ->via('DELETE')
      ->to( "$contoller_prefix-$child_controller#delete", $stash )
      if ( $verbs->{DELETE} );

}

sub _inline_api_routes {

    my $self = shift;
    my ( $rapi, $parent, $key, $api, $config ) = @_;
    my $verbs          = $api->{VERBS};
    my $child_resource = $api->{RESOURCE} || PL($key);    #this should be action
    my $stash          = $api->{STASH} || {};
    my $action = $api->{ACTION} || $child_resource;
    my $contoller_prefix = $config->{PREFIX} || "api";

    $stash->{parent} = $parent;
    $stash->{child}  = $child_resource;

    my $url = $self->_api_url( $parent, $config );

    warn(   "API INLINE->/" 
          . $url
          . "/:id/$child_resource->Via->GET-> $contoller_prefix-$parent#$action"
    ) if ( $verbs->{RETRIEVE} and $api->{DEBUG} );

    $rapi->route( "/" . $url . "/:id/" . $child_resource )->via('GET')
      ->to( "$contoller_prefix-$parent#$action", $stash )
      if ( $verbs->{RETRIEVE} );

    warn(   "API INLINE->/" 
          . $url
          . "/:id/$child_resource->Via->PATCH-> $contoller_prefix-$parent#$action"
    ) if ( $verbs->{UPDATE} and $api->{DEBUG} );

    $rapi->route( "/" . $url . "/:id/" . $child_resource )->via('PATCH')
      ->to( "$contoller_prefix-$parent#$action", $stash )
      if ( $verbs->{UPDATE} );

}

return 1;
__END__
=pod

=head1 NAME

Mojolicious::Plugin::Routes::Restful - A plugin to generate Routes and a L<RESTful|http://en.wikipedia.org/wiki/Representational_state_transfer> API for those routes, 
or just routes or just a RESTful API.

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

In your Mojo App:

  package RoutesRestful;
  use Mojo::Base 'Mojolicious';

  sub startup {
    my $self = shift;
    my $r = $self->plugin( "Routes::Restful", => {
                   Config => { NAMESPACES => ['Controller'] },
                   PARENT => {
                     project => {
                       API   => {
                         VERBS => {
                           CREATE   => 1,
                           UPDATE   => 1,
                           RETRIEVE => 1,
                           DELETE   => 1
                         },
                       },
                       INLINE => {
                         detail => {
                           API => { 
                           VERBS => { RETRIEVE => 1 } }
                         },
                       },
                       CHILD => {
                         user => {
                           API => {
                             VERBS => {
                               CREATE   => 1,
                               RETRIEVE => 1,
                               UPDATE   => 1,
                               DELETE   => 1
                             }
                           }
                         }
                       }
                     }
                   } 
                 );
          
    }
    1;
    
And, presto, the following content routes are created

  +--------+-----------------------------+-----+-------------------+
  |  Type  |    Route                    | Via | Controller#Action |
  +--------+-----------------------------+-----+-------------------+ 
  | Parent | /project                    | GET | project#show      |
  | Parent | /project/:id                | GET | project#show      |
  | Inline | /project/:id/detail         | GET | project#detail    |
  | Child  | /project/:id/user           | GET | project#user      |
  | Child  | /project/:id/user/:child_id | GET | project#user      |
  +--------+-----------------------------+-----+-------------------+

and the following RESTful API routes

  +--------+-------------------------------+--------+----------------------------------+
  |  Type  |       Route                   | Via    | Controller#Action                |
  +--------+-------------------------------+--------+----------------------------------+
  | Parent | /projects                     | GET    | api-projects#get                 |
  | Parent | /projects/:id                 | GET    | api-projects#get                 |
  | Parent | /projects                     | POST   | api-projects#create              |
  | Parent | /projects/:id                 | PATCH  | api-projects#update              |
  | Parent | /projects/:id                 | DELETE | api-projects#delete              |
  | Inline | /projects/:id/details         | GET    | api-projects#details             |
  | Child  | /projects/:id/users           | GET    | api-projects#users               |
  | Child  | /projects/:id/users/:child_id | GET    | api-users#get parent=projects    |
  | Child  | /projects/:id/users           | POST   | api-users#create parent=projects |
  | Child  | /projects/:id/users/:child_id | PATCH  | api-users#update parent=projects |
  | Child  | /projects/:id/users/:child_id | DELETE | api-users#delete parent=projects |
  +--------+-------------------------------+--------+----------------------------------+


=head1 DESCRIPTION

L<Mojolicious::Plugin::Routes::Restful> is a L<Mojolicious::Plugin> that provides a highly configurable route generator for your Mojo App.
Simply drop the plugin at the top of your start class with a config hash and you have your routes for your system.

=head1 METHODS

Well, none! Like the L<'Box Factory'|https://simpsonswiki.com/wiki/Box_Factory> it only generates routes to put in your app.

=head2 Notes on Mojo Routes and Routes in General 

If you know all about routes, just skip to the next section; otherwise, take a few minutes to go over the basic concepts this doc will use.
If you are not fully familiar with L<Mojolicious::Guides::Routing> have a look at L<Mojolicious::Guides::Routing> for some info.  

=head4 Route

The URL pattern that you are opening up that leads to a 'sub' in a controller 'class' which returns some content from the system.

=head4 Action

The 'sub' in the '.pm' file (class) that the route will invoke.

=head4 Controller

This is the '.pm' file (class) file that a route will use to find its action 'sub' in. 

=head4 Parent or Child Resource

The named part of a route. Given this route

  /project/:id/user/:child_id
  
The parent resource is 'project' and the child is 'user', with the parent ':id' identifier between the two and the ':child_id' identifier at the end. 
Usually just referred to as a resource. 

=head4 id: and child_id: Identifiers

The part of a route that identifies a single resource.  99.9872% of the time it is an number but it could be anything.  

=head4 RESTFul Resources

RESTful APIs should always use the plural form of a noun for parent and child resources and a number as an identifier. Normally, RESTful
resources point to data and not content.  As well, a resource should not used to filter the data.  

=head4 Resource Entity

The end content that a route will return in response to a request. Can be any form of content.

=head4 RESTful Entity

This usually means a specific block of data that is stored someplace that a route will return.  In RESTful resources, there is an expectation  
of certain entity result from a route with a given HTTP verb. The table below lists out the expected results of a well
designed RESTFul API and is the pattern that this Plugin enforces.

  +-----------------------+--------+---------------------+-----------------------------------+
  | Route                 | Via    |  Entity Type        |  Example of Result                |
  +-----------------------+--------+---------------------+-----------------------------------+
  | /projects             | GET    | Collection          | My Projects                       |
  | /projects/22          | GET    | Singleton           | Project #22                       |
  | /projects/22/users    | GET    | Collection          | Users in Project #22              |
  | /projects/22/users/44 | GET    | Singleton           | Project User #44                  |
  | /projects             | POST   | Add a Singleton     | New Project #42                   |
  | /projects/22/users    | POST   | Add a Singleton     | New User #44 added to Project #22 |
  | /projects/22          | PUT    | Replace a Singleton | Project #22 replaced              |
  | /projects/22/users/44 | PUT    | Replace a Singleton | User #44 replaced                 |
  | /projects/22          | PATCH  | Update a Singleton  | Project #22 Updated               |
  | /projects/22/users/44 | PATCH  | Update a Singleton  | Project User #44 Updated          |
  | /projects/22          | DELETE | Delete a Singleton  | Project #22 Deleted               |
  | /projects/22/users/44 | DELETE | Singleton           | Project User #44 Deleted          |
  +-----------------------+--------+---------------------+-----------------------------------+
  
You might notice that collection DELELTE, PUT and PATCH is not present. This is by design. 

=head4 HTTP Via Verbs

In the good old days we only had two of these: 'GET' and 'POST'. Now it seems a new one comes out every month. In this doc we simply use the term
Via for this in most places.

=head1 CONFIGURATION

You define which routes and the behaviour of your routes with a simple config hash in the startup section of your app.  The plugin returns the route object
it created so you will have it if you need it for other operations, such as add in a bunch of collective DELETE routes. 


=head2 CONFIG

This controls the global settings. 

=head3 NAMESPACES

Used to hold the namespaces for all routes you generate. Does the same thing as

    $r->namespaces(['MyApp::MyController','MyApp::::Controller::Ipa::Projects']);
    
It must be an array ref of module Class names as they would appear in a 'use' statement.  These are important, as your app may not find 
your class if its  namespace do not appear here.

=head2 ROUTE

With this optional attribute you can pass in a route that will have all the generated as its children. This is useful if you want to use 
a bridge or callback on all your generated routes. 

=head3 Resource Types PARENT, CHILD, INLINE

There is nothing in Mojolicious stopping you from creating a big goofy chained resource like 'all/the/bad/code/perl/catalyst'; if that is what you want, then
find yourself another Plugin. This Plugin enforces a simple two tier model, with as many 1st level 'PARENT' resources as you like, and under each 
you can have as many 2nd level 'INLINE' and 'Child' types you want.  

=head3 Parent and Child in the Stash

INLINE and CHILD routes always have the values of parent and child in the stash as well as id and child_id if available. 

=head3 Resource Attributes
 
All three of resource types have Attributes that allow you to customize your routes to some degree. Most of the attributes are common to all
three and some only apply to certain types. They are all optional.

=head3 API Attribute

All types can have the API attribute which is used to define your RESTful routes. The idea being that if you are creating a route
to content you may want a RESTful 'route' to access data for that content, so you might as well do it at the same time as the route.  

=head3 DEBUG Attribute

You can add in the DEBUG attribute at the any attribute level to get the info on the route that is being generated. 

=head2 PARENT Resource Type

By default, a Parent resource uses its key as the resource and controller name, 'show' as the action and GET as the HTTP verb.

So given this hash

  PARENT => {
            project => {},
            user    => {}
          }

these routes would be created

  +--------+-----------------------------+-----+-------------------+
  |  Type  |    Route                    | Via | Controller#Action |
  +--------+-----------------------------+-----+-------------------+ 
  | Parent | /project                    | GET | project#show      |
  | Parent | /project/:id                | GET | project#show      |
  | Parent | /user                       | GET | user#show         |
  | Parent | /user/:id                   | GET | user#show         |
  +--------+-----------------------------+-----+-------------------+

=head3 PARENT Attributes

The world is a complex place and there is never a simple solution that covers all the bases, so this plugin includes a number of attributes that you can use
to customize your routes to suite your site's needs.

=head4 ACTION

You can override the default 'show' action by with this attribute, so

  PARENT => {
            project => {ACTION=>'list'},
          }

would get you 

  +--------+-----------------------------+-----+-------------------+
  |  Type  |    Route                    | Via | Controller#Action |
  +--------+-----------------------------+-----+-------------------+ 
  | Parent | /project                    | GET | project#list      |
  | Parent | /project/:id                | GET | project#list      |
  +--------+-----------------------------+-----+-------------------+

The value must to be a valid SCALAR and a valid perl sub name.

=head4 CONTROLLER

One can override the use of 'key' as the controller name by using this modifier, so

  PARENT => {
            project => {ACTION=>'list'
                        CONTROLLER=>'myapp-pm'},
          }

  +--------+-----------------------------+-----+-------------------+
  |  Type  |    Route                    | Via | Controller#Action |
  +--------+-----------------------------+-----+-------------------+ 
  | Parent | /project                    | GET | myapp-pm#list     |
  | Parent | /project/:id                | GET | myapp-pm#list     |
  +--------+-----------------------------+-----+-------------------+
  
The value must to be a valid SCALAR and a valid perl 'class' name. You should use the same naming convention 
as found in Mojolicious,  lower-snake-case but it will also take '::' as well.

=head4 NO_ID

You may not want to have an :id on a 'PARENT' resource, so you can use this modifier to drop that route

  PARENT => {
            project => {ACTION=>'all_projects'
                         CONTROLLER=>'pm'
                         NO_ID=>1 },
          }

would get you only

  +--------+-----------------------------+-----+-------------------+
  |  Type  |    Route                    | Via | Controller#Action |
  +--------+-----------------------------+-----+-------------------+ 
  | Parent | /project                    | GET | pm#all_projects   |
  +--------+-----------------------------+-----+-------------------+

The key needs only to be defined. 

=head4 NO_ROOT

Sometimes one might not want to open up a 'PARENT' resource without an :id, so you can use this modifier to drop that route

  PARENT => {
            project => {ACTION=>'list'
                         CONTROLLER=>'pm'
                         NO_ROOT=>1 },
          }

would get you only

  +--------+-----------------------------+-----+-------------------+
  |  Type  |    Route                    | Via | Controller#Action |
  +--------+-----------------------------+-----+-------------------+ 
  | Parent | /project/:id                | GET | pm#list           |
  +--------+-----------------------------+-----+-------------------+

The key needs only to be defined.  Be aware that if you use both 'NO_ID' and 'NO_ROOT' you will get no routes.

=head4 STASH

Need some static data on all items along a route?  Well, with this modifier you can.  So given this hash

  PARENT => {
            project => {STASH=>{selected_tab=>'project'}},
            user    => {STASH=>{selected_tab=>'user'}}
          }
          
you would get the same routes as with the first example but the 'selected_tab' variable will be available in the stash.  So
you could use it on your controller to pass the current navigation state into the content pages say, as in this
case, to set up a  the 'Selected Tab' in a  view.

The value must be a Hashref with at least one key pair defined.

=head4 VIA

By default, all route types use the GET http method.  You can change this to any other valid combination of
HTTP methods.  As this plugin has a restful portion, this is probably not advisable.

  PARENT => {
            user    => {VIA    =>[qw(POST PUT),
                        ACTION =>'update']}
          }

would yield these routes

  +--------+-----------------------------+------+-------------------+
  |  Type  |    Route                    | Via  | Controller#Action |
  +--------+-----------------------------+------+-------------------+ 
  | Parent | /user                       | POST | user#update       |
  | Parent | /user/:id                   | POST | user#update       |
  | Parent | /user                       | PUT  | user#update       |
  | Parent | /user/:id                   | PUT  | user#update       |
  +--------+-----------------------------+------+-------------------+

Note here how the 'action' of the user route was changed to 'update' as it would not be a very good idea to have a sub
in your controller called 'show' that updates an entity.  

The value must be an Arrayref of valid HTTP methods.  

=head4 API_ONLY

Sometimes you want just the RESTful API so instead of using 'NO_ID' and 'NO_ROOT', use the 'API_ONLY' and get no routes.

  PARENT => {
            project => { API_ONLY=>1 },
          }

Would get you no routes!

The key needs only to be defined.

=head2 INLINE Type

An INLINE route is one that usually points to only part of a single content entity, or perhaps a collection of that entity or even a number of 
child entities under the parent entity.  Using an example 'Project' page it could be made up of a number panels, pages, tabs etc. each containing only part of 
the whole project. 

Below we see the three panels of a 'Project' page

  +----------+---------+----------+
  | Abstract | Details | Admin    | 
  +          +---------+----------+
  |                               |
  | Some content here             |
  ...

In this case 'Abstract' is a single large content item from a single project entity,  'Details' has a number of smaller 
single content items (Name, Long Description, etc.) and maybe a few collections such as 'Users' or 'Contacts'.  The final page, 'Admin',
leads to a separate admin entity.

By default, an INLINE resource uses its key as the resource, its parent resource as its controller, its key as the action, and GET
as the HTTP verb.  Also, the parent and child resource are passed placed in the stash along with and other STASH values from the PARENT.
  
So to create the routes for the example page above one would use this hash

  PARENT => {
            project => {
              STASH =>{page=>'project'},
              INLINE => { abstract=>{
                                   STASH=>{tab=>'abstract'}
                                   },
                                 detail=>{
                                   STASH=>{tab=>'detail'},
                                  },
                                 admin=>{
                                   STASH=>{tab=>'admin'},
                                   }
                                 }
               },
          }
          
which would give you these routes

  +--------+-----------------------------+-----+-------------------+---------------------------------+
  |  Type  |    Route                    | Via | Controller#Action | Stashed Values                  |
  +--------+-----------------------------+-----+-------------------+---------------------------------+
  | Parent | /project                    | GET | project#show      | page = project                  |
  | Parent | /project/:id                | GET | project#show      | page = project                  |
  | Inline | /project/:id/abstract       | GET | project#abstract  | tab  = abstract, page = project |
  | Inline | /project/:id/detail         | GET | project#detail    | tab  = detail, page = project   |
  | Inline | /project/:id/admin          | GET | project#admin     | tab  = admin, page = project    |
  +--------+-----------------------------+-----+-------------------+---------------------------------+
 
On the content pages you would use the 'stashed' page and tab values to select the current tab.

So INLINE by default is limited in scope to the parent's level, in this case the project with the correct id,
and using the parents controller the action always being the key of the inline_route. 

The value must a Hashref with at least one key pair defined.

=head3 INLINE Attributes
 
The following attributes are available to INLINE types and work in the same way as the PARENT attributes. 

=over 4 

=item * 

ACTION

=item * 

CONTROLLER

=item * 

NO_ID

=item * 

API_ONLY

=item * 

VIA

=back

=head3 CHILD Type

A CHILD is one that will always follow the parent to child entity pattern. It should always point to either a collection of 
child entities when only the parent :id is present, and a single child entity when the :child_id is present.

By default, a CHILD resource uses its key as the resource, its parent resource as its controller, its key as the action and GET 
as the HTTP verb.

So this hash

  PARENT => {
            project => {
              CHILD => { user=>{},
                         contact=>{}
                        }
               },
          }

would result in the following routes

  +--------+--------------------------------+-----+-------------------+-----------------------------------+
  |  Type  |    Route                       | Via | Controller#Action | Stashed Values                    |
  +--------+--------------------------------+-----+-------------------+-----------------------------------+
  | Parent | /project                       | GET | project#show      | parent = project                  |
  | Parent | /project/:id                   | GET | project#show      | parent = project                  |
  | Child  | /project/:id/user              | GET | projects#user     | parent = project, child = user    |
  | Child  | /project/:id/user/:child_id    | GET | projeect#user     | parent = project, child = user    |
  | Child  | /project/:id/contact           | GET | projects#contact  | parent = project, child = contact |
  | Child  | /project/:id/contact/:child_id | GET | projeect#contact  | parent = project, child = contact |
  +--------+--------------------------------+-----+-------------------+-----------------------------------+

Notice how the stash has the parent controller 'project' and the action child 'user' this works in the same
manner as INLINE types.

The value must be a Hashref with at least one key pair defined.

The following CHILD attributes are available and work in the same way as the on the INLINE and PARENT attributes.

=over 4 

=item * 

ACTION

=item * 

CONTROLLER

=item * 

API_ONLY

=item * 

VIA

=back

=head2 API Attribute

All three route types can have the 'API' attribute, which is used to open the resource to the RESTful API of your system.
This module takes an 'open only when asked' design pattern,  meaning that if you do not explicitly ask for an API resource,
it will not be created.

It follows the tried and true CRUD pattern but with a an extra 'R' for 'Replace' giving us CRRUD which maps to 
the following HTTP Methods: 'POST', 'GET','PUT','PATCH' and 'DELETE'.  

=head3 VERBS

The VERBS modifier is used to open parts of your API.  It must be a Hashref with the following keys;

=head4 CREATE

This opens the 'POST' method of your API resource and always points to a 'create' sub in the resource controller.

=head4 RETRIEVE

This opens the 'GET' method of your API resource and always points to a 'get' sub in the resource controller.

=head4 REPLACE

This opens the 'PUT' method of your API resource and always points to a 'replace' sub in the resource controller.

=head4 UPDATE

This opens the 'GET' method of your API resource and always points to an 'update' sub in the resource controller.

=head4 DELETE

This opens the 'DELETE' method of your API resource and always points to an 'delete' sub in the resource controller.


=head3 PARENT Types and Verbs

All API verbs are available to a parent resource, and by default the key is used as the resource and controller name, while 
the via and action are set by the HTTP verb.

So for the following hash 

  PARENT => {
                     project => {
                       API   => {
                         VERBS => {
                           CREATE   => 1,
                           UPDATE   => 1,
                           RETRIEVE => 1,
                           DELETE   => 1
                         },
                       },
              }
              
you would get the following api routes

  +--------+-------------------------------+--------+---------------------+
  |  Type  |       Route                   | Via    | Controller#Action   |
  +--------+-------------------------------+--------+---------------------+
  | Parent | /projects                     | GET    | api-projects#get    |
  | Parent | /projects/:id                 | GET    | api-projects#get    |
  | Parent | /projects                     | POST   | api-projects#create |
  | Parent | /projects/:id                 | PATCH  | api-projects#update |
  | Parent | /projects/:id                 | DELETE | api-projects#delete |
  +--------+-------------------------------+--------+---------------------+

As the REPLACE verb was not added to the hash, the route via http PUT was not created. Also note, the PARENT
resource has been change to a plural, via Lingua::EN::Inflect::PL, and the controller has had the default 'api' 
namespace added to the plural form of the PARENT resource.

The value must a Hashref with at least one of the valid VERB keys defined.

=head4 RESOURCE

Sometimes you may not want to use the default plural form PL.  Say for example if your specification 
requires you use the first letter abbreviated form of 'Professional Engineers of New Islington' 
tacking an 's' on the end may not be what the client wants.  
 
So with this attribute used in this hash

  PARENT => {
             apparatus => {
                    API   => {
                         RESOURCE =>'apparatus'
                         VERBS => {
                           RETRIEVE => 1,
                         },
                       },
              }

you would get the following
  
  +--------+-------------------------------+--------+---------------------+
  |  Type  |       Route                   | Via    | Controller#Action   |
  +--------+-------------------------------+--------+---------------------+
  | Parent | /apparatus                    | GET    | api-apparatus#get   |
  | Parent | /apparatus/:id                | GET    | api-apparatus#get   |
  +--------+-------------------------------+--------+---------------------+

Note how it set both the route resource and the controller name.

The value must be a valid SCALAR.

=head4 CONTROLLER

You may want to change the controller for some reason; this modifier lets you do that.  So

  PARENT => {
             apparatus => {
                    API   => {
                         RESOURCE =>'apparatus'
                         CONTROLLER=>'user_apps'
                         VERBS => {
                           RETRIEVE => 1,
                         },
                       },

would give you

  +--------+-------------------------------+--------+--------------------+
  |  Type  |       Route                   | Via    | Controller#Action  |
  +--------+-------------------------------+--------+--------------------+
  | Parent | /apparatus                    | GET    | api-user_apps#get  |
  | Parent | /apparatus/:id                | GET    | api-user_apps#get  |
  +--------+-------------------------------+--------+--------------------+
  
The value must to be a valid SCALAR and a valid perl 'class' name. You should use the same naming convention 
as found in Mojolicious, lower-snake-case but it will also take '::' as well.

=head4 STASH

Like all the other route types, you can add extra static data on all items along a route with this modifier.
The value must be a Hashref with at least one key pair defined.

=head3 INLINE Types and API Verbs

INLINE API routes are limited to only two verbs 'RETRIEVE' and 'UPDATE'; and by default, its key is used as the resource, the 
controller is the PARENT resource, the via is set by the VERB, and the action is Key.

Technically speaking, this type of route breaks the RESTFul speculation as no specific path to the Child and its identifier could be present, so it
really should be a PUT replace method rather than an PATCH update method.  I left it in as it is useful to have about, for retrieval of partial data
sets of a parent entity using a sub in the parent's controller, and updating large singleton sets of a Parent.
Just do not use them if you do not like them.

For example the following 

  PARENT => {
             project => {
                    API   => {
                         VERBS => {
                           RETRIEVE => 1,
                         },
                       },
                    INLINE => 
                       { resume=>{
                          API => {verbs=>{RETRIEVE => 1,
                                  UPDATE => 1,
                                  }
                                }
                               }
    
         }
         
would give you the following API routes
 
  +--------+-----------------------+-------+--------------------  +------------------------------------+
  |  Type  |    Route              | Via   | Controller#Action    | Stashed Values                     |
  +--------+-----------------------+-------+----------------------+------------------------------------+
  | Parent | /projects             | GET   | api-projects#get     | parent = projects                  |
  | Parent | /projects/:id         | GET   | api-projects#get     | parent = projects                  |
  | INLINE | /projects/:id/resumes | GET   | api-projects#resumes | parent = projects, child = resumes |
  | INLINE | /projects/:id/resumes | PATCH | api-projects#resumes | parent = projects, child = resumes |
  +--------+-----------------------+-------+----------------------+------------------------------------+
 
The value must be a Hashref with at least one of the valid VERB keys defined. It only process 'RETEIVE' and 'UPDATE' verbs.
 
=head3 Other Attributes

=head4 RESOURCE and ACTION

Both can be used with INLINE routes.

So this hash

  PARENT => {
             project => {
                    API   => {
                         VERBS => {
                           RETRIEVE => 1,
                         },
                       },
                    INLINE => 
                       { resume=>{
                          API => {RESOURCE => 'resume',
                                  ACTION=>'get_or_update_resume',
                                  VERBS=>{RETRIEVE => 1,
                                          UPDATE   => 1}
                                  }
                               }
    
         }
         
would give you the following API routes
 
  +--------+----------------------+-------+-----------------------------------+------------------------------------+
  |  Type  |    Route             | Via   | Controller#Action                 | Stashed Values                     |
  +--------+----------------------+-------+-----------------------------------+------------------------------------+
  | Parent | /projects            | GET   | api-projects#get                  | parent = projects                  |
  | Parent | /projects/:id        | GET   | api-projects#get                  | parent = projects                  |
  | Child  | /projects/:id/resume | GET   | api-projects#get_or_update_resume | parent = projects, child = resumes |
  | Child  | /projects/:id/resume | PATCH | api-projects#get_or_update_resume | parent = projects, child = resumes |
  +--------+----------------------+-------+-----------------------------------+------------------------------------+

By the way, it is not very good RESTful design to have a singular noun as a resource, or to imply an update to a child with
the PATCH method without an identifier for that child. 

The value of RESOURCE and ACTION must be a valid SCALAR.

=head4 STASH

Like all the other route types, you can add extra static data on all items along a route with this modifier.
The value must be a Hashref with at least one key defined.

=head3 CHILD Types and API Verbs

CHILD type routes can utilize all verbs. The resource is by default the key value. When the GET verb is used with only the :id of the parent,
then the Parent controller is used, and the action will be the Key of the Child. For all of the other routes, the key is the controller name
while the via and action are set by the HTTP verb.

So this hash

  PARENT => {
             project =>{
                         API   => {
                           VERBS => {
                             RETRIEVE => 1,
                           },
                         },
                       },
                CHILD => {
                         user => {
                           API => {
                             VERBS => {
                               CREATE   => 1,
                               RETRIEVE => 1,
                               REPLACE  => 1,
                               UPDATE   => 1,
                               DELETE   => 1
                             }
                           }
                         }
                       }
                     }
                   

would generate these routes 

  +--------+-------------------------------+--------+--------------------+----------------------------------+
  |  Type  |    Route                      | Via    | Controller#Action  | Stashed Values                   |
  +--------+-------------------------------+--------+--------------------+----------------------------------+
  | Parent | /projects                     | GET    | api-projects#get   | parent = projects                |
  | Parent | /projects/:id                 | GET    | api-projects#get   | parent = projects                |
  | Child  | /projects/:id/users           | GET    | api-projects#users | parent = projects, child = users |
  | Child  | /projects/:id/users           | POST   | api-users#create   | parent = projects, child = users |
  | Child  | /projects/:id/users/:child_id | GET    | api-users#get      | parent = projects, child = users |
  | Child  | /projects/:id/users/:child_id | PUT    | api-users#replace  | parent = projects, child = users |
  | Child  | /projects/:id/users/:child_id | PATCH  | api-users#update   | parent = projects, child = users |
  | Child  | /projects/:id/users/:child_id | DELETE | api-users#delete   | parent = projects, child = users |
  +--------+-------------------------------+--------+--------------------+----------------------------------+

The value must a Hashref with at least one of the valid VERB keys defined.

=head3 Other Attributes

=head4 RESOURCE and CONTROLLER

You can use both the 'RESOURCE' and 'CONTROLLER' attributes in a sub_route. The only caveat being that you cannot change 
the controller and action on the RETRIEVE Verb without :child_id.

So given this hash

  PARENT => {
                    project => {
                       API   => {
                         VERBS => {
                           RETRIEVE => 1,
                         },
                       },
                       },
                       CHILD => {
                         user => {
                           API => {
                             CONTROLLER => 'my_users',
                             RESOURCE   => 'user',
                             VERBS => {
                               CREATE   => 1,
                               RETRIEVE => 1,
                               REPLACE  => 1,
                               UPDATE   => 1,
                               DELETE   => 1
                             }
                           }
                         }
                       }
                     }
                   
you would have only these routes 

  +--------+------------------------------+--------+----------------------+---------------------------------+
  |  Type  |    Route                     | Via    | Controller#Action    | Stashed Values                  |
  +--------+------------------------------+--------+----------------------+---------------------------------+
  | Parent | /projects                    | GET    | api-projects#get     | parent = projects               |
  | Parent | /projects/:id                | GET    | api-projects#get     | parent = projects               |
  | Child  | /projects/:id/user           | GET    | api-projects#user    | parent = projects, child = user |
  | Child  | /projects/:id/user           | POST   | api-my_users#create  | parent = projects, child = user |
  | Child  | /projects/:id/user/:child_id | GET    | api-my_users#get     | parent = projects, child = user |
  | Child  | /projects/:id/user/:child_id | PUT    | api-my_users#replace | parent = projects, child = user |
  | Child  | /projects/:id/user/:child_id | PATCH  | api-my_users#update  | parent = projects, child = user |
  | Child  | /projects/:id/user/:child_id | DELETE | api-my_users#delete  | parent = projects, child = user |
  +--------+-----------------------+------+--------+----------------------+---------------------------------+

The value of RESOURCE and CONTROLLER must be a valid SCALAR.

=head4 STASH

Like all the other route types, you can add extra static data on all items along a route with this modifier. 
The value must be a Hashref with at least one key pair defined.

=head3 Global API Attributes.

There are a few Global API attributes that can be added to CONFIG hashref with an API Hashref.
hash.

=head4 VERSION

Sometimes there is a requirement to include a version identifier for your APIs, and this is normally done with a version prefix. 
Using this attribute, you can add a version prefix to all our your API routes.  

So with this hash

  CONFIG => {API=>{VERSION=>'V_1_1'}},
  PARENT => {
            project => {
                       API   => {
                         VERBS => {
                           RETRIEVE => 1,
                         },
                       },
                       },
                       CHILD => {
                         user => {
                           API => {
                             CONTROLLER => 'my_users',
                             RESORUCE   => 'user',
                             VERBS => {
                               CREATE   => 1,
                               RETRIEVE => 1,
                               REPLACE  => 1,
                               UPDATE   => 1,
                               DELETE   => 1
                             }
                           }
                         }
                       }
            }
                     
would have only these routes 

  +--------+-----------------------------------+--------+----------------------+---------------------------------+
  |  Type  |    Route                          | Via    | Controller#Action    | Stashed Values                  |
  +--------+-----------------------------------+--------+----------------------+---------------------------------+
  | Parent | V_1_1/projects                    | GET    | api-projects#get     | parent = projects               |
  | Parent | V_1_1/projects/:id                | GET    | api-projects#get     | parent = projects               |
  | Child  | V_1_1/projects/:id/user           | GET    | api-projects#user    | parent = projects, child = user |
  | Child  | V_1_1/projects/:id/user           | POST   | api-my_users#create  | parent = projects, child = user |
  | Child  | V_1_1/projects/:id/user/:child_id | GET    | api-my_users#get     | parent = projects, child = user |
  | Child  | V_1_1/projects/:id/user/:child_id | PUT    | api-my_users#replace | parent = projects, child = user |
  | Child  | V_1_1/projects/:id/user/:child_id | PATCH  | api-my_users#update  | parent = projects, child = user |
  | Child  | V_1_1/projects/:id/user/:child_id | DELETE | api-my_users#delete  | parent = projects, child = user |
  +--------+-----------------------------------+--------+----------------------+---------------------------------+

The value must be a valid SCALAR.

=head4 RESOURCE_PREFIX

You can also add a global prefix as well if you want.  It always comes after the VERSION. 

So this hash

  CONFIG => {API=>{VERSION=>'V_1_1',
                   RESOURCE_PREFIX=>'beta' }
            },
  PARENT => {
                    project => {
                       API   => {
                         VERBS => {
                           RETRIEVE => 1,
                         },
                       },
                       },
                       CHILD => {
                         user => {
                           API => {
                             CONTROLLER => 'my_users',
                             RESORUCE   => 'user',
                             VERBS => {
                               CREATE   => 1,
                               RETRIEVE => 1,
                               REPLACE  => 1,
                               UPDATE   => 1,
                               DELETE   => 1
                             }
                           }
                         }
                       }
                     }
                     
would generate these routes 

  +--------+----------------------------------------+--------+----------------------+---------------------------------+
  |  Type  |    Route                               | Via    | Controller#Action    | Stashed Values                  |
  +--------+----------------------------------------+--------+----------------------+---------------------------------+
  | Parent | beta/V_1_1/projects                    | GET    | api-projects#get     | parent = projects               |
  | Parent | beta/V_1_1/projects/:id                | GET    | api-projects#get     | parent = projects               |
  | Child  | beta/V_1_1/projects/:id/user           | GET    | api-projects#user    | parent = projects, child = user |
  | Child  | beta/V_1_1/projects/:id/user           | POST   | api-my_users#create  | parent = projects, child = user |
  | Child  | beta/V_1_1/projects/:id/user/:child_id | GET    | api-my_users#get     | parent = projects, child = user |
  | Child  | beta/V_1_1/projects/:id/user/:child_id | PUT    | api-my_users#replace | parent = projects, child = user |
  | Child  | beta/V_1_1/projects/:id/user/:child_id | PATCH  | api-my_users#update  | parent = projects, child = user |
  | Child  | beta/V_1_1/projects/:id/user/:child_id | DELETE | api-my_users#delete  | parent = projects, child = user |
  +--------+----------------------------------------+--------+----------------------+---------------------------------+

The value must be a valid SCALAR. 

=head4 PREFIX

If you really do not like 'API' as the lead part of your api namespace you can over-ride that with this 
attribute as in the hash below

  CONFIG => {API=>{PREFIX=>'open'}},
  PARENT => {
            project => {
                       API   => {
                         VERBS => {
                           RETRIEVE => 1,
                         },
                       },
                       CHILD => {
                         user => {
                           API => {
                             CONTROLLER => 'my_users',
                             RESORUCE   => 'user',
                             VERBS => {
                               CREATE   => 1,
                               RETRIEVE => 1,
                               REPLACE  => 1,
                               UPDATE   => 1,
                               DELETE   => 1
                             }
                           }
                         }
                       }
            }
                     
would have only these routes 

  +--------+-----------------------------+--------+-----------------------+---------------------------------+
  |  Type  |    Route                    | Via    | Controller#Action     | Stashed Values                  |
  +--------+------------------------- ---+--------+-----------------------+---------------------------------+
  | Parent | projects                    | GET    | open-projects#get     | parent = projects               |
  | Parent | projects/:id                | GET    | open-projects#get     | parent = projects               |
  | Child  | projects/:id/user           | GET    | open-projects#user    | parent = projects, child = user |
  | Child  | projects/:id/user           | POST   | open-my_users#create  | parent = projects, child = user |
  | Child  | projects/:id/user/:child_id | GET    | open-my_users#get     | parent = projects, child = user |
  | Child  | projects/:id/user/:child_id | PUT    | open-my_users#replace | parent = projects, child = user |
  | Child  | projects/:id/user/:child_id | PATCH  | open-my_users#update  | parent = projects, child = user |
  | Child  | projects/:id/user/:child_id | DELETE | open-my_users#delete  | parent = projects, child = user |
  +--------+-----------------------+------+--------+----------------------+---------------------------------+

The value must to be a valid SCALAR and a valid perl 'class' name. You should use the same naming convention 
as found in Mojolicious,  lower-snake-case but it will also take '::' as well.

=head1 AUTHOR

John Scoles, C<< <byterock  at hotmail.com> >>

=head1 BUGS / CONTRIBUTING

Please report any bugs or feature requests through the web interface at L<https://github.com/byterock/>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.
    perldoc Mojolicious::Plugin::Authorization
You can also look for information at:

=over 4

=item * 

AnnoCPAN: Annotated CPAN documentation L<http:/>

=item * 

CPAN Ratings L<http://cpanratings.perl.org/d/>

=item * 

Search CPAN L<http://search.cpan.org/dist//>

=back

=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2016 John Scoles.
This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.
See http://dev.perl.org/licenses/ for more information.

=cut
