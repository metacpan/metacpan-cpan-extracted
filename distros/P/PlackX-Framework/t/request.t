#!perl
use v5.36;
use Test::More;

package MyExample::Request {
  use parent 'PlackX::Framework::Request';
  sub app_namespace { 'MyExample' }
}

{
  # Require
  require_ok('PlackX::Framework::Request');

  # Create object
  my $request = MyExample::Request->new(sample_env());
  ok($request, 'Create request object');
  isa_ok($request, 'PlackX::Framework::Request');

  # Request properties
  ok( $request->isa('Plack::Request' ));
  ok(!$request->isa('Plack::Response'));

  ok($request->is_get);
  ok(!$request->is_post);
  ok(!$request->is_put);
  ok(!$request->is_delete);
  ok(!$request->is_ajax);

  # Stash
  my $stash = { boo => 'who' };
  $request->stash($stash);
  ok($request->stash->{boo} eq 'who');

  # Routes
  ok($request->destination eq $request->path_info);
  $request->reroute('/new');
  ok($request->destination eq '/new');

  # Namespace
  ok($request->app_namespace eq 'MyExample');

  # Route Params
  $request->route_parameters({ user_id => '8', page => 'paper' });
  ok($request->route_param('user_id') eq '8');
  ok($request->route_param('page') eq 'paper');

  # Params
  ok(my $food = $request->param('food') eq 'pizza');
  ok(my $drink = $request->param('drink') =~ m/^(beer|pepsi|wine|water)$/);
  my @drinks = $request->cgi_param('drink');
  ok(@drinks == 4);
  my @sdrinks = $request->param('drink');
  ok(@sdrinks == 1);

  # Flash
  require PlackX::Framework;
  ok(substr($request->flash_cookie_name, 0, 5) eq 'flash');
  ok(8 < length $request->flash_cookie_name < 64);

  {
    # We have to subclass to override flash_cookie_name()
    eval q{
      package PXF_Test_Request {
        use parent 'PlackX::Framework::Request';
        sub app_namespace     { die }
        sub flash_cookie_name { 'flash-123456789-test' }
      }
      1;
    } or die 'Could not create sublcass of PXFR: ' .$@;

    my $env = sample_env();
    $env->{HTTP_COOKIE} = 'flash-123456789-test=A%20Plain%20String';
    $request = PXF_Test_Request->new($env);
    is(
      $request->flash => 'A Plain String',
      'Flash is correct'
    );
  }
  {
    my $env  = sample_env();
    my $hash = { key => 'value', key2 => 'value2', arr => [1..9] };
    my $val  = PXF::Util::encode_ju64($hash);
    $env->{HTTP_COOKIE} = "flash-123456789-test=flash-123456789-test-ju64-$val";
    $request = PXF_Test_Request->new($env);
    is_deeply(
      $request->flash => $hash,
      'Flash is correct (JSON-encoded hashref)'
    );
  }
}

done_testing();

####################################################

sub sample_env {
  return {
    REQUEST_METHOD    => 'GET',
    SERVER_PROTOCOL   => 'HTTP/1.1',
    SERVER_PORT       => 80,
    SERVER_NAME       => 'example.com',
    SCRIPT_NAME       => '/foo',
    REMOTE_ADDR       => '127.0.0.1',
    PATH_INFO         => '/foo',
    REQUEST_URI       => '/foo',
    HTTP_COOKIE       => 'NOT_IMPLEMENTED=NOT_IMPLEMENTED',
    QUERY_STRING      => 'food=pizza&drink=beer&drink=pepsi&drink=wine&drink=water',
    'psgi.version'    => [ 1, 0 ],
    'psgi.input'      => undef,
    'psgi.errors'     => undef,
    'psgi.url_scheme' => 'http',
  }
};
