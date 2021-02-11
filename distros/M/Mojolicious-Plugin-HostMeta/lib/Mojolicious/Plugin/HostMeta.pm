package Mojolicious::Plugin::HostMeta;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Headers;
use Mojo::Util qw/quote/;

our $VERSION = '0.25';

our $WK_PATH = '/.well-known/host-meta';


# Register plugin
sub register {
  my ($plugin, $app, $param) = @_;

  $param ||= {};

  # Load parameter from Config file
  if (my $config_param = $app->config('HostMeta')) {
    $param = { %$param, %$config_param };
  };

  # Get helpers object
  my $helpers = $app->renderer->helpers;

  # Load Util-Endpoint/Callback if not already loaded
  foreach (qw/Endpoint Callback/) {
    $app->plugin("Util::$_") unless exists $helpers->{ lc $_ };
  };

  # Load XML if not already loaded
  unless (exists $helpers->{new_xrd}) {
    $app->plugin('XRD');
  };

  # Set callbacks on registration
  $app->callback(fetch_hostmeta => $param);

  # Get seconds to expiration
  my $seconds = (60 * 60 * 24 * 10);
  if ($param->{expires} && $param->{expires} =~ /^\d+$/) {
    $seconds = delete $param->{expires};
  };

  # Create new hostmeta document
  my $hostmeta = $app->new_xrd;
  $hostmeta->extension( -HostMeta );

  # Get host information on first request
  $app->hook(
    prepare_hostmeta =>
      sub {
        my ($c, $hostmeta) = @_;
        my $host = $c->req->url->to_abs->host;

        # Add host-information to host-meta
        $hostmeta->host( $host ) if $host;
      }
    );

  # Establish 'hostmeta' helper
  $app->helper(
    hostmeta => sub {
      my $c = shift;

      # Undefined host name
      shift if !defined $_[0];

      # Host name is provided
      if (!$_[0] || ref $_[0]) {

        # Return local hostmeta
        return _serve_hostmeta( $c, $hostmeta, @_ );
      };

      # Return discovered hostmeta
      return _fetch_hostmeta( $c, @_ );
    });

  # Establish /.well-known/host-meta route
  my $route = $app->routes->any( $WK_PATH );

  # Define endpoint
  $route->endpoint('host-meta');

  # Set route callback
  $route->to(
    cb => sub {
      my $c = shift;

      # Seconds given
      if ($seconds) {

        # Set cache control
        my $headers = $c->res->headers;
        $headers->cache_control(
          "public, max-age=$seconds"
        );

        # Set expires element
        $hostmeta->expires( time + $seconds );

        # Set expires header
        $headers->expires( $hostmeta->expires );
      };

      # Serve host-meta document
      return $c->helpers->reply->xrd(
        _serve_hostmeta( $c, $hostmeta )
      );
    });
};


# Get HostMeta document
sub _fetch_hostmeta {
  my $c    = shift;
  my $host = lc shift;

  # Trim tail
  pop while @_ && !defined $_[-1];

  # Get headers
  my $header = {};
  if ($_[0] && ref $_[0] && ref($_[0]) eq 'HASH') {
    $header = shift;
  };

  # Check if security is forced
  my $secure = defined $_[-1] && $_[-1] eq '-secure' ? pop : 0;

  # Get callback
  my $cb = pop if ref($_[-1]) && ref($_[-1]) eq 'CODE';

  # Get host information
  unless ($host =~ s!^\s*(?:http(s?)://)?([^/]+)/*\s*$!$2!) {
    return;
  };
  $secure = 1 if $1;

  # Build relations parameter
  my $rel;
  $rel = shift if $_[0] && ref($_[0]) eq 'ARRAY';

  # Helpers proxy
  my $h = $c->helpers;

  # Callback for caching
  my ($xrd, $headers) = $h->callback(
    fetch_hostmeta => $host
  );

  # HostMeta document was cached
  if ($xrd) {

    # Filter relations
    $xrd = $xrd->filter_rel( $rel ) if $rel;

    # Set headers to default
    $headers ||= Mojo::Headers->new if $cb || wantarray;

    # Return cached hostmeta document
    return $cb->( $xrd, $headers ) if $cb;
    return ( $xrd, $headers ) if wantarray;
    return $xrd;
  };

  # Create host-meta path
  my $path = '//' . $host . $WK_PATH;
  $path = 'https:' . $path if $secure;


  # Non-blocking
  if ($cb) {

    return $h->get_xrd(
      $path => $header => sub {
        my ($xrd, $headers) = @_;
        if ($xrd) {

          # Add hostmeta extension
          $xrd->extension(-HostMeta);

          # Hook for caching
          $c->app->plugins->emit_hook(
            after_fetching_hostmeta => (
              $c, $host, $xrd, $headers
            )
          );

          # Filter based on relations
          $xrd = $xrd->filter_rel( $rel ) if $rel;

          # Send to callback
          return $cb->( $xrd, $headers );
        };

        # Fail
        return $cb->();
      });
  };

  # Blocking
  ($xrd, $headers) = $h->get_xrd( $path => $header );

  # No host-meta found
  return unless $xrd;

  # Add hostmeta extension
  $xrd->extension( -HostMeta );

  # Hook for caching
  $c->app->plugins->emit_hook(
    after_fetching_hostmeta => (
      $c, $host, $xrd, $headers
    )
  );

  # Filter based on relations
  $xrd = $xrd->filter_rel( $rel ) if $rel;

  # Return
  return ($xrd, $headers) if wantarray;
  return $xrd;
};


# Run hooks for preparation and serving of hostmeta
sub _serve_hostmeta {
  my $c   = shift;
  my $xrd = shift;

  # Delete tail
  pop while @_ && !defined $_[-1];

  # Ignore security flag
  pop if defined $_[-1] && $_[-1] eq '-secure';

  # Ignore header information
  shift if $_[0] && ref($_[0]) && ref($_[0]) eq 'HASH';

  # Get callback
  my $cb = pop if ref($_[-1]) && ref($_[-1]) eq 'CODE';

  my $rel = shift;

  my $plugins = $c->app->plugins;
  my $phm = 'prepare_hostmeta';


  # prepare_hostmeta has subscribers
  if ($plugins->has_subscribers( $phm )) {

    # Emit hook for subscribers
    $plugins->emit_hook( $phm => ( $c, $xrd ));

    # Unsubscribe all subscribers
    foreach (@{ $plugins->subscribers( $phm ) }) {
      $plugins->unsubscribe( $phm => $_ );
    };
  };

  # No further modifications wanted
  unless ($plugins->has_subscribers('before_serving_hostmeta')) {

    # Filter relations
    $xrd = $xrd->filter_rel( $rel ) if $rel;

    # Return document
    return $cb->( $xrd ) if $cb;
    return $xrd;
  };

  # Clone hostmeta reference
  $xrd = $c->helpers->new_xrd( $xrd->to_string );

  # Emit 'before_serving_hostmeta' hook
  $plugins->emit_hook(
    before_serving_hostmeta => (
      $c, $xrd
    ));

  # Filter relations
  $xrd = $xrd->filter_rel( $rel ) if $rel;

  # Return hostmeta clone
  return $cb->( $xrd ) if $cb;
  return $xrd;
};


1;


__END__

=pod

=head1 NAME

Mojolicious::Plugin::HostMeta - Serve and Retrieve Host-Meta Documents


=head1 SYNOPSIS

  # Mojolicious
  $app->plugin('HostMeta');

  # Mojolicious::Lite
  plugin 'HostMeta';

  # Serves XRD or JRD from /.well-known/host-meta

  # Blocking requests
  print $c->hostmeta('gmail.com')->link('lrrd');

  # Non-blocking requests
  $c->hostmeta('gmail.com' => sub {
    print shift->link('lrrd');
  });


=head1 DESCRIPTION

L<Mojolicious::Plugin::HostMeta> is a Mojolicious plugin to serve and
request C<well-known> L<Host-Meta|https://tools.ietf.org/html/rfc6415>
documents.

=head1 METHODS

=head2 register

  # Mojolicious
  $app->plugin(HostMeta => {
    expires => 100
  });

  # Mojolicious::Lite
  plugin 'HostMeta';

Called when registering the plugin.
Accepts one optional parameter C<expires>, which is the number
of seconds the served host-meta should be cached by the fetching client.
Defaults to 10 days.
All parameters can be set either as part of the configuration
file with the key C<HostMeta> or on registration
(that can be overwritten by configuration).


=head1 HELPERS

=head2 hostmeta

  # In Controller:
  my $xrd = $c->hostmeta;
  $xrd = $c->hostmeta('gmail.com');
  $xrd = $c->hostmeta('sojolicio.us' => ['hub']);
  $xrd = $c->hostmeta('sojolicio.us', { 'X-MyHeader' => 'Fun' } => ['hub']);
  $xrd = $c->hostmeta('gmail.com', -secure);

  # Non blocking
  $c->hostmeta('gmail.com' => ['hub'] => sub {
    my $xrd = shift;
    # ...
  }, -secure);

This helper returns host-meta documents
as L<XML::Loy::XRD> objects with the
L<XML::Loy::HostMeta> extension.

If no host name is given, the local host-meta document is returned.
If a host name is given, the corresponding host-meta document
is retrieved from the host and returned.

An additional hash reference or a L<Mojo::Headers> object can be used
to pass header information for retrieval.
An additional array reference may limit the relations to be retrieved
(see the L<WebFinger|http://tools.ietf.org/html/draft-ietf-appsawg-webfinger>
specification for further explanation).
A final C<-secure> flag indicates, that discovery is allowed
only over C<https> without redirections.

This method can be used in a blocking or non-blocking way.
For non-blocking retrieval, pass a callback function as the
last argument before the optional C<-secure> flag to the method.
As the first passed response is the L<XML::Loy::XRD>
document, you have to use an offset of C<0> in
L<begin|Mojo::IOLoop::Delay/begin> for parallel requests using
L<Mojo::IOLoop::Delay>.


=head1 CALLBACKS

=head2 fetch_hostmeta

  # Establish a callback
  $app->callback(
    fetch_hostmeta => sub {
      my ($c, $host) = @_;

      my $doc = $c->chi->get("hostmeta-$host");
      return unless $doc;

      my $header = $c->chi->get("hostmeta-$host-headers");

      # Return document
      return ($c->new_xrd($doc), Mojo::Headers->new->parse($header));
    }
  );

This callback is released before a host-meta document
is retrieved from a foreign server. The parameters passed to the
callback include the current controller object and the host's
name.

If a L<XML::Loy::XRD> document associated with the requested
host name is returned (and optionally a L<Mojo::Headers> object),
the retrieval will stop.

The callback can be established with the
L<callback|Mojolicious::Plugin::Util::Callback/callback>
helper or on registration.

This can be used for caching.

Callbacks may be changed for non-blocking requests.


=head1 HOOKS

=head2 prepare_hostmeta

  $app->hook(prepare_hostmeta => sub {
    my ($c, $xrd) = @_;
    $xrd->link(permanent => '/perma.html');
  };

This hook is run when the host's own host-meta document is
first prepared. The hook passes the current controller
object and the host-meta document as an L<XML::Loy::XRD> object.
This hook is only emitted once for each subscriber.


=head2 before_serving_hostmeta

  $app->hook(before_serving_hostmeta => sub {
    my ($c, $xrd) = @_;
    $xrd->link(lrdd => './well-known/host-meta');
  };

This hook is run before the host's own host-meta document is
served. The hook passes the current controller object and
the host-meta document as an L<XML::Loy::XRD> object.
This should be used for dynamical changes of the document
for each request.


=head2 after_fetching_hostmeta

  $app->hook(
    after_fetching_hostmeta => sub {
      my ($c, $host, $xrd, $headers) = @_;

      # Store in cache
      my $chi = $c->chi;
      $chi->set("hostmeta-$host" => $xrd->to_string);
      $chi->set("hostmeta-$host-headers" => $headers->to_string);
    }
  );

This hook is run after a foreign host-meta document is newly fetched.
The parameters passed to the hook are the current controller object,
the host name, the XRD document as an L<XML::Loy::XRD> object
and the L<headers|Mojo::Headers> object of the response.

This can be used for caching.


=head1 ROUTES

The route C</.well-known/host-meta> is established and serves
the host's own host-meta document.
An L<endpoint|Mojolicious::Plugin::Util::Endpoint> called
C<host-meta> is established.


=head1 EXAMPLES

The C<examples/> folder contains a full working example application
with serving and discovery.
The example has an additional dependency of L<CHI>.

It can be started using the daemon, morbo or hypnotoad.

  $ perl examples/hostmetaapp daemon

This example may be a good starting point for your own implementation.

A less advanced application using non-blocking requests without caching
is also available in the C<examples/> folder. It can be started using
the daemon, morbo or hypnotoad as well.

  $ perl examples/hostmetaapp-async daemon


=head1 DEPENDENCIES

L<Mojolicious> (best with SSL support),
L<Mojolicious::Plugin::Util::Endpoint>,
L<Mojolicious::Plugin::Util::Callback>,
L<Mojolicious::Plugin::XRD>.


=head1 AVAILABILITY

  https://github.com/Akron/Mojolicious-Plugin-HostMeta

This plugin is part of the L<Sojolicious|http://sojolicio.us> project.


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2021, L<Nils Diewald|https://www.nils-diewald.de/>.

This program is free software, you can redistribute it
and/or modify it under the terms of the Artistic License version 2.0.

=cut
