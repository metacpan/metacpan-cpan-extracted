#!perl
use v5.36;
use Test::More;

do_tests();
done_testing();

#######################################################################
#
# Most of PlackX::Framework::Handler is tested during integration tests
# of PlackX::Framework, but here we test its helper functions at least.
# We will avoid testing features that require other PXF components to
# work so that we don't get cascading failures.
#
#######################################################################

sub do_tests {

  require_ok('PlackX::Framework::Handler');

  #
  # test is_valid_response()
  #

  ok(
    not(PlackX::Framework::Handler::is_valid_response(undef)),
    'Undef is not a valid response'
  );

  ok(
    not(PlackX::Framework::Handler::is_valid_response('a string')),
    'A string is not a valid response'
  );

  ok(
    not(PlackX::Framework::Handler::is_valid_response({})),
    'Hashref is not a valid response'
  );

  ok(
    not(PlackX::Framework::Handler::is_valid_response([])),
    'Empty arrayref is not a valid response'
  );

  ok(
    not(PlackX::Framework::Handler::is_valid_response([1])),
    '1-element arrayrref is not a valid response'
  );

  ok(
    not(PlackX::Framework::Handler::is_valid_response([1,2,3,4])),
    '4-element arrayrref is not a valid response'
  );

  ok(
    PlackX::Framework::Handler::is_valid_response([500,[],[]]),
    'PSGI 3-element arrayref is valid response'
  );

  ok(
    PlackX::Framework::Handler::is_valid_response([500,[]]),
    'PSGI 2-element arrayref is valid response (for streaming)'
  );

  require Plack::Response;
  ok(
    PlackX::Framework::Handler::is_valid_response(Plack::Response->new),
    'Plack::Response is a valid response'
  );

  require Plack::Request;
  ok(
    not(PlackX::Framework::Handler::is_valid_response(Plack::Request->new({}))),
    'Plack::Request is not a valid response'
  );

  #
  # test psgi_response() (without streaming, that is an integration test)
  #
  {
    my $resp = [200,[],[]];
    is(
       PlackX::Framework::Handler::psgi_response($resp) => $resp,
      'PSGI arrayref is same arrayref given by psgi_response()'
    );
  }
  {
    my $resp = Plack::Response->new(200);
    is_deeply(
      PlackX::Framework::Handler::psgi_response($resp) => [200,[],[]],
      'Blank Plack::Response is turned into arrayref'
    );
  }

  #
  # test handle_request) - should fail without ENV
  #
  {
    my $success = eval { PlackX::Framework::Handler->handle_request; 1 };
    ok(
      !$success,
      'Cannot handle a request without ENV'
    );
  }

  #
  # TODO: see what more we can add
  #
}
