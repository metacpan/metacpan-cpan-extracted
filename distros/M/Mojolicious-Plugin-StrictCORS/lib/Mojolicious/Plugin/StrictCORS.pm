package Mojolicious::Plugin::StrictCORS;
use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = "0.02";
$VERSION = eval $VERSION;

use constant DEFAULT_MAX_AGE => 3600;

sub register {
  my ($self, $app, $conf) = @_;

  $conf->{max_age}  //= DEFAULT_MAX_AGE;
  $conf->{expose}   //= [];

  # Recursive get route params
  my $route_params = sub {
    my ($c) = @_;

    my $route = $c->match->endpoint;

    my %params;
    my @fields = qw/origin credentials expose methods headers/;

    while ($route) {
      for my $name (@fields) {
        next if exists $params{$name};
        next unless exists $route->to->{"cors_${name}"};

        $params{$name} = $route->to->{"cors_${name}"};
      }

      $route = $route->parent;
    }

    return \%params;
  };

  my $check_preflight = sub {
    my ($c) = @_;

    my $h = $c->req->headers;

    return 1 if $h->header('Origin') =~ qr/\S/ms
      and $h->header('Access-Control-Request-Method') =~ qr/\S/ms;

    return; # Fail
  };

  # Check Origin header
  my $check_origin = sub {
    my ($c, @allow) = @_;

    my $h = $c->req->headers;

    my $origin = $h->origin;
    return unless defined $origin;

    return $origin if grep { not ref $_ and $_ eq '*' } @allow;

    return $origin if grep {
      if    (not ref $_)          { lc $origin eq lc $_ }
      elsif (ref $_ eq 'Regexp')  { $origin =~ $_ }
      else  { die "Router 'cors_origin' param must be scalar or Regexp\n" }
    } @allow;

    $app->log->debug("Reject CORS Origin '$origin'");

    return; # Fail
  };

  # Check request method
  my $check_methods = sub {
    my ($c, @allow) = @_;

    my $h = $c->req->headers;

    my $method = $h->header('Access-Control-Request-Method');
    return unless defined $method;

    my $allow = join ", ", @allow;

    return $allow if grep {
      if    (not ref $_)  { uc $method eq uc $_ }
      else  { die "Router 'cors_methods' param must be scalar\n" }
    } @allow;

    $app->log->debug("Reject CORS Method '$method'");

    return; # Fail
  };

  # Check request headers
  my $check_headers = sub {
    my ($c, @allow) = @_;

    my $h = $c->req->headers;

    my @safe_headers = qw/
      Cache-Control
      Content-Language
      Content-Type
      Expires
      Last-Modified
      Pragma
    /;

    my %safe_headers = map { lc $_ => 1 } @safe_headers;
    my $allow = join ", ", @allow;

    my $headers = $h->header('Access-Control-Request-Headers');
    my @headers = map { lc } grep { $_ } split /,\s*/ms, $headers || '';

    return $allow unless @headers;

    return $allow unless grep {
      if    (not ref $_)  { not $safe_headers{ lc $_ } }
      else  { die "Router 'cors_headers' param must be scalar\n" }
    } @allow;

    $app->log->debug("Reject CORS Headers '$headers'");

    return; # Fail
  };

  $app->hook(around_action => sub {
    my ($next, $c, $action, $last) = @_;

    # Only endpoints intrested
    return $next->() unless $last;

    # Do not process preflight requests
    return $next->() if $c->req->method eq 'OPTIONS';

    my $params = $route_params->($c);

    # Do not process routes without cors_origin configured
    my @params_origin = @{$params->{origin} //= []};
    return $next->() unless @params_origin;

    my $h = $c->res->headers;
    $h->append('Vary' => 'Origin');

    my $origin = $check_origin->($c, @params_origin);
    return $next->() unless defined $origin;

    $h->header('Access-Control-Allow-Origin' => $origin);

    $h->header('Access-Control-Allow-Credentials' => 'true')
      if $params->{credentials} //= 0;

    my @params_expose = (@{$conf->{expose}}, @{$params->{expose} //= []});
    if (@params_expose) {
      my $params_expose = join ", ", @params_expose;
      $h->header('Access-Control-Expose-Headers' => $params_expose);
    }

    $app->log->debug("Allow CORS Origin '$origin'");

    return $next->();
  });

  # CORS Preflight
  $app->routes->add_shortcut(cors => sub {
    my ($r, @args) = @_;

    $r->options(@args)->to(
      cb => sub {
        my ($c) = @_;

        return $c->render(status => 204, data => '')
          unless $check_preflight->($c);

        my $params = $route_params->($c);

        my @params_origin = @{$params->{origin} //= []};
        return $c->render(status => 204, data => '')
          unless @params_origin;

        my $h = $c->res->headers;
        $h->append('Vary' => 'Origin');

        my $origin = $check_origin->($c, @params_origin);
        return $c->render(status => 204, data => '')
          unless defined $origin;

        my @params_methods = @{$params->{methods} //= []};
        push @params_methods, 'HEAD'
          if grep { uc $_ eq 'GET' } @params_methods
            and not grep { uc $_ eq 'HEAD' } @params_methods;
        return $c->render(status => 204, data => '')
          unless @params_methods;

        my $methods = $check_methods->($c, @params_methods);
        return $c->render(status => 204, data => '')
          unless defined $methods;

        my @params_headers = @{$params->{headers} //= []};

        my $headers = $check_headers->($c, @params_headers);
        return $c->render(status => 204, data => '')
          unless defined $headers;

        $h->header('Access-Control-Allow-Origin'  => $origin);
        $h->header('Access-Control-Allow-Methods' => $methods);

        $h->header('Access-Control-Allow-Headers' => $headers)
          if $headers;

        $h->header('Access-Control-Allow-Credentials' => 'true')
          if $params->{credentials} //= 0;

        $h->header('Access-Control-Max-Age' => $conf->{max_age});

        $app->log->debug("Accept CORS '$origin' => '$methods'");
        return $c->render(status => 204, data => '');
      }
    );
  });
}

1;

__END__

=encoding utf8

=head1 NAME

Mojolicious::Plugin::StrictCORS - Strict and secure control over CORS

=head1 SYNOPSIS

  # Mojolicious app
  sub startup {
    my ($app) = @_;

    # load and configure
    $app->plugin('StrictCORS');
    $app->plugin('StrictCORS', {
      max_age => -1,
      expose  => ['X-Message']
    });

    # set app-wide CORS defaults
    $app->routes->to(cors_credentials => 1);

    # set default CORS options for nested routes
    $r = $r->under(..., { cors_origin => ['*'] }, ...);

    # set CORS options for this route (at least "origin" option must be
    # defined to allow CORS, either here or in parent routes)
    $r->get(..., { cors_origin => ['*'] }, ...);
    $r->route(...)->to(cors_origin => ['*']);

    # allow non-simple (with preflight) CORS on this route
    $r->cors(...);

=head1 DESCRIPTION

L<Mojolicious::Plugin::StrictCORS> is a plugin that allow you to configure
Cross Origin Resource Sharing for routes in L<Mojolicious> app.

Implements this spec: L<http://www.w3.org/TR/2014/REC-cors-20140116/>.

This module is based on Powerman's CORS implementation:
L<https://github.com/powerman/perl-Mojolicious-Plugin-SecureCORS>
But this module no longer updated, so this one wos created.

=head2 SECURITY

Don't use the lazy cors_origin => ['*'] for resources which should be
available only for intranet or which behave differently when accessed from
intranet - otherwise malicious website opened in browser running on
workstation in intranet will get access to these resources.

Don't use the lazy cors_origin => ['*'] for resources which should be
available only from some known websites - otherwise other malicious website
will be able to attack your site by injecting JavaScript into the victim's
browser.

=head1 INTERFACE

=head2 CORS options

To allow CORS on some route you should define relevant CORS options for
that route. These options will be processed automatically using
L<Mojolicious/"around_action"> hook and result in adding corresponding HTTP
headers to the response.

Options should be added into default parameters for the route or it parent
routes. Defining CORS options on parent route allow you to set some
predefined defaults for their nested routes.

=over

=item cors_origin => ['*']

=item cors_origin => ["http://example.com"]

=item cors_origin => ["https://example.com", "http://example.com:8080"]

=item cors_origin => [qr/\.local\z/ms]

=item cors_origin => undef >> (default)

This option is required to enable CORS support for the route.

Only matched origins will be allowed to process returned response
(C<['*']> will match any origin).

When set to undef no origins will match, so it effectively disable
CORS support (may be useful if you've set this option value on parent
route).

=item cors_credentials => 1

=item cors_credentials => undef (default)

While handling preflight request true/false value will tell browser to
send or not send credentials (cookies, http auth, SSL certificate) with
actual request.

While handling simple/actual request if set to false and browser has sent
credentials will disallow to process returned response.

=item cors_expose => ['X-Some']

=item cors_expose => [qw/X-Some X-Other Server/]

=item cors_expose => undef (default)

Allow access to these headers while processing returned response.

These headers doesn't need to be included in this option:

  Cache-Control
  Content-Language
  Content-Type
  Expires
  Last-Modified
  Pragma

=item cors_headers => ['X-Requested-With']

=item cors_headers => [qw/X-Requested-With Content-Type X-Some/]

=item cors_headers => undef (default)

Define headers which browser is allowed to send. Work only for non-simple
CORS because it require preflight.

=item cors_methods => ['POST']

=item cors_methods => [qw/GET POST PUT DELETE]

This option can be used only for C<cors()> route. It's needed in complex
cases when it's impossible to automatically detect CORS option while
handling preflight - see below for example.

=back

=head2 cors

    $app->routes->cors(...);

Accept same params as L<Mojolicious::Routes::Route/"route">.

Add handler for preflight (OPTIONS) CORS request - it's required to allow
non-simple CORS requests on given path.

To be able to respond on preflight request this handler should know CORS
options for requested method/path. In most cases it will be able to detect
them automatically by searching for route defined for same path and HTTP
method given in CORS request. Example:

    $r->cors("/rpc");
    $r->get("/rpc", { cors_origin => ["http://example.com"] });
    $r->put("/rpc", { cors_origin => [qr/\.local\z/ms] });

But in some cases target route can't be detected, for example if you've
defined several routes for same path using different conditions which
can't be checked while processing preflight request because browser didn't
sent enough information yet (like C<Content-Type:> value which will be
used in actual request). In this case you should manually define all
relevant CORS options on preflight route - in addition to CORS options
defined on target routes. Because you can't know which one of defined
routes will be used to handle actual request, in case they use different
CORS options you should use combined in less restrictive way options for
preflight route. Example:

    $r->cors("/rpc")->to(
        cors_methods      => [qw/GET POST/],
        cors_origin       => ["http://localhost", "http://example.com"],
        cors_credentials  => 1,
    );
    $r->any([qw(GET POST)] => "/rpc")->over(
      headers => {
        'Content-Type' => 'application/json-rpc'
      }
    )->to(
      controller    => 'jsonrpc',
      action        => 'handler',

      cors_origin   => ["http://localhost"]
    );
    $r->post("/rpc")->over(
      headers => {
        'Content-Type' => 'application/soap+xml'
      }
    )->to(
      controller  => 'soaprpc',
      action      => 'handler',

      cors_origin       => "http://example.com",
      cors_credentials  => 1
    );

This route use 'headers' condition, so you can add your own handler for
OPTIONS method on same path after this one, to handle non-CORS OPTIONS
requests on same path.

=head1 OPTIONS

L<Mojolicious::Plugin::StrictCORS> supports the following options.

=head2 max_age

  $app->plugin('StrictCORS', { max_age => -1 });

Value for C<Access-Control-Max-Age:> sent by preflight OPTIONS handler.
If set to C<-1> cache will be disabled.

Default is 3600 (1 hour).

=head2 expose

  $app->plugin('StrictCORS', { expose => ['X-Message']});

Default value for C<Access-Control-Expose-Headers> for all requests, that
configured to use CORS.

Defailt is ampty array.

=head1 METHODS

L<Mojolicious::Plugin::StrictCORS> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);
  $plugin->register(Mojolicious->new, { max_age => -1 });

Register hooks in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious>.

=head1 SUPPORT

=head2 Bugs / Feature Requests

Bugs should always be submitted via the GitHub bug tracker.

L<https://github.com/bitnoize/mojolicious-plugin-strictcors/issues>

=head2 Source Code

Feel free to fork the repository and submit pull requests.

L<https://github.com/bitnoize/mojolicious-plugin-strictcors>

=head1 AUTHOR

Dmitry Krutikov E<lt>monstar@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2020 Dmitry Krutikov.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
