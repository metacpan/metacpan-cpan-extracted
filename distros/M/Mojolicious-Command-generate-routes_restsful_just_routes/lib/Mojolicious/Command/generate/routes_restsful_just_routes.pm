package Mojolicious::Command::generate::routes_restsful_just_routes;
use Lingua::EN::Inflect 'PL';
use Mojo::Base 'Mojolicious::Command';

use Mojo::Util qw(class_to_file class_to_path camelize class_to_path);

has description =>
  'Generate Mojolicious route code using a Mojolicious::Plugin::Routes::Restful hash';
has usage =>
"Usage: $0 generate Mojolicious route code using a Mojolicious::Plugin::Routes::Restful hash\n";

our $VERSION   = '0.0.1';
our @all_routes = ();
use Data::Dumper;

$Data::Dumper::Indent              = 0;
$Data::Dumper::Terse               = 1;

sub run {
    my ( $self, $name, $in_routes ) = @_;

   
    # Script

    for my $sub_ref (qw/ PARENT CONFIG /) {
        die __PACKAGE__, ": missing '$sub_ref' hash in parameters\n"
          unless exists( $in_routes->{$sub_ref} );
    }

    my $config = $in_routes->{CONFIG};

    my $routes     = $in_routes->{PARENT};
   
    foreach my $key ( keys( %{$routes} ) ) {

        my $resource =
          _make_site( "PARENT", $key, $routes->{$key}, $config, $key, $key );

        my $route = $routes->{$key};

        foreach my $inline_key ( keys( %{ $route->{INLINE} } ) ) {

            die __PACKAGE__, ": INLINE must be a Hash Ref\n"
              if ( ref( $route->{INLINE} ) ne 'HASH' );

            _make_site( "INLINE", $inline_key, $route->{INLINE}->{$inline_key},
                $config, $key, $resource, $routes->{$key}->{STASH} );

        }

        foreach my $sub_route_key ( keys( %{ $route->{CHILD} } ) ) {

            _make_site( "CHILD", $sub_route_key,
                $route->{CHILD}->{$sub_route_key},
                $config, $key, $resource, $routes->{$key}->{STASH} );

        }
    }
  
    $self->render_to_rel_file( 'just_code', $name, \@all_routes);
  
  

}


sub _get_methods {
    my ($via) = @_;

    return "['GET']"
      unless ($via);
    my $valid = {
        GET    => 1,
        POST   => 1,
        PUT    => 1,
        PATCH  => 1,
        DELETE => 1
    };

    my @uc_via = map( uc($_), @{$via} );

    return Dumper(\@uc_via);

}

sub _make_site {

    my ( $type, $key, $route, $config, $parent, $resource, $parent_stash ) = @_;

    my $route_stash = $route->{STASH} || {};
    $route_stash = { %{$route_stash}, %{$parent_stash} }
      if ($parent_stash);
    my $action = $route->{ACTION} || "show";
    my $methods    = _get_methods( $route->{VIA} );
    my $controller = $route->{CONTROLLER} || $key;

    if ( $type eq 'PARENT' ) {

        $resource = _api_site( $key, $route->{API}, $config->{API} )
          if ( exists( $route->{API} ) );

        return $resource || $key
          if ( exists( $route->{API_ONLY} ) );

        push(@all_routes,{url=>"/$key",
                          methods=>$methods,
                          controller=>"$controller#$action",
                          stash=>Dumper( $route_stash)})

        unless ( exists( $route->{NO_ROOT} ) );

        push(@all_routes,{url=>"/$key/:id",
                          methods=>$methods,
                          controller=>"$controller#$action",
                          stash=>Dumper( $route_stash)})
          unless ( exists( $route->{NO_ID} ) );

        return $resource || $key

    }
    $controller = $route->{CONTROLLER} || $parent;    #aways use parent on kids
    $route_stash->{parent} = $resource;
    $route_stash->{child}  = $key;
    if ( $type eq 'INLINE' ) {

        $action = $route->{ACTION} || $key;

        _sub_inline_api_site( $resource, $key, $route->{API}, $config->{API} )
          if ( exists( $route->{API} ) );

        return
          if ( exists( $route->{API_ONLY} ) );

        if ( exists( $route->{NO_ID} ) ) {
                  push(@all_routes,{url=>"/$parent/$key",
                          methods=>$methods,
                          controller=>"$controller#$action",
                          stash=>Dumper( $route_stash)});
        }
        else {
                  push(@all_routes,{url=>"/$parent/:id/$key",
                          methods=>$methods,
                          controller=>"$controller#$action",
                          stash=>Dumper( $route_stash)});

        }
    }
    elsif ( $type eq 'CHILD' ) {

        _sub_api_site( $resource, $key, $route->{API}, $config->{API} )
          if ( exists( $route->{API} ) );

        return
          if ( exists( $route->{API_ONLY} ) );

        $action = $route->{ACTION} || $key;
          push(@all_routes,{url=>"/$parent/:id/$key",
                          methods=>$methods,
                          controller=>"$controller#$action",
                          stash=>Dumper( $route_stash)});
           push(@all_routes,{url=>"/$parent/:id/$key/:child_id",
                          methods=>$methods,
                          controller=>"$controller#$action",
                          stash=>Dumper( $route_stash)});
    }

}

sub _api_url {

    my ( $resource, $config ) = @_;
    my $ver    = $config->{VERSION}         || "";
    my $prefix = $config->{RESOURCE_PREFIX} || "";
    my $url = join( "/", grep( $_ ne "", ( $ver, $prefix, $resource ) ) );
    return $url;
}

sub _api_site {

    my ( $key, $api, $config ) = @_;

    my $resource         = $api->{RESOURCE} || PL($key);
    my $verbs            = $api->{VERBS};
    my $stash            = $api->{STASH} || {};
    my $contoller        = $api->{CONTROLLER} || $resource;
    my $contoller_prefix = $config->{PREFIX} || "api";
    my $url              = _api_url( $resource, $config );



     push(@all_routes,{url=>"/" .$url  ,
                          methods=>"['GET']",
                          controller=>"$contoller_prefix-$contoller#get",
                          stash=>Dumper($stash)})
      if ( $verbs->{RETRIEVE} );

      push(@all_routes,{url=>"/" .$url."/:id" ,
                          methods=>"['GET']",
                          controller=>"$contoller_prefix-$contoller#get",
                          stash=>Dumper($stash)})
      if ( $verbs->{RETRIEVE} );

    
     push(@all_routes,{url=>"/" .$url  ,
                          methods=>"['POST']",
                          controller=>"$contoller_prefix-$contoller#create",
                          stash=>Dumper($stash)})
      if ( $verbs->{CREATE} );

     push(@all_routes,{url=>"/" .$url. "/:id",
                          methods=>"['PATCH']",
                          controller=>"$contoller_prefix-$contoller#update",
                          stash=>Dumper($stash)})
      if ( $verbs->{UPDATE} );

     push(@all_routes,{url=>"/" .$url. "/:id",
                          methods=>"['PUT']",
                          controller=>"$contoller_prefix-$contoller#replace",
                          stash=>Dumper($stash)})
      if ( $verbs->{REPLACE} );

     push(@all_routes,{url=>"/" .$url. "/:id",
                          methods=>"['DELETE']",
                          controller=>"$contoller_prefix-$contoller#delete",
                          stash=>Dumper($stash)})
      if ( $verbs->{DELETE} );

    return $resource;

}

sub _sub_api_site {

    my ( $parent, $key, $api, $config ) = @_;

    my $child_resource   = $api->{RESOURCE} || PL($key);
    my $verbs            = $api->{VERBS};
    my $stash            = $api->{STASH} || {};
    my $child_controller = $api->{CONTROLLER} || $child_resource;
    my $contoller_prefix = $config->{PREFIX} || "api";
    my $url              = _api_url( $parent, $config );
    $stash->{parent} = $parent;
    $stash->{child}  = $child_resource;


    push(@all_routes,{url=>"/" .$url ."/:id/" . $child_resource,
                          methods=>"['GET']",
                          controller=>"$contoller_prefix-$parent#$child_resource#get",
                          stash=>Dumper($stash)})
      if ( $verbs->{RETRIEVE} );

    push(@all_routes,{url=>"/" .$url. "/:id/" . $child_resource."/:child_id",
                          methods=>"['GET']",
                          controller=>"$contoller_prefix-$child_controller#get",
                          stash=>Dumper($stash)})
      if ( $verbs->{RETRIEVE} );

    push(@all_routes,{url=>"/" .$url. "/:id/" . $child_resource,
                          methods=>"['POST']",
                          controller=>"$contoller_prefix-$child_controller#create",
                          stash=>Dumper($stash)})
      if ( $verbs->{CREATE} );

    push(@all_routes,{url=>"/" .$url. "/:id/" . $child_resource."/:child_id",
                          methods=>"['PUT']",
                          controller=>"$contoller_prefix-$child_controller#replace",
                          stash=>Dumper($stash)})
    if ( $verbs->{REPLACE} );

    push(@all_routes,{url=>"/" .$url. "/:id/" . $child_resource."/:child_id",
                          methods=>"['PATCH']",
                          controller=>"$contoller_prefix-$child_controller#update",
                          stash=>Dumper($stash)})
     if ( $verbs->{UPDATE} );

    push(@all_routes,{url=>"/" .$url. "/:id/" . $child_resource."/:child_id",
                          methods=>"['DELETE']",
                          controller=>"$contoller_prefix-$child_controller#delete",
                          stash=>Dumper($stash)})
      if ( $verbs->{DELETE} );
}

sub _sub_inline_api_site {

    my ( $parent, $key, $api, $config ) = @_;
    my $verbs          = $api->{VERBS};
    my $child_resource = $api->{RESOURCE} || PL($key);    #this should be action
    my $stash          = $api->{STASH} || {};
    my $action           = $api->{ACTION} || $child_resource;
    my $contoller_prefix = $config->{PREFIX} || "api";
    my $url              = _api_url( $parent, $config );
    $stash->{parent} = $parent;
    $stash->{child}  = $child_resource;

    push(@all_routes,{url=>"/" .$url. "/:id/" . $child_resource,
                          methods=>"['GET']",
                          controller=>"$contoller_prefix-$parent#$action",
                          stash=>Dumper($stash)})
      if ( $verbs->{RETRIEVE} );

    push(@all_routes,{url=>"/" .$url. "/:id/" . $child_resource,
                          methods=>"['PATCH']",
                          controller=>"$contoller_prefix-$parent#$action",
                          stash=>Dumper($stash)})
   
      if ( $verbs->{UPDATE} );

}
   

# Ooh. "Big Pink." It's the only gum with the breath-freshening power of ham. 

1;

=pod
 
=head1 NAME
 
Mojolicious::Command::generate::routes_restsful_just_routes - Generate just the perl code for routes from a  Mojolicious::Plugin::Routes::Restful HASH
 
=head1 SYNOPSIS
 
  my $commands = Mojolicious::Commands->new;
  my $gen = Mojolicious::Command::generate::routes_restsful_just_routes->new;
  $gen->run('RoutesRestfulCode',{ 
            CONFIG => { Namespaces => ['RouteRestfulApp::Controller'] },
            PARENT => {...
 
=head1 DESCRIPTION
 
Give L<Mojolicious::Command::generate::routes_restsful_just_routes> a hash that was created for L<Mojolicious::Plugin::Routes::Restful>
it will generate the code for the described routes.  
  
It is not intended to use this generator from the command line. Best to use it in a script. See the script dir for an example.

See L<Mojolicious::Plugin::Routes::Restful> for details on how to make a Hash for this generator.
 
=head1 ATTRIBUTES
 
L<Mojolicious::Command::generate::app> inherits all attributes from
L<Mojolicious::Command> and implements the following new ones.
 
=head2 description
 
  my $description = $app->description;
  $app            = $app->description('Foo');
 
Short description of this command, used for the command list.
 
=head2 usage
 
  my $usage = $app->usage;
  $app      = $app->usage('Foo');
 
Usage information for this command, used for the help screen.
 
=head1 METHODS
 
L<Mojolicious::Command::generate::routes_restsful> inherits all methods from
L<Mojolicious::Command> and implements the following new ones.
 
=head2 run
 
  $app->run($name,$hash);
 
Generates the code. Where $name is the name of the file you want to create, and $hash is a valid L<Mojolicious::Plugin::Routes::Restful> hash.
 
=head1 SEE ALSO
 
L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicious.org>, L<Mojolicious::Plugin::Routes::Restful>.

=head1 LICENSE AND COPYRIGHT

Copyright 2016 John Scoles.
This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.
See http://dev.perl.org/licenses/ for more information.

=cut

__DATA__
 

@@ just_code
% my $routes = shift;

% foreach my $route (@{$routes}){ 
   $r->route("<%=$route->{url}%>")->via(<%=$route->{methods}%>)->to( "<%=$route->{controller}%>", <%=$route->{stash}%>);
% }
#This code was generated with  "Mojolicious::Command::generate::routes_restful_just_routes.pm"
