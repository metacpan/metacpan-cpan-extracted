package Mojolicious::Plugin::WebFinger;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Util 'url_escape';
use Mojo::URL;

# Todo:
# - Make callback non-blocking aware
# - Support 307 Temporary Redirect as described in the spec
# - Support simple startup defintion, like
#   plugin WebFinger => {
#     'akron@sojolicious' => {
#       describedby => {
#	  type => 'application/rdf+xml',
#	  href => 'http://sojolicio.us/akron.foaf'
#       }
#     }
#   };

our $VERSION = '0.12';


my $WK_PATH = '/.well-known/webfinger';

# Register Plugin
sub register {
  my ($plugin, $mojo, $param) = @_;

  # Plugin parameter
  $param ||= {};

  # Load parameter from Config file
  if (my $config_param = $mojo->config('WebFinger')) {
    $param = { %$param, %$config_param };
  };

  # Load HostMeta if not already loaded.
  # This automatically loads XRD,
  # Util::Endpoint and Util::Callback plugins.
  unless (exists $mojo->renderer->helpers->{hostmeta}) {
    $mojo->plugin('HostMeta');
  };

  # Check for 'prepare_webfinger' and 'fetch_webfinger' callback
  $mojo->callback(
    [qw/fetch_webfinger prepare_webfinger/],
    $param,
    -once
  );

  # Get seconds to expiration
  my $seconds = (60 * 60 * 24 * 10);
  if ($param->{expires} && $param->{expires} =~ /^\d+$/) {
    $seconds = delete $param->{expires};
  };

  # Establish WebFinger Route
  my $wfr = $mojo->routes->any($WK_PATH);

  # Establish endpoint
  $wfr->endpoint(
    webfinger => {
      query => [
        'resource' => '{uri}',
        'rel'      => '{rel?}',
        'format'   => '{format?}'
      ]
    });

  # Response to webfinger request
  $wfr->to(
    cb => sub {
      my $c = shift;

      # Check for security
      if ($param->{secure} && !$c->req->is_secure) {

        # Bad request - only https allowed!
        return $c->render(status => 400);
      };

      # Get resource parameter
      my $res = $c->param('resource');

      # Delete invalid parameters
      if (!$res || $res eq '{uri}') {

        # Bad request - no resource defined
        return $c->render(status => 400);
      };

      # Set standard format
      unless ($c->stash('format') || scalar $c->param('_format') || scalar $c->param('format')) {
        $c->stash(format => 'jrd');
      };

      # Normalize the resource
      my ($acct, $host, $nres) = _normalize_resource($c, $res);

      # Set host to local
      $host ||= $c->req->url->base->host || 'localhost';

      # Bad request - no resource defined
      return $c->render(status => 400) unless $nres;

      # Check for 'prepare_webfinger' callback
      if ($c->callback(prepare_webfinger => $nres)) {

        # The response body is already rendered
        return if $c->res->body;

        # Create new xrd document
        my $xrd = _serve_webfinger($c, $acct, $nres, $res);

        # Seconds given
        if ($xrd) {

          my $expires;
          unless ($expires = $xrd->expires && $seconds) {
            $expires = $xrd->expires( time + $seconds);
          };

          # Expires set
          if ($expires) {

            # Set cache control
            my $headers = $c->res->headers;
            $headers->cache_control(
              "public, max-age=$seconds"
            );

            # Set expires header
            $headers->expires( $xrd->expires );
          };
        };

        # Server xrd document
        return $c->reply->xrd($xrd, $res);
      };

      # No valid xrd document is existing for this resource
      return $c->reply->xrd(undef, $res);
    }
  );

  # Add Route to Host-Meta - exactly once
  $mojo->hook(
    prepare_hostmeta => sub {
      my ($c, $hostmeta) = @_;

      # Add JRD link
      $hostmeta->link(lrdd => {
        type     => 'application/jrd+json',
        template => $c->endpoint(
          webfinger => {
            '?' => undef
          }
        )
      });

      # Add XRD link
      $hostmeta->link(lrdd => {
        type     => 'application/xrd+xml',
        template => $c->endpoint(
          webfinger => {
            format => 'xrd',
            '?' => undef
          }
        )
      });
    });

  # webfinger helper
  $mojo->helper(
    webfinger => \&_fetch_webfinger
  );
};


# Fetch webfinger resource
sub _fetch_webfinger {
  my $c = shift;

  my ($acct, $res, $nres, $host);


  # Request with host information
  if ($_[1] && !ref($_[1]) && index($_[1], '-') != 0) {
    $host = shift;
    $nres = shift;
  }

  # Get host information from resource
  else {
    $res = shift;
    ($acct, $host, $nres) = _normalize_resource($c, $res);
  };

  # Trim tail
  pop while @_ && !defined $_[-1];

  # Get flags
  my %flag;
  while (defined $_[-1] && index($_[-1], '-') == 0) {
    $flag{ pop() } = 1;
  };

  # Optimize flags for known services
  if ($host && $host =~ /(?:gmail|yahoo|mozilla)\.(?:com|org|net)$/i) {
    $flag{-old} = 1 unless $flag{-modern};
  };

  # Get callback
  my $cb = defined $_[-1] && ref $_[-1] eq 'CODE' ? pop : undef;

  # Get header information for requests
  my $header = {};
  if ($_[0] && ref $_[0] && ref($_[0]) eq 'HASH') {
    $header = shift;
  };

  # Get relation information
  my $rel = shift;

  # If local, serve local
  if (!$host ||
        ($host eq ($c->req->url->base->host || 'localhost'))) {

    if ($c->callback(prepare_webfinger => $nres)) {

      # Serve local xrd document
      my $xrd = _serve_webfinger($c, $acct, $nres, $res);

      # Return values
      return $cb ? $cb->($xrd, Mojo::Headers->new) : (
        wantarray ? ($xrd, Mojo::Headers->new) : $xrd
      );
    }
    else {
      return $cb ? $cb->() : undef;
    }
  };

  # Check cache
  my ($xrd, $headers) = $c->callback(
    fetch_webfinger => ($host, $nres, $header)
  );

  # Store unchanged normalized resource
  $res = $nres;

  # Delete resource
  $nres =~ s/^acct://;

  # xrd document exists
  if ($xrd) {

    # Filter relations
    $xrd = $xrd->filter_rel( $rel ) if $rel;

    # Set headers to default
    $headers ||= Mojo::Headers->new if $cb || wantarray;

    # Return cached webfinger document
    # Return values
    return $cb ? $cb->($xrd, $headers) : (
      wantarray ? ($xrd, $headers) : $xrd
    );
  };

  # Not found
  return ($cb ? $cb->() : undef) unless $host && $res;

  # Set secure value
  my $secure;
  if (exists $flag{-secure} || exists $flag{-modern}) {
    $secure = 1;
  };

  # Modern webfinger path
  my $path = '//' . $host . $WK_PATH . '?resource=' . url_escape $nres;
  $path = 'https:' . $path if $secure;

  # Non-blocking
  if ($cb) {

    # Initialize delay array
    my @delay;

    # If modern is allowed
    unless (exists $flag{-old}) {

      # push to delay array
      push(
        @delay,

        # Step 1
        sub {
          my $delay = shift;

          # Retrieve from modern path
          $c->get_xrd(
            $path => $header => $delay->begin
          );
        },

        # Step 2
        sub {
          my ($delay, $xrd, $headers) = @_;

          # Document found
          if ($xrd) {

            # Hook for caching
            $c->app->plugins->emit_hook(
              after_fetching_webfinger => (
                $c, $host, $res, $xrd, $headers
              ));

            # Filter based on relations
            $xrd = $xrd->filter_rel($rel) if $rel;

            # Successful
            return $cb->($xrd, $headers);
          };

          # No more discovery
          return $cb->() if exists $flag{-modern};

          # Next step
          $delay->begin->();
        });
    };

    # Old Host-Meta discovery
    push(
      @delay,

      # Step 3
      sub {
        my $delay = shift;

        my @param = (
          $host,
          $header,
          ['lrdd'],
          $delay->begin(0,1)
        );

        push @param, '-secure' if $secure;

        # Host-Meta with lrdd
        $c->hostmeta( @param );
      },

      # Step 4
      sub {
        # Host-Meta document
        my ($delay, $xrd) = @_;

        # Host-Meta is expired
        return $cb->() if !$xrd || $xrd->expired;

        # Prepare lrdd
        my $template = _get_lrdd($xrd) or return $cb->();

        # Interpolate template
        my $lrdd = $c->endpoint($template => {
          uri => $nres,
          '?' => undef
        });

        # Get lrdd
        $c->get_xrd($lrdd => $header => $delay->begin(0,1))
      },

      # Step 5
      sub {
        my $delay = shift;
        my ($xrd, $headers) = @_;

        # No lrdd xrd document found
        return $cb->() unless $xrd;

        # Hook for caching
        $c->app->plugins->emit_hook(
          after_fetching_webfinger => (
            $c, $host, $res, $xrd, $headers
          ));

        # Filter based on relations
        $xrd = $xrd->filter_rel($rel) if $rel;

        # Successful
        return $cb->($xrd, $headers);
      });

    # Create delay
    my $delay = Mojo::IOLoop->delay(@delay);

    # Start IOLoop if not running
    $delay->wait unless Mojo::IOLoop->is_running;

    return;
  };

  # Blocking
  # Modern discovery
  unless (exists $flag{-old}) {

    # Retrieve from modern path
    ($xrd, $headers) = $c->get_xrd($path => $header);
  };

  # Not found yet
  unless ($xrd) {

    # No further discovery
    return if exists $flag{-modern};

    # Host-Meta and lrdd
    $xrd = $c->hostmeta(
      $host,
      $header,
      ['lrdd'],
      ($secure ? '-secure' : undef)
    ) or return;

    # Todo: support header expiration date
    return if $xrd->expired;

    # Find 'lrdd' link
    my $template = _get_lrdd($xrd) or return;

    # Interpolate template
    my $lrdd = $c->endpoint(
      $template => {
        uri => $nres,
        '?' => undef
      });

    # Retrieve based on lrdd
    ($xrd, $headers) = $c->get_xrd($lrdd => $header) or return;
  };

  # Hook for caching
  $c->app->plugins->emit_hook(
    after_fetching_webfinger => (
      $c, $host, $res, $xrd, $headers
    ));

  # Filter based on relations
  $xrd = $xrd->filter_rel($rel) if $rel;

  # Return
  return wantarray ? ($xrd, $headers) : $xrd;
};


# Serve webfinger
sub _serve_webfinger {
  my $c = shift;
  my ($acct, $nres, $res) = @_;

  # No normalized resource
  return unless $nres;

  # No resource given
  $res ||= $nres;

  # Create new XRD document
  my $xrd = $c->new_xrd;

  # Set Subject
  $xrd->subject($res);

  # Set Alias
  $xrd->alias($nres) if $res ne $nres;

  # Run hook
  $c->app->plugins->emit_hook(
    before_serving_webfinger => ($c, $nres, $xrd)
  );

  # Filter relations
  $xrd = $xrd->filter_rel($c->every_param('rel')) if $c->param('rel');

  # Return webfinger document
  return $xrd;
};


# Normalize resource
sub _normalize_resource {
  my ($c, $res) = @_;
  return unless $res;

  # Resource is qualified
  if (index($res, 'acct:') != 0 and $res =~ /^[^:]+:/) {

    return $res unless wantarray;

    # Check host
    my $url = Mojo::URL->new($res);

    # Get host information
    my $host = $url->host;

    # Return array
    return (undef, $host, $res) if wantarray;
  };

  # Delete scheme if exists
  $res =~ s/^acct://i;

  # Split user from domain
  my ($acct, $host) = split '@', lc $res;

  # Create norm writing
  my $norm = 'acct:' . $acct . '@';

  # Use request host if no host is given
  $norm .= ($host || $c->req->url->base->host || 'localhost');

  return wantarray ? ($acct, $host, $norm) : $norm;
};


# Get lrdd
sub _get_lrdd {
  my $xrd = shift;

  # Find 'lrdd' link
  my $lrdd = $xrd->link('lrdd') or return;

  # Get template
  $lrdd->attr('template') or return;
};


1;


__END__

=pod

=head1 NAME

Mojolicious::Plugin::WebFinger - Serve and Retrieve WebFinger Documents


=head1 SYNOPSIS

  # Mojolicious
  $app->plugin('WebFinger');

  # Mojolicious::Lite
  plugin 'WebFinger';

  # Will serve XRD or JRD from /.well-known/webfinger

  # Discover WebFinger resources the blocking ...
  print $c->webfinger('acct:bob@example.com')
          ->link('describedby')
          ->attr('href');

  # ... or the non-blocking way
  $c->webfinger('acct:bob@example.com' => sub {
    my ($xrd, $header) = @_;
    # ...
  });


=head1 DESCRIPTION

L<Mojolicious::Plugin::WebFinger> provides several functions for the
L<WebFinger Protocol|https://webfinger.net/>.
It supports C<.well-known/webfinger> discovery as well as Host-Meta
and works with both XRD and JRD.


=head1 METHODS

=head2 register

  # Mojolicious
  $app->plugin(WebFinger => {
    expires => 100,
    secure  => 1
  });

  # Mojolicious::Lite
  plugin 'WebFinger';

Called when registering the plugin.
Accepts the optional parameters C<secure>, which is a boolean value
indicating that only secure transactions are allowed,
and C<expires>, which is the number of seconds the served WebFinger
document should be cached by the fetching client (defaults to 10 days).
These parameters can be either set on registration or
as part of the configuration file with the key C<WebFinger>.


=head1 HELPERS

=head2 webfinger

  # In Controllers:
  my $xrd = $self->webfinger('acct:me@sojolicio.us');

  # Only secure discovery
  my $xrd = $self->webfinger('acct:me@sojolicio.us', -secure);

  # Use lrdd with host and resource description
  my $xrd = $self->webfinger(
    'sojolicio.us' => 'http://sojolicio.us/me.html', -secure
  );

  # Use 'rel' parameters
  my $xrd = $self->webfinger(
    'acct:me@sojolicio.us' => ['describedBy'], -secure
  );

  # Use non-blocking discovery
  $self->webfinger(
    'acct:me@sojolicio.us' => [qw/describedBy author/] => sub {
      my $xrd = shift;
      # ...
    } => -modern);

  # Serve local WebFinger documents
  my $xrd = $self->webfinger('me');

Returns the WebFinger resource as an L<XRD|XML::Loy::XRD> object.
Accepts the WebFinger resource, an optional array reference
of relations, and an optional callback for non-blocking requests.
The appended flag indicates, how the discovery should be done.
C<-secure> indicates, that discovery is allowed only via C<https>.
C<-modern> indicates, that only C</.well-known/webfinger> is
discovered over C<https>.
C<-old> indicates, that only L<Host-Meta|Mojolicious::Plugin::HostMeta>
and lrdd discovery is used.


=head1 CALLBACKS

=head2 fetch_webfinger

  # Establish a callback
  $mojo->callback(
    fetch_webfinger=> sub {
      my ($c, $host, $res, $header) = @_;

      # Get cached document using M::P::CHI
      my $doc = $c->chi->get("webfinger-$host-$res") or return;

      # Get cached headers
      my $headers = $c->chi->get("webfinger-$host-$res-headers");

      # Return document
      return ($c->new_xrd($doc), Mojo::Headers->new->parse($headers));
    }
  );

This callback is released before a WebFinger document
is retrieved from a foreign server. The parameters passed to the
callback include the current controller object, the host's
name and the resource name.

If an L<XRD|XML::Loy::XRD> object associated with the requested
host name is returned (and optionally a L<Mojo::Headers> object),
the retrieval will stop.

This can be used for caching.

The callback can be established using the
L<callback|Mojolicious::Plugin::Util::Callback/callback>
helper or on registration.
Callbacks may be improved for non-blocking requests in the future.


=head2 prepare_webfinger

  if ($c->callback(prepare_webfinger => sub {
    my ($c, $res) = @_;
    if ($res eq 'acct:akron@sojolicio.us') {
      $c->stash('profile' => 'http://sojolicio.us/user/akron');
      return 1;
    };
  })) {
    print 'The requested resource exists!';
  };

This callback is triggered before a WebFinger document is served.
The current controller object and the requested resource is passed.
A boolean value indicating the
validity of the resource is expected.
A rendered response in the callback will be respected and further
serving won't be processed.

Data retrieved for the resource can be passed to the stash and
rendered using the L<before_serving_webfinger|/before_serving_webfinger>
hook.

The callback can be either set using the
L<callback helper|Mojolicious::Plugin::Util::Callback/callback>
or on registration.
Callbacks may be improved for non-blocking requests in the future.


=head1 HOOKS

=head2 before_serving_webfinger

  $mojo->hook(
    before_serving_webfinger => sub {
      my ($c, $res, $xrd) = @_;
      if ($c->stash('profile')) {
        $xrd->link(profile => { href => $c->stash('profile') } );
      };
    });

This hook is run before the requested WebFinger document is served.
The hook passes the current controller object,
the resource name and the L<XRD|XML::Loy::XRD> object.


=head2 after_fetching_webfinger

  $mojo->hook(
    after_fetching_webfinger => sub {
      my ($c, $host, $res, $xrd, $headers) = @_;

      # Store document in cache using M::P::CHI
      $c->chi->set("webfinger-$host-$res" => $xrd->to_pretty_xml);

      # Store headers in cache
      $c->chi->set("webfinger-$host-$res-headers" => $headers->to_string);
    }
  );

This hook is run after a foreign WebFinger document is newly fetched.
The parameters passed to the hook are the current controller object,
the host name, the resource name, the L<XRD|XML::Loy::XRD> object
and the L<headers|Mojo::Headers> object of the response.

This can be used for caching.


=head1 ROUTES

The route C</.well-known/webfinger> is established as the
lrdd L<endpoint|Mojolicious::Plugin::Util::Endpoint> C<webfinger>.
This plugin depends on this route,
and the C<resource> and C<rel> attributes. Although other
routes are possible for WebFinger/lrdd in older drafts of
the specification and different forms for the resource definition,
this is assumed to be a future-proof best practice.


=head1 EXAMPLE

The C<examples/> folder contains a full working example application
with serving and discovery.
The example has an additional dependency of L<CHI>.
It can be started using the daemon, morbo or hypnotoad.

  $ perl examples/webfingerapp daemon

This example may be a good starting point for your own implementation.

A less advanced application using non-blocking requests without caching
is also available in the C<examples/> folder. It can be started using
the daemon, morbo or hypnotoad as well.

  $ perl examples/webfingerapp-async daemon


=head1 DEPENDENCIES

L<Mojolicious> (best with SSL support),
L<Mojolicious::Plugin::HostMeta>.


=head1 AVAILABILITY

  https://github.com/Akron/Mojolicious-Plugin-WebFinger


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2021, L<Nils Diewald|https://www.nils-diewald.de/>.

This program is free software, you can redistribute it
and/or modify it under the terms of the Artistic License version 2.0.

=cut
