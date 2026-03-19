#!perl
use v5.36;
use Test::More;

do_tests();
done_testing();

#######################################################################

sub do_tests {
  require_ok('PlackX::Framework::Router');

  # Make an app
  ok(
    eval {
      package My::Test::App {
        use PlackX::Framework;
        use My::Test::App::Router;
      }
      1;
    },
    'Create a new app, import routing'
  );

  # Check to see if the DSL was imported
  ok(
    ref \&My::Test::App::base eq 'CODE',
    'DSL "base" keyword imported'
  );

  ok(
    ref \&My::Test::App::filter eq 'CODE',
    'DSL "filter" keyword imported'
  );

  ok(
    ref \&My::Test::App::global_filter eq 'CODE',
    'DSL "global_filter" keyword imported'
  );

  ok(
    ref \&My::Test::App::route eq 'CODE',
    'DSL "route" keyword imported'
  );

  # Set a URI base, add filters, and a route
  ok(
    eval {
      package My::Test::App {
        our $x = 0;

        # Route before base
        route '/no-base' => sub { return Plack::Response->new; };

        # Set a base for remainign routes
        base '/my-test-app';

        # Simple route, unfiltered
        route '/test1' => sub { $x = 3; };

        # Add some filters for remaining routes
        filter before => sub { $x = 1; return; };
        filter after  => sub { $x = 2; return; };

        # Route with param
        route '/test1/page/{some_param}' => sub { $x = 3.5; };

        # Route with method
        route get  => '/test1-method-get'  => sub { $x = 4; };
        route post => '/test1-method-post' => sub { $x = 5; };

        # Route with alternate methods
        route 'put|delete' => '/test1-put-or-delete' => sub { $x = 6; };

        # Route hashref test
        route {
          get => '/test1-hashref-get',
          put => '/test1-hashref-put',
        } => sub { $x = 7 };

        # Route arrayref test
        route ['/test1-aaa', '/test1-bbb'] => sub { $x = 8; };

        # Check for bug, the above routes shouldn't get the below filters
        filter before => sub { };
        filter after  => sub { };
        route '/last-route' => sub { };
      }
      1;
    },
    'Add a base, some filters, and some routes'
  );

  #######################
  # Test route matching #
  #######################
  my sub match {
    My::Test::App::Router->engine->match(@_)
  }
  my sub execute_filter ($filter) {
    return if !defined $filter;
    return $filter->() if ref $filter eq 'CODE';
    return $filter->{action}->() if ref $filter eq 'HASH';
    die "Invalid filter";
  }

  ok(
    match(sample_request(get => '/no-base')),
    'Should match no-base'
  );

  is(
    match(sample_request(get => '/my-test-app/no-base')) => undef,
    'Path without base should not match path after base'
  );

  is(
    match(sample_request(get => '/')) => undef,
    'Should not match without base'
  );

  is(
    match(sample_request(get => '/test1')) => undef,
    'Should not match without base'
  );

  is(
    match(sample_request(get => '/test1/page/blah')) => undef,
    'Should not match without base'
  );

  ok(
    match(sample_request(get => '/my-test-app/test1')),
    'Basic match ok'
  );

  ok(
    match(sample_request(get => '/my-test-app/test1/page/whatever')),
    'Param match ok'
  );

  is(
    match(sample_request(get => '/my-test-app/test1/page/whatever'))->{route_parameters}{some_param} => 'whatever',
    'Route param set successfully'
  );

  ok(
    match(sample_request(get => '/my-test-app/test1-method-get')),
    'Match with method get ok'
  );

  ok(
    match(sample_request(post => '/my-test-app/test1-method-post')),
    'Match with method post ok'
  );

  is(
    match(sample_request(post => '/my-test-app/test1-method-get')) => undef,
    'Get does not match post request'
  );

  is(
    match(sample_request(get => '/my-test-app/test1-method-post')) => undef,
    'Post does not match get request'
  );

  ok(
    match(sample_request(put => '/my-test-app/test1-put-or-delete')),
    'Match with method put|delete (put) ok'
  );

  ok(
    match(sample_request(delete => '/my-test-app/test1-put-or-delete')),
    'Match with method put|delete (delete) ok'
  );

  is(
    match(sample_request(get => '/my-test-app/test1-put-or-delete')) => undef,
    'Get request does not match put|delete'
  );

  is(
    match(sample_request(post => '/my-test-app/test1-put-or-delete')) => undef,
    'Post request does not match put|delete'
  );

  ok(
    match(sample_request(get => '/my-test-app/test1-hashref-get')),
    'Successful match hashref route (get)'
  );

  ok(
    match(sample_request(put => '/my-test-app/test1-hashref-put')),
    'Successful match hashref route (put)'
  );

  is_deeply(
    match(sample_request(get => '/my-test-app/test1-hashref-get')),
    match(sample_request(put => '/my-test-app/test1-hashref-put')),
    'Same route'
  );

  is(
    match(sample_request(get => '/my-test-app/test1-hashref-put')) => undef,
    'Should not match'
  );

  is(
    match(sample_request(put => '/my-test-app/test1-hashref-get')) => undef,
    'Should not match'
  );

  ok(
    match(sample_request(get => '/my-test-app/test1-aaa')),
    'Successful match arrayref route'
  );

  ok(
    match(sample_request(get => '/my-test-app/test1-bbb')),
    'Successful match arrayref route'
  );

  is(
    match(sample_request(get => '/my-test-app/test1-ccc')) => undef,
    'Should not match'
  );

  is_deeply(
    match(sample_request(get => '/my-test-app/test1-aaa')),
    match(sample_request(get => '/my-test-app/test1-bbb')),
    'Arrayref routes are the same route'
  );

  #######################
  # Test filters        #
  #######################
  {
    my $match = match(sample_request(get => '/my-test-app/test1'));
    is(
      $match->{prefilters} => undef,
      'First route should have no pre filters'
    );
    is(
      $match->{postfilters} => undef,
      'First route should have no post filters'
    );
  }
  {
    my $match = match(sample_request(get => '/my-test-app/test1/page/whatever'));
    is(
      ref $match->{prefilters} => 'ARRAY',
      'Second route has pre filters'
    );
    is(
      ref $match->{prefilters} => 'ARRAY',
      'Second route has post filters'
    );

    my $prefilter = $match->{prefilters}[0];
    $prefilter = (ref $prefilter eq 'CODE') ? $prefilter : $prefilter->{action};
    execute_filter($prefilter);

    is(
      $My::Test::App::x => 1,
      'Prefilter set a variable'
    );

    my $postfilter = $match->{postfilters}[0];
    $postfilter = (ref $postfilter eq 'CODE') ? $postfilter : $postfilter->{action};
    execute_filter($postfilter);

    is(
      $My::Test::App::x => 2,
      'Prefilter set a variable'
    );
  }
  {
    my $match = match(sample_request(get => '/my-test-app/test1-aaa'));
    is(
      ref $match->{prefilters} => 'ARRAY',
      'Last route has pre filters'
    );
    is(
      ref $match->{prefilters} => 'ARRAY',
      'Last route has post filters'
    );
  }

  # Add a global filter
  ok(
    eval {
      package My::Test::App {
        our $x;
        global_filter before => sub { $x = 100; };
        global_filter after  => sub { $x = 200; };
      }
      1;
    },
    'Add global filters (DSL style)'
  );

  # Test path with global filter
  {
    my $match = match(sample_request(get => '/my-test-app/test1'));
    ok(
      eval { @{$match->{prefilters}} == 1 },
      'First route should now have one pre filters'
    );
    ok(
      eval { @{$match->{prefilters}} == 1 },
      'First route should now have one post filters'
    );
    ok(
      eval { execute_filter($match->{prefilters}[0]); 1 },
      'Execute first global prefilter'
    );
    is(
      $My::Test::App::x => 100,
      'Prefilter set a variable',
    );
    ok(
      eval { execute_filter($match->{postfilters}[0]); 1 },
      'Execute first global postfilter'
    );
    is(
      $My::Test::App::x => 200,
      'Postfilter set a variable',
    );
  }

  # Test with global and local filters; global is first, then local
  {
    my $match = match(sample_request(get => '/my-test-app/test1-aaa'));
    ok(
      eval { @{$match->{prefilters}} == 2 },
      'First route should now have two pre filters (one global, one local)'
    );
    ok(
      eval { @{$match->{postfilters}} == 2 },
      'First route should now have two post filters (one global, one local)'
    );
    ok(
      eval {
        execute_filter($match->{prefilters}[0]);
        execute_filter($match->{prefilters}[1]);
        1;
      },
      'Execute both pre filters'
    );
    is(
      $My::Test::App::x => 1,
      'Local filter executed after global filter'
    );
    ok(
      eval {
        execute_filter($match->{postfilters}[0]);
        execute_filter($match->{postfilters}[1]);
        1;
      },
      'Execute both post filters'
    );
    is(
      $My::Test::App::x => 200,
      'Global postfilter executed after local filter'
    );
  }

  # Use class method syntax
  ok(
    eval {
      package My::Test::App::Controller {
        My::Test::App::Router->add_route('/classy-uri', sub { });
        My::Test::App::Router->add_route({ get =>  '/classy-get' },  sub { });
        My::Test::App::Router->add_route({ post => '/classy-post' }, sub { });
        My::Test::App::Router->add_route(['/class-1', '/class-2'] => sub { });

        My::Test::App::Router->add_route('/restricted', sub { });
        My::Test::App::Router->add_route('/restricted/{page}', sub { });

        My::Test::App::Router->add_route('/verbatim', sub { });
        My::Test::App::Router->add_route('/verbatim/{page}', sub { });

        My::Test::App::Router->add_route('/{dir}/yellow' => sub { });
        My::Test::App::Router->add_route('/{dir}/orange' => sub { });

        # It shouldn't matter where we add them
        My::Test::App::Router->add_global_filter(before => sub { 'b4'; }); # idx 1
        My::Test::App::Router->add_global_filter(after  => sub { '4b'; });

        My::Test::App::Router->add_global_filter(before => '/restricted' => sub { 'restrict'; }); # idx 2 if applied
        My::Test::App::Router->add_global_filter(before => \'/verbatim'  => sub { 'verbatim'; }); # idx 2 if applied

        My::Test::App::Router->add_global_filter(before => qr|/(.+)/yellow| => sub { 'yellow' }); # idx 2 if applied
      }
      1;
    },
    'Add routes and filters using class method syntax'.$@
  );
  ok(
    match(sample_request(get => '/classy-uri')),
    'Match a class method route'
  );
  is(
    match(sample_request(get => '/my-test-app/classy-uri')) => undef,
    'Should not match with base from different class'
  );
  my $match = match(sample_request(get => '/classy-uri'));
  is(
    execute_filter($match->{prefilters}[1]) => 'b4',
    'Execute filter added via class method (second added=index 1)'
  );
  is(
    execute_filter(match(sample_request(get => '/restricted'))->{prefilters}[2]) => 'restrict',
    'Global filter applied via class method works'
  );
  is(
    execute_filter(match(sample_request(get => '/restricted/boo'))->{prefilters}[2]) => 'restrict',
    'Global filter applied via class method works using substr pattern'
  );
  is(
    execute_filter(match(sample_request(get => '/verbatim'))->{prefilters}[2]) => 'verbatim',
    'Global filter applied via class method using scalar ref (verbatim string) works'
  );
  is(
    match(sample_request(get => '/verbatim/boo'))->{prefilters}[2] => undef,
    'Global filter using scalar ref (verbatim string) does not match when not supposed to'
  );
  is(
    execute_filter(match(sample_request(get => '/something/yellow'))->{prefilters}[2]) => 'yellow',
    'Regex filter matching works'
  );
  is(
    match(sample_request(get => '/something/orange'))->{prefilters}[2] => undef,
    'Regex filter matching does not match when it is not supposed to'
  );


  # Create a new app and change keywords
  ok(
    eval {
      package My::Test::App2 {
        use PlackX::Framework;
      }
      package My::Test::App2::Router {
        sub global_filter_request_keyword { 'my_gfilter' }
        sub filter_request_keyword        { 'my_lfilter' }
        sub route_request_keyword         { 'my_request' }
        sub uri_base_keyword              { 'my_uri'     }
      }
      package My::Test::App2::Controller {
        use My::Test::App2::Router;
        my_request '/another_test' => sub { };
      }
      1;
    },
    'Create router with custom keyword names'
  );
  ok(\&My::Test::App2::Controller::my_gfilter, 'Imported custom keyword for global_filter');
  ok(\&My::Test::App2::Controller::my_lfilter, 'Imported custom keyword for filter');
  ok(\&My::Test::App2::Controller::my_request, 'Imported custom keyword for route');
  ok(\&My::Test::App2::Controller::my_uri,     'Imported custom keyword for base');

  is(
    match(sample_request(get => '/another_test')) => undef,
    'Request to new app not answered by old app'
  );

  my sub match2 {
    My::Test::App2::Router->engine->match(@_)
  }

  ok(
    match2(sample_request(get => '/another_test')),
    'Request to new app is answered by new app'
  );

  # Create another app and use ONLY class method syntax
  # Do not import from the Router class
  ok(
    eval {
      package My::Test::App3 {
        use PlackX::Framework;
        My::Test::App3::Router->add_route('/app3' => sub { 333; });
      }
      1;
    },
    'Create an app with a route without importing from ::Router'
  );

  my sub match3 {
    My::Test::App3::Router->engine->match(@_)
  }
  is(
    match3(sample_request(get => '/app3'))->{action}->() => '333',
    'Request to third app gets result'
  );
  is(
    match3(sample_request(get => '/another_test')) => undef,
    'Apps do not interfere with each other'
  );


}

#######################################################################
# Helpers

sub sample_request {
  return PlackX::Framework::Request->new(sample_env(@_));
}

sub sample_env ($method = 'GET', $uri = '/') {
  return {
    REQUEST_METHOD    => uc $method,
    SERVER_PROTOCOL   => 'HTTP/1.1',
    SERVER_PORT       => 80,
    SERVER_NAME       => 'example.com',
    SCRIPT_NAME       => $uri,
    REMOTE_ADDR       => '127.0.0.1',
    PATH_INFO         => $uri,
    'psgi.version'    => [ 1, 0 ],
    'psgi.input'      => undef,
    'psgi.errors'     => undef,
    'psgi.url_scheme' => 'http',
  }
}
