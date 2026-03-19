use v5.36;
package PlackX::Framework::Handler {
  use PXF::Util ();
  use Scalar::Util qw(blessed);
  use HTTP::Status qw(status_message);

  my  %globals;
  our $psgix_streaming; # memoized, but in an "our" var so tests can change it
  sub use_global_request_response    { } # Override in subclass to turn on
  sub global_request        ($class) { $globals{$class->app_namespace}->[0]            }
  sub global_response       ($class) { $globals{$class->app_namespace}->[1]            }
  sub error_response ($class, $code) { [$code, [], [status_message($code)." ($code)"]] } # Override for nicer message

  #
  # App assembly section
  #
  sub build_app ($class, %options)  {
    # Freeze the router
    my $rt_engine = ($class->app_namespace . '::Router::Engine')->instance;
    $rt_engine->freeze;

    # Honestly, it is probably better for the user to use Plack::Builder
    # or URLMap or Cascade instead of doing this, but we do it here for
    # convenience in development environments, at least for now. Think about
    # removing this feature at a later date.
    my $serve_static_files = delete $options{'serve_static_files'};
    my $static_docroot     = delete $options{'static_docroot'};
    die "Unknown options: " . join(', ', keys %options) if %options;

    my $main_app = sub ($env) { psgi_response($class->handle_request($env, undef, $rt_engine)) };
    my $file_app = ($serve_static_files and do {
      require Plack::App::File;
      Plack::App::File->new(root => $static_docroot)->to_app;
    });

    # if app_base is specified, use URLMap
    if (my $app_base = $class->app_base) {
      require Plack::App::URLMap;
      my $mapper = Plack::App::URLMap->new;
      $mapper->map($app_base => $main_app);
      $mapper->map('/'       => $file_app) if $file_app;
      return $mapper->to_app;
    }

    # Static file app with no app_base, so try one, try the other if it's 404
    # (basically our own cascade whereas we could use Plack::App::Cascade).
    # We prefer to serve the app's 404 page if the file app also returns 404
    # because it is easier to customize the 404 page with PXF.
    # Add a later date we might add a feature to intercept all 4xx and 5xx
    # error codes at the last possible moment and render a user-defined page.
    return sub ($env) {
      my $main_resp = $main_app->($env);
      return $main_resp if ref $main_resp and $main_resp->[0] != 404;
      my $file_resp = $file_app->($env);
      return $file_resp if ref $file_resp and $file_resp->[0] != 404;
      return $main_resp;
    } if $file_app;

    # no app_base, no static file app, just return the main app
    return $main_app;
  }

  sub app_base ($class) {
    my $base = eval { $class->app_namespace->app_base } || eval { $class->app_namespace->uri_prefix } || '';
    $base = '/'.$base if $base and length $base and substr($base,0,1) ne '/';
    return $base;
  }

  #
  # Request handling section
  #
  sub handle_request ($class, $env_or_req, $maybe_resp = undef, $maybe_rt_engine = undef) {
    my $app_namespace  = $class->app_namespace;

    # Get or create default request and response objects
    my $env      = $class->env_or_req_to_env($env_or_req);
    my $request  = $class->env_or_req_to_req($env_or_req);
    my $response = $maybe_resp || ($app_namespace . '::Response')->new->set_defaults;

    # Memoize server info and maybe set request/response globals
    $psgix_streaming = $env->{'psgi.streaming'} ? !!1 : !!0
      if !defined $psgix_streaming;
    $globals{$app_namespace} = [$request, $response]
      if $class->use_global_request_response;

    # Set up stash
    my $stash = ($request->stash or $response->stash or {});
    $request->stash($stash);
    $response->stash($stash);

    # Maybe set up Templating, if loaded
    if (PXF::Util::is_module_loaded($app_namespace . '::Template')) {
      eval {
        my $template = ($app_namespace . '::Template')->new($response);
        $template->set(STASH => $stash, REQUEST => $request, RESPONSE => $response);
        $response->template($template);
      } or do {
        warn "$app_namespace\::Template module loaded, but unable to set up template: $@"
        .    "  (Hint: Did you use/import from it or set up templating manually?)\n";
      };
    }

    # Clear flash if set, set response defaults, and route request
    $response->flash(undef) if $request->flash;
    return $class->route_request($request, $response, $maybe_rt_engine);
  }

  sub route_request ($class, $request, $response, $rt_engine = undef) {
    $rt_engine //= ($class->app_namespace . '::Router::Engine')->instance;
    if (my $match = $rt_engine->match($request)) {
      $request->route_base($match->{base}) if defined $match->{base};
      $request->route_parameters($match->{route_parameters});

      # Execute global and route-specific prefilters
      if (my $filterset = $match->{prefilters}) {
        my $ret = execute_filters($filterset, $request, $response);
        return $ret if $ret and is_valid_response($ret);
      }

      # Execute main action
      my $result = $match->{action}->($request, $response);
      unless ($result and ref $result) {
        warn "PlackX::Framework - Invalid result '$result'\n";
        return $class->error_response(500);
      }

      # Check if the result is actually another request object
      return $class->handle_request($result) if $result->isa('Plack::Request');
      return $class->error_response unless $result->isa('Plack::Response');
      $response = $result;

      # Execute postfilters
      if (my $filterset = $match->{postfilters}) {
        my $ret = execute_filters($filterset, $request, $response);
        return $ret if $ret and is_valid_response($ret);
      }

      # Clean up (does server support cleanup handlers? Add to list or else execute now)
      if ($response->cleanup_callbacks and scalar $response->cleanup_callbacks->@* > 0) {
        if ($request->env->{'psgix.cleanup'}) {
          push $request->env->{'psgix.cleanup.handlers'}->@*, $response->cleanup_callbacks->@*;
        } else {
          $_->($request->env) for $response->cleanup_callbacks->@*;
        }
      }

      return $response if is_valid_response($response);
    }

    return $class->error_response(404);
  }

  #
  # Helper function and method section
  #
  sub execute_filters ($filters, $request, $response) {
    return unless $filters and ref $filters eq 'ARRAY';
    foreach my $filter (@$filters) {
      $filter = { action => $filter, params => [] } if ref $filter eq 'CODE';
      my $response = $filter->{action}->($request, $response, @{$filter->{params}});
      return $response if $response and is_valid_response($response);
    }
    return;
  }

  sub is_valid_response {
    my $response = pop;
    return !!0 unless defined $response and ref $response;
    return !!1 if ref $response eq 'ARRAY' and (@$response == 3 or @$response == 2);
    return !!1 if blessed $response and $response->can('finalize');
    return !!0;
  }

  sub psgi_response ($resp) {
    return $resp
      if !blessed $resp;

    return $resp->finalize
      if not $resp->can('stream') or not $resp->stream;

    return sub ($PSGI_responder) {
      my $PSGI_writer = $PSGI_responder->($resp->finalize_sb);
      $resp->stream_writer($PSGI_writer);
      $resp->stream->();
      $PSGI_writer->close;
    } if $psgix_streaming;

    # Simulate streaming, use "do" to make it look consistent with the above
    return do {
      $resp->stream->();    # execute coderef
      $resp->stream(undef); # unset stream property
      $resp->finalize;      # finalize
    };
  }

  sub env_or_req_to_req ($class, $env_or_req) {
    if (ref $env_or_req and ref $env_or_req eq 'HASH') {
      return ($class->app_namespace . '::Request')->new($env_or_req);
    } elsif (blessed $env_or_req and $env_or_req->isa('PlackX::Framework::Request')) {
      return $env_or_req;
    }
    die 'Neither a PSGI-type HASH reference nor a PlackX::Framework::Request object.';
  }

  sub env_or_req_to_env ($class, $env_or_req) {
    if (ref $env_or_req and ref $env_or_req eq 'HASH') {
      return $env_or_req;
    } elsif (blessed $env_or_req and $env_or_req->isa('PlackX::Framework::Request')) {
      return $env_or_req->env;
    }
    die 'Neither a PSGI-type HASH reference nor a PlackX::Framework::Request object.';
  }
}

1;
