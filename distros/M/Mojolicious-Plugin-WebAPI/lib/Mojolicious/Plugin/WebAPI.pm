package Mojolicious::Plugin::WebAPI;

# ABSTRACT: Mojolicious::Plugin::WebAPI - mount WebAPI::DBIC in your Mojolicious app

use Mojo::Base 'Mojolicious::Plugin';

use WebAPI::DBIC::WebApp;
use WebAPI::DBIC::RouteMaker;
use Mojolicious::Plugin::WebAPI::Proxy;
 
our $VERSION = '0.04';
 
sub register {
    my ($self, $app, $conf) = @_;

    my $schema = delete $conf->{schema};
    my $route  = delete $conf->{route};
    my $debug  = delete $conf->{debug};

    if ( $debug ) {
        $ENV{WEBAPI_DBIC_DEBUG} = 1;
        $app->log->debug( "Base route: " . $route->to_string );
    }

    my %opts;
    if ( $conf->{resource_opts} ) {
        $opts{route_maker} = WebAPI::DBIC::RouteMaker->new(
            %{ $conf->{resource_opts} },
        );
    }

    my $psgi_app = WebAPI::DBIC::WebApp->new({
        %opts,
        routes => [ map { $schema->source($_) } $schema->sources ],
    })->to_psgi_app;

    $route->detour(
        app => Mojolicious::Plugin::WebAPI::Proxy->new(
            app  => $psgi_app,
            base => $route->to_string,
        ),
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::WebAPI - Mojolicious::Plugin::WebAPI - mount WebAPI::DBIC in your Mojolicious app

=head1 VERSION

version 0.04

=head1 SYNOPSIS

  # load DBIx::Class schema
  use MyApp::Schema;
  my $schema = MyApp::Schema->connect('DBI:SQLite:test.db');
  
  # create base route for api
  my $route = $self->routes->route('/api/v0');
  $self->plugin('WebAPI' => {
      schema => $schema,
      route  => $route,
  });



  # now with a route that can check for authentication
  use MyApp::Schema;
  my $schema = MyApp::Schema->connect('DBI:SQLite:test.db');
  
  # create base route for api
  my $auth  = $self->routes->auth('/')->to('auth#test');
  my $route = $auth->route('/api/v0');
  $self->plugin('WebAPI' => {
      schema => $schema,
      route  => $route,
  });


  # disable http basic auth
  $self->plugin('WebAPI' => {
    schema => $schema,
    route  => $route,

    resource_opts => {
      resource_default_args => {
        http_auth_type => 'none',
      },
    },
  });

=head1 DESCRIPTION

This is just the glue to mount the webapi into your application. The
hard work is done by L<WebAPI::DBIC>. The code for C<Proxy.pm> is
mostly from L<Mojolicious::Plugin::MountPSGI>.

=head1 CONFIGURATION

You can pass the following options when loading the plugin:

=head2 schema

=head2 route

=head2 resource_opts

Here you can set all options that can be used to change the behaviour
of L<WebAPI::DBIC::RouteMaker>.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
