package Mojolicious::Command::generate::routes_restsful;
use Lingua::EN::Inflect 'PL';
use Mojo::Base 'Mojolicious::Command';

use Mojo::Util qw(class_to_file class_to_path camelize class_to_path);

has description =>
  'Generate Mojolicious App using a Mojolicious::Plugin::Routes::Restful hash';
has usage =>
"Usage: $0 generate Stub App with a Mojolicious::Plugin::Routes::Restful hash\n";

our $VERSION   = '0.0.2';
our $site      = {};
our $site_api  = {};
our @site_urls = ();
our %api_urls  = ();
use Data::Dumper;

sub run {
    my ( $self, $class, $in_routes ) = @_;

    die <<EOF unless $class =~ /^[A-Z](?:\w|::)+$/;
Your application name has to be a well formed (CamelCase) Perl module name
like "RoutesRestfulApp".
EOF

    # Script

    for my $sub_ref (qw/ PARENT CONFIG /) {
        die __PACKAGE__, ": missing '$sub_ref' hash in parameters\n"
          unless exists( $in_routes->{$sub_ref} );
    }

    my $config = $in_routes->{CONFIG};

    my $routes     = $in_routes->{PARENT};
    my @namespaces = ( $class . "::Controller" );

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
    my $name = class_to_file $class;
    $self->render_to_rel_file( 'mojo', "$name/script/$name", $class, $routes );
    $self->chmod_rel_file( "$name/script/$name", 0744 );

    # # content Controllers
    foreach my $key ( keys( %{$site} ) ) {
        my $controller = camelize($class) . "::Controller::" . camelize($key);
        push( @namespaces, $controller );
        my $path = class_to_path $controller;
        $self->render_to_rel_file( 'controller', "$name/lib/$path", $controller,
            $site->{$key} );

        # Templates
        foreach my $action ( keys( %{ $site->{$key} } ) ) {
            my $dir =
              substr( class_to_path( camelize( lcfirst($key) ) ), 0, -3 );

            $self->render_to_rel_file(
                'page',
                "$name/templates/" . $dir . "/" . lcfirst($action) . ".html.ep",
                $dir,
                $action
            );
        }
    }

    # API controllers

    foreach my $key ( keys( %{$site_api} ) ) {
        my $controller = camelize($class) . "::Controller::" . camelize($key);
        push( @namespaces, $controller );

        my $path = class_to_path $controller;
        $self->render_to_rel_file(
            'api_controller', "$name/lib/$path",
            $controller,      $site_api->{$key}
        );

    }

    $in_routes->{CONFIG}->{NAMESPACES} = \@namespaces;
    $Data::Dumper::Indent              = 1;
    $Data::Dumper::Terse               = 1;
    my $str_routes = Dumper($in_routes);

    my $app = class_to_path $class;
    $self->render_to_rel_file( 'appclass', "$name/lib/$app", $class,
        $str_routes );

    $self->render_to_rel_file( 'api_test', "$name/t/api_basic.t", $class,
        \%api_urls );

    # Static file
    $self->render_to_rel_file( 'static', "$name/public/index.html" );

}

sub _make_site {

    my ( $type, $key, $route, $config, $parent, $resource, $parent_stash ) = @_;

    my $route_stash = $route->{STASH} || {};
    $route_stash = { %{$route_stash}, %{$parent_stash} }
      if ($parent_stash);
    my $action = $route->{ACTION} || "show";

    my $controller = $route->{CONTROLLER} || $key;

    if ( $type eq 'PARENT' ) {

        $resource = _api_site( $key, $route->{API}, $config->{API} )
          if ( exists( $route->{API} ) );

        return $resource || $key
          if ( exists( $route->{API_ONLY} ) );

        push( @site_urls, "/$key" )
          unless ( exists( $route->{NO_ROOT} ) );

        push( @site_urls, "/$key/1" )
          unless ( exists( $route->{NO_ID} ) );

        $site->{$controller}->{$action} = 1;

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
            push( @site_urls, "/$parent/$key" );
        }
        else {
            push( @site_urls, "/$parent/1/$key" );
        }
        $site->{$controller}->{$action} = $parent;
    }
    elsif ( $type eq 'CHILD' ) {

        _sub_api_site( $resource, $key, $route->{API}, $config->{API} )
          if ( exists( $route->{API} ) );

        return
          if ( exists( $route->{API_ONLY} ) );

        $action = $route->{ACTION} || $key;
        push( @site_urls, "/$parent/1/$key" );
        push( @site_urls, "/$parent/1/$key/1" );
        $site->{$controller}->{$action} = $parent;

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

    $site_api->{"$contoller_prefix-$contoller"}->{get} = 1
      if ( $verbs->{RETRIEVE} );

    push( @{ $api_urls{GET} }, "/" . $url )
      if ( $verbs->{RETRIEVE} );

    push( @{ $api_urls{GET} }, "/" . $url . "/1" )
      if ( $verbs->{RETRIEVE} );

    $site_api->{"$contoller_prefix-$contoller"}->{create} = 1
      if ( $verbs->{CREATE} );

    push( @{ $api_urls{POST} }, ( "/" . $url ) )
      if ( $verbs->{CREATE} );

    $site_api->{"$contoller_prefix-$contoller"}->{update} = 1
      if ( $verbs->{UPDATE} );

    push( @{ $api_urls{PATCH} }, ( "/" . $url . "/1" ) )
      if ( $verbs->{UPDATE} );

    $site_api->{"$contoller_prefix-$contoller"}->{replace} = 1
      if ( $verbs->{REPLACE} );

    push( @{ $api_urls{PUT} }, ( "/" . $url . "/1" ) )
      if ( $verbs->{REPLACE} );

    $site_api->{"$contoller_prefix-$contoller"}->{delete} = 1
      if ( $verbs->{DELETE} );

    push( @{ $api_urls{POST} }, ( "/" . $url . "/1" ) )
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

    $site_api->{"$contoller_prefix-$parent"}->{$child_resource} = 1
      if ( $verbs->{RETRIEVE} );

    $site_api->{"$contoller_prefix-$child_controller"}->{get} = 1
      if ( $verbs->{RETRIEVE} );

    push( @{ $api_urls{GET} }, "/" . $url . "/1/" . $child_resource )
      if ( $verbs->{RETRIEVE} );

    push( @{ $api_urls{GET} }, "/" . $url . "/1/" . $child_resource . "/1" )
      if ( $verbs->{RETRIEVE} );

    $site_api->{"$contoller_prefix-$child_controller"}->{create} = 1
      if ( $verbs->{CREATE} );

    push( @{ $api_urls{POST} }, "/" . $url . "/1/" . $child_resource )
      if ( $verbs->{CREATE} );

    $site_api->{"$contoller_prefix-$child_controller"}->{replace} = 1
      if ( $verbs->{REPLACE} );

    push( @{ $api_urls{PUT} }, "/" . $url . "/1/" . $child_resource . "/1" )
      if ( $verbs->{REPLACE} );

    $site_api->{"$contoller_prefix-$child_controller"}->{update} = 1
      if ( $verbs->{UPDATE} );

    push( @{ $api_urls{PATCH} }, "/" . $url . "/1/" . $child_resource . "/1" )
      if ( $verbs->{UPDATE} );

    $site_api->{"$contoller_prefix-$child_controller"}->{delete} = 1
      if ( $verbs->{DELETE} );

    push( @{ $api_urls{DELETE} }, "/" . $url . "/1/" . $child_resource . "/1" )
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

    $site_api->{"$contoller_prefix-$parent"}->{$action} = 1
      if ( $verbs->{RETRIEVE} );

    push( @{ $api_urls{RETRIEVE} }, "/" . $url . "/1/" . $child_resource )
      if ( $verbs->{RETRIEVE} );

    push( @{ $api_urls{UPDATE} }, "/" . $url . "/1/" . $child_resource )
      if ( $verbs->{UPDATE} );

    $site_api->{"$contoller_prefix-$parent"}->{$action} = 1
      if ( $verbs->{UPDATE} );

}

# Shut up friends.
# My internet browser heard us saying the word Fry and it found a movie about Philip J. Fry for us.
# It also opened my calendar to Friday and ordered me some french fries.
1;

=pod

 
=head1 NAME
 
Mojolicious::Command::generate::routes_restsful - Generate an App from a Mojolicious::Plugin::Routes::Restful HASH
 
=head1 SYNOPSIS
 
  my $commands = Mojolicious::Commands->new;
  my $gen = Mojolicious::Command::generate::routes_restsful->new;
  $gen->run('RoutesRestfulApp',{ 
            CONFIG => { Namespaces => ['RouteRestfulApp::Controller'] },
            PARENT => {...
 
=head1 DESCRIPTION
 
Give L<Mojolicious::Command::generate::routes_restsful> a hash that was created for L<Mojolicious::Plugin::Routes::Restful>
and it will generate a stub site for you.  You get a stub working in version of your app made up of

  An App Class
  Content Contollers
  API Controllers
  A Startup Script
  A Template set based on your content controlers
  A basic test suite for your API
  
Please note that this generator overwrites the NAMESPACE attribute of you hash.  It is not intended to use this generator from the command line.
Best to use it in a script. See the script dir for an example.

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
 
  $app->run($class,$hash);
 
Generates the App. Where $class is the name of the App you want to create, and $hash is a valid L<Mojolicious::Plugin::Routes::Restful> hash.

 
=head1 SEE ALSO
 
L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicious.org>, L<Mojolicious::Plugin::Routes::Restful>.
 
=cut

__DATA__
 
@@ mojo
% my $class = shift;
#!/usr/bin/env perl
 
use strict;
use warnings;
 
use FindBin;
BEGIN { unshift @INC, "$FindBin::Bin/../lib" }
use Mojolicious::Commands;
 
# Start command line interface for application
Mojolicious::Commands->start_app('<%= $class %>');
 
@@ appclass
% my $class  = shift;
% my $config = shift;
package <%= $class %>;
use Mojo::Base 'Mojolicious';
 
# This method will run once at server start
sub startup {
  my $self = shift;
 
 
  # Resetul Routes
  my $r = $self->plugin(
        "Routes::Restful",
             <%=$config%>
         );
}
 
1;
 
@@ controller
% my $class = shift;
% my $actions = shift;
package <%= $class %>;
use Mojo::Base 'Mojolicious::Controller';
 

% foreach my $action (keys(%{$actions})){ 
  
sub <%= $action %> {
  my $self = shift;
  
  #warn("<%=$class%>-><%=$action%> id=".$self->param('id'));
  #warn("Child =".$self->param('child').", Child_id=".$self->param('child_id'))
  #  if ($self->param('child'));
  
  $self->render(msg => '<%=$class %> with method=<%=$action %>');

}
#This page was generated with  "Mojolicious::Command::generate::routes_restful.pm"
% }
1;

@@ api_controller
% my $class = shift;
% my $actions = shift;
package <%= $class %>;
use Mojo::Base 'Mojolicious::Controller';
 
% foreach my $action (keys(%{$actions})){ 
  
sub <%= $action %> {
  my $self = shift;
  
  #warn("<%=$class%>-><%=$action%> id=".$self->param('id'));
  #warn("Child =".$self->param('child').", Child_id=".$self->param('child_id'))
  #  if ($self->param('child'));
 
   $self->render( json => {'<%=$class %>-<%=$action%>'=>'Stub!',id=>$self->param('id'),child_id=>$self->param('child_id')});

}
#This page was generated with  "Mojolicious::Command::generate::routes_restful.pm"
% }
1;
 
@@ static
<!DOCTYPE html>
<html>
  <head>
    <title>Welcome to the Mojolicious real-time web framework!</title>
  </head>
  <body>
    <h2>Welcome to the Mojolicious real-time web framework!</h2>
    This is the static document "public/index.html",
    <a href="/">click here</a> to get back to the start.
  </body>
</html>
 
@@ api_test
% my $class = shift;
% use Data::Dumper;
% my $routes = shift;

use Mojo::Base -strict;
 
use Test::More;
use Test::Mojo;
 
my $t = Test::Mojo->new('<%= $class %>');

% foreach my $method (keys(%{$routes})){
% foreach my $route (@{$routes->{$method}}){ 
   $t-><%=$method%>_ok('<%=$route%>')->status_is(200);
%#<%=$method%>_ok("<%=$route%>")->status_is(200);
% }
%}
done_testing();
1;

@@ layout
<!DOCTYPE html>
<html>
  <head><title><%%= title %></title></head>
  <body><%%= content %></body>
</html>
 
@@ page
% my $page = shift;
% my $action = shift;

%% layout 'default';
%% title 'Welcome to the <%=$page%>/<%=$action%> Template';




<h2>Welcome to the  <%=$page%>/<%=$action%> Template </h2>

<BR>
The content was generated by the controller class <B><%%= $msg %>.

<BR>
<BR>

This page was generated with  "Mojolicious::Command::generate::routes_restful.pm"<BR>
<%%= link_to 'click here' => url_for %> to reload the page 
__END__
