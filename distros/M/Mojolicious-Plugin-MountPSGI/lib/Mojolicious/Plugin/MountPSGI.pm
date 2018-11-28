package Mojolicious::Plugin::MountPSGI;
use Mojo::Base 'Mojolicious::Plugin';
use Mojolicious::Plugin::MountPSGI::Proxy;


our $VERSION = '0.14';

sub register {
  my ($self, $app, $conf) = @_;

  my $rewrite = delete $conf->{rewrite};

  # Extract host and path
  my $prefix = (keys %$conf)[0];
  my ($host, $path);
  if ($prefix =~ /^(\*\.)?([^\/]+)(\/.*)?$/) {
    $host = quotemeta $2;
    $host = "(?:.*\\.)?$host" if $1;
    $path = $3;
    $path = '/' unless defined $path;
    $host = qr/^$host$/i;
  }
  else { $path = $prefix }

  my %args = (
    rewrite => $rewrite ? $path : undef,
  );

  unless ($ENV{PLACK_ENV}) {
    $args{mode} = $app->mode;
  }

  my $psgi = $conf->{$prefix};
  if (ref $psgi) {
    $args{app} = $psgi;
  } else {
    unless (-r $psgi) {
      my $abs = $app->home->rel_file($psgi);
      $psgi = $abs if -r $abs;
    }
    $args{script} = $psgi;
  }

  my $proxy = Mojolicious::Plugin::MountPSGI::Proxy->new(%args);

  # Generate route
  my $route = $app->routes->route($path)->detour(app => $proxy);
  $route->over(host => $host) if $host;

  return $route;
}


1;
__END__

=encoding utf8

=head1 NAME

Mojolicious::Plugin::MountPSGI - Mount PSGI apps

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('MountPSGI', { '/' => 'ext/MyApp/app.psgi'});

  # Mojolicious::Lite
  plugin 'MountPSGI', { '/' => 'ext/MyApp/app.psgi' };

  # rewrite the path so the psgi app doesn't see the mount point
  # thus app.psgi sees / when /mount is visited
  plugin 'MountPSGI', { '/mount' => 'ext/MyApp/app.psgi', rewrite => 1 };

=head1 DESCRIPTION

L<Mojolicious::Plugin::MountPSGI> lets you mount any PSGI app
inside a Mojolicious app. For instance you could use this to
deploy your PSGI app under hypnotoad, or to include a PSGI
app inside a path inside your Mojo app.

The key given is the route under which to mount the app. The
value is either a PSGI application or a string which resolves
to an instance via L<Plack::Util/load_psgi>.

One additional option is C<rewrite> which if set to a true value
will rewrite the C<PATH_INFO> and C<SCRIPT_NAME> values in the env
hash so that the application does not see the mount point in
its request path. This uses the mechanism as described by L<Plack::App::URLMap>.

=head1 CAVEATS

Due to the way Mojolicious parses multipart requests, the original request body
is not available to pass to the PSGI application. As a stopgap measure this
plugin rebuilds the request from its parts at what is likely a huge cost in
L<performance|https://github.com/marcusramberg/Mojolicious-Plugin-MountPSGI/issues/8>.
There has been discussion about L<"adding proxying
primatives"|https://github.com/mojolicious/mojo/issues/1295> to Mojolicious
which would likely be useful in resolving this performance hit.

If C<PLACK_ENV> is not otherwise set, the L<Mojolicious/mode> will be used
while loading the application script and during synchronous responses. For
delayed responses, the plugin cannot ensure that it will be set. Applications
should fetch their C<PLACK_ENV> before requesting a delayed response and manage
it appropriately.

=head1 METHODS

L<Mojolicious::Plugin::MountPSGI> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 C<register>

  $plugin->register;

Register plugin in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=head1 CONTRIBUTORS

=over 2

Joel Berger (jberger)

Peter Valdemar Mørch (pmorch)

Graham Knop (haarg)

=back

=head1 COPYRIGHT

Most of this module was assembled from the Mojo mount plugin and the
Mojolicious-Plugin-PlackMiddleware plugin. Copyright on that code belongs
to the authors.

The remainder is (C) 2011-2015 Marcus Ramberg and the C</CONTRIBUTORS> above.

=head1 LICENSE

Licensed under the same terms as Perl itself.

=cut
