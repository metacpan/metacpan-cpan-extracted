#!perl
use v5.36;
use Test::More;

do_tests();
done_testing();

#######################################################################

sub do_tests {

  # use() PlackX::Framework
  eval q{
    package My::Test::App2 {
      use PlackX::Framework;
      use My::Test::App2::Router;
      # TODO: Currently, an app with no routes breaks!
      # Add a default route or warn if no routes?
      route '/' => sub ($request, $response) {
        $response->print('Hello world!');
        $response;
      };

      route '/a' => sub ($request, $response) {
        return $request->reroute('/b');
      };

      route '/b' => sub ($request, $response) {
        $response->print('Reroute Test 1');
        $response;
      };

      route '/aa/bb/cc' => sub ($request, $response) {
        return $request->reroute('/cc/bb/aa');
      };

      route '/xx/yy/zz' => sub ($request, $response) {
        $response->redirect($request->uri_to('/b'));
        return $response;
      };

      route '/cc/bb/aa' => sub ($request, $response) {
        if (my $to = $request->param('uri_to')) {
          $response->print($request->uri_to("/$to"));
        } else {
          $response->print('Reroute Test 2');
        }
        return $response;
      };
    }
    1;
  } or die "Problem setting up test: $@";

  ok(My::Test::App2->can('app'),
    'app() class method generated'
  );

  ok(My::Test::App2::Handler->can('build_app'),
    'Handler::build_app method generated'
  );

  my $app = My::Test::App2::Handler->build_app;
  ok(
    (ref $app and ref $app eq 'CODE'),
    'Handler->build_app returns a coderef'
  );

  my $app2 = My::Test::App2->app;
  ok(
    (ref $app2 and ref $app2 eq 'CODE'),
    'AppNamespace->app returns a coderef'
  );

  my $result = $app->(test_env());
  ok(
    (ref $result and ref $result eq 'ARRAY'),
    'Handler->to_app->() returns arrayref'
  );

  ok(
    ($result->[0] == 200 and $result->[2][0] eq 'Hello world!'),
    'Handler->to_app->() response is as expected'
  );

  my $result2 = $app2->(test_env());
  is_deeply(
    $result, $result2,
    'Calling Handler->to_app->() and App->app->() gives same result'
  );

  #
  # Check re-routing feature
  #
  use Plack::Test;
  use HTTP::Request::Common;
  test_psgi My::Test::App2->app, sub ($cb) {
    my $response = $cb->(GET "/a");
    is(
      $response->content => "Reroute Test 1",
      'Reroute Test 1'
    );
  };

  test_psgi My::Test::App2->app, sub ($cb) {
    my $response = $cb->(GET "/aa/bb/cc");
    is(
      $response->content => "Reroute Test 2",
      'Reroute Test 2'
    );
  };

  #
  # Check to see if routes play nice with builder
  #
  use Plack::Builder;
  my $builder_app = builder {
    mount "/wonderland/alice" => My::Test::App2->app;
  };

  test_psgi $builder_app, sub ($cb) {
    my $response = $cb->(GET "/wonderland/alice/a");
    is(
      $response->content => "Reroute Test 1",
      'Reroute Test 1 inside builder'
    );
  };

  test_psgi $builder_app, sub ($cb) {
    my $response = $cb->(GET "/wonderland/alice/aa/bb/cc");
    is(
      $response->content => "Reroute Test 2",
      'Reroute Test 2 inside builder'
    );
  };

  test_psgi $builder_app, sub ($cb) {
    my $response = $cb->(GET "/wonderland/alice/aa/bb/cc?uri_to=b");
    is(
      $response->content => "http://localhost/wonderland/alice/b",
      'Reroute and uri_to test'
    );
  };

  test_psgi $builder_app, sub ($cb) {
    my $response = $cb->(GET "/wonderland/alice/xx/yy/zz");
    is(
      $response->header('Location') => "http://localhost/wonderland/alice/b",
      'Redirect test inside builder'
    );
  };


  # use() PlackX::Framework with all optional modules
  ok(
    eval q{
      package My::Test::App2b {
        use PlackX::Framework qw(:all);
        use My::Test::App2b::Router;
        use My::Test::App2b::Config './t/tsupport/config.pl';
        my $config = config();
        # TODO: Currently, an app with no routes breaks!
        # Add a default route or warn if no routes?
        route '/' => sub ($request, $response) {
          $response->print('Hello world!');
          $response;
        };
      }
      1;
    },
    'Create an app with optional components'
  );

}

#######################################################################

sub test_env {
  return {
    'psgi.version' => [1, 1],
    'psgi.errors' => *::STDERR,
    'psgi.multiprocess' => '',
    'psgi.multithread' => '',
    'psgi.nonblocking' => '',
    'psgi.run_once' => '',
    'psgi.streaming' => 0,
    'psgi.url_scheme' => 'http',
    'psgix.harakiri' => 1,
    'psgix.input.buffered' => 1,
    'QUERY_STRING' => '',
    'HTTP_ACCEPT' => 'text/html,text/plain',
    'REQUEST_METHOD' => 'GET',
    'HTTP_USER_AGENT' => 'Mock',
    'HTTP_SEC_FETCH_DEST' => 'document',
    'SCRIPT_NAME' => '',
    'HTTP_SEC_CH_UA' => '"Google Chrome";v="93", " Not;A Brand";v="99", "Chromium";v="93"',
    'HTTP_ACCEPT_LANGUAGE' => 'en-US,en;q=0.9',
    'HTTP_SEC_FETCH_USER' => '?1',
    'SERVER_PROTOCOL' => 'HTTP/1.1',
    'HTTP_SEC_FETCH_SITE' => 'none',
    'PATH_INFO' => '/',
    'HTTP_DNT' => '1',
    'HTTP_CACHE_CONTROL' => 'max-age=0',
    'HTTP_ACCEPT_ENCODING' => 'gzip, deflate, br',
    'REMOTE_ADDR' => '127.0.0.1',
    'HTTP_HOST' => 'localhost:5000',
    'SERVER_NAME' => 0,
    'REMOTE_PORT' => 62037,
    'SERVER_PORT' => 5000,
    'HTTP_UPGRADE_INSECURE_REQUESTS' => '1',
    'HTTP_SEC_FETCH_MODE' => 'navigate',
    'REQUEST_URI' => '/'
  };
}
