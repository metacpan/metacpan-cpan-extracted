package Mojolicious::Plugin::Util::Endpoint;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::ByteStream 'b';
use Scalar::Util qw/blessed/;
use Mojo::URL;

our $VERSION = '0.19';

# Todo: Support alternative bases for https-paths
# Todo: Update to https://tools.ietf.org/html/rfc6570
# Todo: Allow for changing scheme, port, host etc. afterwards

# Endpoint hash
our %endpoints;

# Register Plugin
sub register {
  my ($plugin, $mojo) = @_;

  # Add 'endpoints' command
  push @{$mojo->commands->namespaces}, __PACKAGE__;

  # Add 'endpoint' shortcut
  $mojo->routes->add_shortcut(
    endpoint => sub {
      my ($route, $name, $param) = @_;

      # Endpoint already defined
      if (exists $endpoints{$name}) {
	$mojo->log->debug(qq{Route endpoint "$name" already defined});
	return $route;
      };

      $param //= {};

      # Route defined
      $param->{route} = $route->name;

      # Set to stash
      $endpoints{$name} = $param // {};

      # Return route for piping
      return $route;
    }
  );


  # Add 'endpoint' helper
  $mojo->helper(
    endpoint => sub {
      my ($c, $name, $values) = @_;
      $values ||= {};

      # Define endpoint by string
      unless (ref $values) {
	return ($endpoints{$name} = Mojo::URL->new($values));
      }

      # Define endpoint by Mojo::URL
      elsif (blessed $values && $values->isa('Mojo::URL')) {
	return ($endpoints{$name} = $values->clone);
      };

      # Set values
      my %values = (
	$c->isa('Mojolicious::Controller') ? %{$c->stash} : %{$c->defaults},
	format => undef,
	%$values
      );

      # Endpoint undefined
      unless (defined $endpoints{$name}) {

	# Named route
	if ($name !~ m!^([^:]+:)?/?/!) {
	  return $c->url_for($name)->to_abs->to_string;
	};

	# Interpolate string
	return _interpolate($name, \%values, $values);
      };

      # Return interpolated string
      if (blessed $endpoints{$name} && $endpoints{$name}->isa('Mojo::URL')) {
	return _interpolate(
	  $endpoints{$name}->to_abs->to_string,
	  \%values,
	  $values
	);
      };

      # The following is based on url_for of Mojolicious::Controller
      # and parts of path_for in Mojolicious::Routes::Route
      # Get match object
      my $match;
      unless ($match = $c->match) {
	$match = Mojolicious::Routes::Match->new(get => '/');
	$match->root($c->app->routes);
      };

      # Base
      my $url = Mojo::URL->new;
      my $req = $c->req;
      $url->base($req->url->base->clone);
      my $base = $url->base;
      $base->userinfo(undef);

      # Get parameters
      my $param = $endpoints{$name};

      # Set parameters to url
      $url->scheme($param->{scheme}) if $param->{scheme};
      $url->port($param->{port}) if $param->{port};
      if ($param->{host}) {
	$url->host($param->{host});
	$url->port(undef) unless $param->{port};
	$url->scheme('http') unless $url->scheme;
      };

      # Clone query
      $url->query( [@{$param->{query}}] ) if $param->{query};

      # Get path
      my $path = $url->path;

      # Lookup match
      my $r = $match->root->find($param->{route});

      # Interpolate path
      my @parts;
      while ($r) {
	my $p = '';
	foreach my $part (@{$r->pattern->tree}) {
	  my $t = $part->[0];

	  # Slash
	  if ($t eq 'slash') {
	    $p .= '/';
	  }

	  # Text
	  elsif ($t eq 'text') {
	    $p .= $part->[1];
	  }

	  # Various wildcards
	  elsif ($t =~ m/^(?:wildcard|placeholder|relaxed)$/) {
	    if (exists $values{$part->[1]}) {
	      $p .= $values{$part->[1]};
	    }
	    else {
	      $p .= '{' . $part->[1] . '}';
	    };
	  };
	};

	# Prepend to path array
	unshift(@parts, $p);

	# Go up one level till root
	$r = $r->parent;
      };

      # Set path
      $path->parse(join('', @parts)) if @parts;

      # Fix trailing slash
      $path->trailing_slash(1)
	if (!$name || $name eq 'current')
	  && $req->url->path->trailing_slash;

      # Make path absolute
      my $base_path = $base->path;
      unshift @{$path->parts}, @{$base_path->parts};
      $base_path->parts([]);

      # Interpolate url for query parameters
      return _interpolate($url->to_abs->to_string, \%values, $values);
    }
  );


  # Add 'get_endpoints' helper
  $mojo->helper(
    get_endpoints => sub {
      my $c = shift;

      # Get all endpoints
      my %endpoint_hash;
      foreach (keys %endpoints) {
	$endpoint_hash{$_} = $c->endpoint($_);
      };

      # Return endpoint hash
      return \%endpoint_hash;
    });
};


# Interpolate templates
sub _interpolate {
  my $endpoint = shift;

  # Decode escaped symbols
  $endpoint =~
    s/\%7[bB](.+?)\%7[dD]/'{' . b($1)->url_unescape . '}'/ge;

  my $param = shift;
  my $orig_param = shift;

  # Interpolate template
  pos($endpoint) = 0;
  while ($endpoint =~ /\{([^\}\?}\?]+)\??\}/g) {

    # Save search position
    # Todo: That's not exact!
    my $val = $1;
    my $p = pos($endpoint) - length($val) - 1;

    my $fill = undef;

    # Look in param
    if ($param->{$val}) {
      $fill = b($param->{$val})->url_escape;
      $endpoint =~ s/\{$val\??\}/$fill/;
    }

    # unset specific parameters
    elsif (exists $orig_param->{$val}) {

      # Delete specific parameters
      for ($endpoint) {
	if (s/(?<=[\&\?])[^\}][^=]*?=\{$val\??\}//g) {
	  s/([\?\&])\&*/$1/g;
	  s/\&$//g;
	};
	s/^([^\?]+?)([\/\.])\{$val\??\}\2/$1$2/g;
	s/^([^\?]+?)\{$val\??\}/$1/g;
      };
    };

    # Reset search position
    # Todo: (not exact if it was optional)
    pos($endpoint) = $p + length($fill || '');
  };

  # Ignore optional placeholders
  if (exists $param->{'?'} &&
	!defined $param->{'?'}) {
    for ($endpoint) {
      s/(?<=[\&\?])[^\}][^=]*?=\{[^\?\}]+?\?\}//g or last;
      s/([\?\&])\&*/$1/g;
      s/\&$//g;
    };
  };

  # Strip empty query marker
  $endpoint =~ s/\?$//;
  return $endpoint;
};


1;


__END__

=pod

=head1 NAME

Mojolicious::Plugin::Util::Endpoint - Use Template URIs in Mojolicious


=head1 SYNOPSIS

  # Mojolicious::Lite
  plugin 'Util::Endpoint';

  # Mojolicious
  $self->plugin('Util::Endpoint');

  my $rs = $mojo->routes;

  # Set endpoint
  my $r = $rs->route('/:user')->endpoint(
    webfinger => {
      query  => [
        q => '{uri}'
      ]
    });

  return $self->endpoint('webfinger');
  # https://sojolicio.us/{user}?q={uri}

  $self->stash(user => 'Akron');

  return $self->endpoint('webfinger');
  # https://sojolicio.us/Akron?q={uri}

  return $self->endpoint(webfinger => {
    uri => 'acct:akron@sojolicio.us'
  });
  # https://sojolicio.us/Akron?q=acct%3Aakron%40sojolicio.us


=head1 DESCRIPTION

L<Mojolicious::Plugin::Util::Endpoint> is a plugin that
allows for the simple establishment of endpoint URIs.
This is similar to L<url_for|Mojolicious::Controller/url_for>,
but includes support for template URIs with parameters
following L<RFC6570|https://tools.ietf.org/html/rfc6570> Level 1
(as used in, e.g., Host-Meta or OpenSearch).


=head1 METHODS

=head2 register

  # Mojolicious
  $app->plugin('Util::Endpoint');

  # Mojolicious::Lite
  plugin 'Util::Endpoint';

Called when registering the plugin.


=head1 SHORTCUTS

=head2 endpoint

  my $rs = $mojo->routes
  my $r = $rs->route('/suggest')->endpoint(
    opensearch => {
      scheme => 'https',
      host   => 'sojolicio.us',
      port   => 3000,
      query  => [
        q     => '{searchTerms}',
        start => '{startIndex?}'
      ]
    });

Establishes an endpoint defined for a service.
It accepts optional parameters C<scheme>, C<host>,
a C<port> and query parameters (C<query>),
overwriting the current values of C<url_for>.
Template parameters need curly brackets, optional
template parameters need a question mark before
the closing bracket.
Optional path placeholders are currenty not supported.
Returns the route.

B<Warning>: Support for named routes to use with
C<url_for> was dropped in v0.19.

=head1 HELPERS

=head2 endpoint

  # In Controller:
  #   Set endpoints:
  $self->endpoint(hub => 'http://sojolicio.us/search?q={searchTerm}');
  $self->endpoint(hub => Mojo::URL->new('http://pubsubhubbub.appspot.com/'));

  #   Get endpoints:
  return $self->endpoint('webfinger');
  return $self->endpoint(webfinger => { user => 'me' } );

  # Interpolate arbitrary template URIs
  return $self->endpoint(
    'http://sojolicio.us/.well-known/webfinger?resource={uri}&rel={rel?}' => {
      'uri' => 'acct:akron@sojolicio.us',
      '?'   => undef
    });

  # In Template:
  <%= endpoint 'webfinger' %>

Get or set endpoints defined for a specific service.

For setting it accepts the name of the endpoint and
either a string with the endpoint URI or a L<Mojo::URL> object.

For getting it accepts the name of the endpoint or an arbitrary
template URI and additional stash values for the route as a hash reference.
These stash values override existing stash values from
the controller and fill the template variables.

  # In Controller:
  return $self->endpoint('opensearch');
  # https://sojolicio.us/suggest?q={searchTerms}&start={startIndex?}

  return $self->endpoint(opensearch => {
    searchTerms => 'simpson',
    '?' => undef
  });
  # https://sojolicio.us/suggest?q=simpson

The special parameter C<?> can be set to C<undef> to ignore
all undefined optional template parameters.

If the defined endpoint can't be found, the value for C<url_for>
is returned.


=head2 get_endpoints

  # In Controller:
  my $hash = $self->get_endpoints;

  while (my ($key, $value) = each %$hash) {
    print $key, ' => ', $value, "\n";
  };

Returns a hash of all endpoints, interpolated with the current
controller stash.

B<Note:> This helper is EXPERIMENTAL and may be deprecated in further releases.


=head1 COMMANDS

=head2 endpoints

  $ perl app.pl endpoints

Show all endpoints of the app established by this plugin.


=head1 DEPENDENCIES

L<Mojolicious> (best with SSL support).


=head1 CONTRIBUTORS

L<Viacheslav Tykhanovskyi|https://github.com/vti>


=head1 AVAILABILITY

  https://github.com/Akron/Mojolicious-Plugin-Util-Endpoint


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2015, L<Nils Diewald|http://nils-diewald.de/>.

This program is free software, you can redistribute it
and/or modify it under the same terms as Perl.

=cut
