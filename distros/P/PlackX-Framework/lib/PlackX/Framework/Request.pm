use v5.36;
package PlackX::Framework::Request {
  use parent 'Plack::Request';
  use Carp qw(croak);

  use Plack::Util::Accessor qw(stash route_base route_parameters);
  sub GlobalRequest    ($class) { ($class->app_namespace.'::Handler')->global_request }
  sub max_reroutes              { 16 }
  sub app_base          ($self) { eval {$self->app_namespace->uri_prefix} || ''      }
  sub is_get            ($self) { uc $self->method eq 'GET'    }
  sub is_post           ($self) { uc $self->method eq 'POST'   }
  sub is_put            ($self) { uc $self->method eq 'PUT'    }
  sub is_delete         ($self) { uc $self->method eq 'DELETE' }
  sub is_ajax           ($self) { uc($self->header('X-Requested-With') || '') eq 'XMLHTTPREQUEST' }
  sub destination       ($self) { $self->{destination} // $self->path        }
  sub flash_cookie_name ($self) { PlackX::Framework::flash_cookie_name($self->app_namespace) }
  sub param       ($self, $key) { scalar $self->parameters->{$key} } # faster than scalar $self->param($key)
  sub cgi_param   ($self, $key) { $self->SUPER::param($key)        } # CGI.pm compatibile
  sub route_param ($self, $key) { $self->{route_parameters}{$key}  }
  sub stash_param ($self, $key) { $self->{stash}{$key}             }
  sub abs_to      ($self, $pth) { $self->base . with_leadslash($pth)           }
  sub rel_to      ($self, $pth) { $self->abs_to($pth) =~ s|^https?://.+?/|/|ir }
  sub urix              ($self) { ($self->app_namespace.'::URIx')->new_from_pxfrequest($self) }
  sub with_leadslash     ($uri) { substr($uri, 0, 1) eq '/' ? $uri : '/'.$uri }
  *uri_to = \&abs_to;

  # Send request somewhere else without issuing the client an HTTP redirect
  # ::Handler will reprocess if it gets a request instead of response object
  sub reroute ($self, $dest) {
    croak "Specify reroute relative to application path"
      if $dest =~ m/^http/;
    croak "request->reroute path must start with /"
      if substr($dest, 0, 1) ne '/';

    $self->{reroutes} //= [$self->path_info];
    push @{$self->{reroutes}}, $dest;

    croak "Excessive reroutes:\n" . join("\n", $self->{reroutes}->@*)
      if $self->{reroutes}->@* > $self->max_reroutes;

    my $orig_path_info        = $self->path_info;
    $self->{"pxf.orig.$_"}  //= $self->env->{$_} for ('PATH_INFO', 'REQUEST_URI');
    $self->env->{PATH_INFO}   = $dest;
    $self->env->{REQUEST_URI} =~ s|$orig_path_info|$dest|;

    return $self;
  }

  # Maybe decode the flash from b64 json
  sub flash ($self) {
    my $cname   = $self->flash_cookie_name;
    my $content = $self->cookies->{$cname};
    my $prefix  = "$cname-ju64-";
    return PXF::Util::decode_ju64(substr($content, length($prefix)))
      if $content and substr($content, 0, length($prefix)) eq $prefix;
    return $content;
  }

}

1;

=pod

=head1 NAME

PlackX::Framework::Request - A subclass of Plack::Request


=head1 Differences from Plack::Request

This module adds some additional methods, and changes the behavior of the
param() method to only return a scalar. The original behavior is provided
by cgi_param().

    # Safe! param always returns scalar
    my %okay_hash = (
      key => $request->param('key')
    );

    # Not safe! cgi_param may return empty list or multiple values!
    my %bad_hash = (
      key => $request->cgi_param('key')
    );

    # ?color=red&color=green&color=blue
    my @colors = $request->cgi_param('color'); # red, green, blue

Please see the documentation for Plack::Request for more ways to get params,
e.g. the parameters() method, which is unchanged here.

In addition, this class has a destination() method, which returns the path_info
or a path set manually via the reroute() method. See below.


=head1 CLASS METHODS

=over 4

=item max_reroutes()

Returns the maximum number of PlackX::Framework "re-routes." By default, this
is 16. As this is a class method, the only way to change it is to override
the method in your subclass.

    package MyApp::Request {
      sub max_reroutes() { 1 }
    }

=item GlobalRequest()

If your app's subclass of PlackX::Framework::Handler overrides the
use_global_request_response() method to return a true value, PXF will set up
a global $request object, which can be accessed here.

This feature is turned off by default to avoid action-at-a-distance bugs. It
is preferred to use the request object instance passed to the route's
subroutine.

    package MyApp { use PlackX::Framework; }
    package MyApp::Handler { use_global_request_response { 1 } }
    package MyApp::Routes {
      use MyApp::Router;
      route '/someroute' => sub ($request, $response) {
        my $g_request = MyApp::Request->GlobalRequest();
        # $request and $g_request "should" be the same object
        ...
      };
    }

Attempting to use this method when the feature is turned off will result in an
error, most like of the "not an arrayref" variety.

=back


=head1 OBJECT METHODS

=over 4

=item param(NAME)

Unlike Plack::Request, our param() method always returns a single scalar value.
If you want the original behavior, which was modeled after CGI.pm, you can call
cgi_param().

=item cgi_param(NAME)

Calls Plack::Request's param() method, which may return a scalar or list,
depending on context, like CGI.pm or the mod_perl Apache request object.

=item route_param(NAME)

Return's the value of a route parameter, parsed by PlackX::Framework's router
engine. For example:

    route '/{page_name}' => sub ($request, $response) {
      my $page_name = $request->route_param('page_name');
    };

=item stash_param(NAME)

Accesses the request/response cycle's stash hashref, returning the value based
on the given key. For example:

     # Somewhere, like a route filter
     $request->stash->{session} = $session;

     # Somewhere else
     my $session = $request->stash_param('session');

     # The above is just a shortcut for
     my $session = $request->stash->{'session'};

=item flash()

Gets the content of the PXF app's flash cookie, if set on the previous request.

=item flash_cookie_name()

Returns the name of the PXF app's flash cookie, which should be unique per app,
as it is based on the md5 of the app's namespace. This method is used
internally, and there should be no need to access or override it in your app.

=item is_get(), is_post(), is_put(), is_delete()

Returns true if the HTTP request was a GET, POST, PUT, or DELETE request. This
is syntactic sugar for $request->method eq $verb;

=item is_ajax()

Returns true if the HTTP X-Requested-With header is set as expected for an AJAX
request.


=item destination()

Returns the request's path_info, or the app's alternative destination, if set
using the reroute() method.

=item reroute(URL)

Sets the destination to URL and returns the modified request object.

    # In a route sub:
    route '/old/url' => sub ($request, $response) {
      return $request->reroute('/new/url');
    };

When PlackX::Framework::Handler receives a request object as a response,
instead of a response object, request processing will start over with the new
route. Think of this as an internal redirect (which does not issue an HTTP
redirect to the user).

For debugging, you can access a list of reroutes through the
$request->{reroutes} hash key, which may be undefined or an arrayref. Routes
are remembered in order from oldest to newest.

=item urix()

Returns a new instance of a URI::Fast object, if you have the URI::Fast module
installed and your app turned on this feature.

    package MyApp {
      use PlackX::Framework qw(:URIx); # or :all
      use MyApp::Router;
      route '/seomwhere' => sub ($request, $response) {
        my $uri_fast = $request->urix;
        ...
      };
    }

=back


=head1 META

For author, copyright, and license, see PlackX::Framework.
