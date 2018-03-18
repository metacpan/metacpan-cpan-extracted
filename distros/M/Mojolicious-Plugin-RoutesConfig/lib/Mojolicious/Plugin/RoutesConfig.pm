package Mojolicious::Plugin::RoutesConfig;
use Mojo::Base 'Mojolicious::Plugin::Config';
use List::Util qw(first);

our $VERSION   = 0.03;
our $AUTHORITY = 'cpan:BEROV';

sub register {
  my ($self, $app, $conf) = @_;
  my $file = $conf->{file};
  my $file_msg = ($file ? ' in file ' . $file : '');
  $conf = $self->SUPER::register($app, $conf);
  $app->log->warn('No routes definitions found' . $file_msg . '...')
    && return $conf
    unless exists $conf->{routes};
  $app->log->warn(  '"routes" key must point to an ARRAY reference '
                  . 'of routes descriptions'
                  . $file_msg . '...')
    && return $conf
    unless ref $conf->{routes} eq 'ARRAY';

  $self->_generate_routes($app, $conf->{routes}, $file_msg);
  return $conf;
}

#generates routes (TODO:recursively?)
sub _generate_routes {
  my ($self, $app, $routes_conf, $file_msg) = @_;
  my $routes  = $app->routes;
  my $init_rx = '^any|route|get|post|patch|put|delete|options$';
  for my $rconf (@$routes_conf) {
    my $init_method = first(sub { $_ =~ /$init_rx/; }, keys %$rconf);
    unless ($init_method) {
      $app->log->warn( "Malformed route description$file_msg!!!$/"
                     . " Could not find route initialisation method, matching$/"
                     . " /$init_rx/$/"
                     . " in definition$/"
                     . $app->dumper($rconf)
                     . ". Skipping...");
      next;
    }
    my $init_params = $rconf->{$init_method};
    my $route
      = $routes->$init_method(
                 ref $init_params eq 'ARRAY'
                 ? @$init_params
                 : (ref $init_params eq 'HASH' ? %$init_params : $init_params));

    for my $method (keys %$rconf) {
      next if $method eq $init_method;
      my $params = $rconf->{$method};
      $route->can($method) || do {
        $app->log->warn("Malformed route description$file_msg!!!$/"
          . " for route definition$/"
          . $app->dumper($rconf)
          . qq|Can't locate object method "$method" via package "${\ ref $route}"!$/|
          . ' Removing route '
          . (ref $init_params eq 'ARRAY' ? $init_params->[0] : $init_params));
        $route->remove();
        last;
      };

      $route->$method(
                      ref $params eq 'ARRAY'
                      ? @$params
                      : (ref $params eq 'HASH' ? %$params : $params));
    }
  }
  return;
}

=encoding utf8

=head1 NAME

Mojolicious::Plugin::RoutesConfig - Describe routes in configuration

=head1 SYNOPSIS

  # Create $MOJO_HOME/etc/routes.conf and describe your routes
  # or do it directly in $MOJO_HOME/${\ $app->moniker }.conf
  {
    routes => [
      {get  => '/groups', to => 'groups#list', name => 'list_groups'},
      {post => '/groups', to => 'groups#create'},
      {any => {[qw(GET POST)] => '/users'}, to => 'users#list_or_create'},
    ],
  }

  # Mojolicious
  my $config = $app->plugin('Config');
  # or even
  my $config = $app->plugin('RoutesConfig');
  # or
  $app->plugin('RoutesConfig', $config);
  $app->plugin('RoutesConfig', {file => $app->home->child('etc/routes_admin.conf')});
  $app->plugin('RoutesConfig', {file => $app->home->child('etc/routes_site.conf')});

  # Mojolicious::Lite
  my $config = plugin 'Config';
  plugin 'RoutesConfig', $config;
  plugin 'RoutesConfig', {file => app->home->child('etc/routes_admin.conf')};
  plugin 'RoutesConfig', {file => app->home->child('etc/routes_site.conf')};

=head1 DESCRIPTION

L<Mojolicious::Plugin::RoutesConfig> allows you to define your routes in
configuration file or in a separate file, for example
C<$MOJO_HOME/etc/plugins/routes.conf>. This way you can quickly enable and
disable parts of your application without editing its source code.

The routes are described the same way as you would generate them imperatively,
just instead of methods you use method names as keys and suitable references as
values which will be dereferenced and passed as arguments to the respective
method. For allowed keys look at L<Mojolicious::Routes::Route/METHODS>. Of
course only relatively simple cases are handled. Complex logic is left to the
programmer. Still you can have all your routes defined in the configuration
file as it is Perl and you have the C<app> object available.

=head1 METHODS

L<Mojolicious::Plugin::RoutesConfig> inherits all methods from L<Mojolicious::Plugin::Config> and implements the following new ones.

=head2 register

  my $config = $plugin->register(Mojolicious->new, $config);
  my $config = $plugin->register($app, {file => '/etc/app_routes.conf'});

Register the plugin in L<Mojolicious> application and generate routes. 

=head1 AUTHOR

    Красимир Беров
    CPAN ID: BEROV
    berov ат cpan точка org
    http://i-can.eu

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the terms of Artistic License 2.0.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

L<Mojolicious::Routes>, L<Mojolicious::Routes::Route>, L<Mojolicious::Plugin::Config>

=cut

#################### main pod documentation end ###################


1;

