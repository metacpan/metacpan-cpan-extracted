package Blog;
use Mojo::Base 'Mojolicious';

# This method will run once at server start
sub startup {
  my $self = shift;
  $self->plugin('RoutesConfig',
                {file => $self->home->child('etc/routes_missing.conf')});

  # Load configuration from hash returned by "my_app.conf"
  my $config = $self->plugin('Config');

  # Router
  my $r = $self->routes;

  # Normal route to controller
  $r->get('/')->to('example#welcome');

  $self->plugin('RoutesConfig', $config);
  $self->plugin(PODViewer => {default_module => 'Blog'});

  # Documentation browser under "/perldoc"
  # $self->plugin('PODRenderer') if $config->{perldoc};
  $self->plugin('RoutesConfig',
                {file => $self->home->child('etc/routes_not_ARRAY.conf')});
  $self->plugin('RoutesConfig',
                {file => $self->home->child('etc/complex_routes.conf')});
}

1;


=encoding utf8

=head1 NAME

Blog - an example Mojolicious application

=head1 SYNOPSIS


# Start command line interface for application

    Mojolicious::Commands->start_app('Blog');

=head1 DESCRIPTION

This is an example application used to test L<Mojolicious::Plugin::RoutesConfig>.

=head1 METHODS

L<Blog> inherits all methods from L<Mojolicious> and implements
the following new ones.

=head2 startup

    my $app = Blog->new->startup;

Starts the application. Adds hooks, prepares C<$app-E<gt>routes> for use, loads
configuration files and applies settings from them, loads plugins, sets default
paths, and returns the application instance.

=head1 COPYRIGHT

This program is free software licensed under the Artistic License 2.0.

The full text of the license can be found in the
LICENSE file included with this module.

This distribution contains other free software which belongs to their
respective authors.


=head1 SEE ALSO

L<Slovo> has a pretty advanced routes configuration using
L<Mojolicious::Plugin::RoutesConfig>.  Please look at
Slovo/lib/Slovo/resources/etc/routes.conf. See also  L<Mojolicious>,
L<Mojolicious::Guides::Routing>

=cut
