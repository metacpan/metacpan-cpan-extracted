package Mojolicious::Plugin::YamlRoutes;

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::File 'path';
use YAML::XS 'LoadFile';

our $VERSION = '0.01';

sub register {
    my ($self, $app, $conf) = @_;

    return $self->_read_yaml($app,$app->home->rel_file($conf->{file})) if $conf->{file};

    if ( $conf->{directory} ) {
	my $dir = $app->home->rel_file($conf->{directory});

	$dir .= '/' unless $dir =~ /\/$/;

	## Check is directory
	unless ( -d $dir ) {
	    $app->log->debug((caller(0))[3].' => Directory not found : '.$dir);
	    return;
	}
	
	$self->_dir_yaml($app,$dir);
    }

    ## No args register helpers
    $app->helper(RouteYaml => \&_read_yaml);
    
}

sub _dir_yaml {
    my ($self, $app, $dir) = @_;
    
    for my $path ( path($dir)->list->each ) {
	next unless $path->basename =~ /\.yaml$/;
	$app = $self->_read_yaml($app,$dir.$path->basename);
    }    
}

sub _read_yaml {
    my ($self, $app, $yaml) = @_;

    unless ( -e $yaml ) {
	$app->log->debug((caller(0))[3].'Error file not found : '.$yaml);
	return;
    }

    my $RoutesYaml = LoadFile $yaml;

    foreach my $routes_init ( sort keys %{ $RoutesYaml->{routes} } ){

	foreach my $menu_item ( sort keys %{ $RoutesYaml->{routes}->{$routes_init} } ){

	    # GET by default
	    $RoutesYaml->{routes}->{$routes_init}->{$menu_item}->{via} = 'GET' unless $RoutesYaml->{routes}->{$routes_init}->{$menu_item}->{via};

	    if ( $RoutesYaml->{routes}->{$routes_init}->{$menu_item}->{via} eq 'GET' ) {
		$app->routes->get( $RoutesYaml->{routes}->{$routes_init}->{$menu_item}->{route})->to(controller => $routes_init, action => $menu_item );
	    } elsif ( $RoutesYaml->{routes}->{$routes_init}->{$menu_item}->{via} eq 'POST' ) {
		$app->routes->post( $RoutesYaml->{routes}->{$routes_init}->{$menu_item}->{route})->to( controller => $routes_init, action => $menu_item );
	    } else {
		$app->routes->any( ['GET', 'POST'] => $RoutesYaml->{routes}->{$routes_init}->{$menu_item}->{route})->to( controller => $routes_init, action => $menu_item );
	    }

	    if ( $RoutesYaml->{routes}->{$routes_init}->{$menu_item}->{r0} ) {
		say qq{$RoutesYaml->{routes}->{$routes_init}->{$menu_item}->{route} - $routes_init - $menu_item};
		$app->routes->get( $RoutesYaml->{routes}->{$routes_init}->{$menu_item}->{r0})->any( ['GET', 'POST'] => $RoutesYaml->{routes}->{$routes_init}->{$menu_item}->{route})->to( controller => $routes_init , action => $menu_item );
	    }
	   
	}
    }

    return $app;
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::YamlRoutes - Generates routes from a yaml file

=head1 SYNOPSIS

  
  $self->plugin(YamlRoutes => { directory => 'config/routes/' } );
  $self->plugin(YamlRoutes => { file => 'routes.yaml'} );

  $self->plugin(YamlRoutes);

=head1 DESCRIPTION

L<Mojolicious::Plugin::YamlRoutes> Generate routes in Mojoliciouse based a yaml file

By default all http methods are GET can be force in the var 'via'.

routes:
 Example:
  Tester:
   route: /tester
 Example::Tester:
  Tester:
   route: /example/teste
  Post:
   route: /tester/post
   via: POST
  Any:
   route: /tester/any
   via: ANY

=head1 METHODS

L<Mojolicious::Plugin::YamlRoutes> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<https://mojolicious.org>.

=cut
