#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use HTTP::Response;
use LWP::UserAgent;
use FakeAuthentik;
use FakeHTTP;
use Net::Async::Authentik;

sub error_of (&) { my ( $code ) = @_; eval { $code->(); 1 } ? undef : $@ }

my $fake = FakeAuthentik->new;
my $provider = $fake->add( providers => {
  name => 'probe-provider', client_id => 'probe-client', client_secret => 'probe-secret',
  authorization_flow => 'f', invalidation_flow => 'f', redirect_uris => [], grant_types => ['client_credentials']
} );
$fake->add( applications => { name => 'Probe App', slug => 'probe-app', provider => $provider->{pk} } );
my $ak  = Net::Async::Authentik->new( base_url => $fake->base, application => 'probe-app', token => $fake->token, http => FakeHTTP->new( fake => $fake ) );
my $api = $ak->api;

subtest 'classes and stringification' => sub {
  my $e = Net::Async::Authentik::Error::API->new( message => 'boom', http_status => 400 );
  isa_ok( $e, 'Net::Async::Authentik::Error' );
  is( "$e", 'boom', 'stringifies to the message' );
  ok( $e->is_bad_request, 'is_bad_request' );
  ok( !$e->is_not_found && !$e->is_forbidden && !$e->is_unauthorized, 'and nothing else' );
  is_deeply( $e->field_errors, {}, 'no field errors by default' );
  isa_ok( Net::Async::Authentik::Error::Validation->new( message => 'x' ), 'Net::Async::Authentik::Error' );
  isa_ok( Net::Async::Authentik::Error::Network->new( message => 'x' ), 'Net::Async::Authentik::Error' );
  isa_ok( error_of { Net::Async::Authentik::Error::Validation->throw( message => 'thrown' ) },
    'Net::Async::Authentik::Error::Validation', 'throw' );
};

subtest 'the detail shape' => sub {
  my $missing = error_of { $api->get_user_f(999999)->get };
  isa_ok( $missing, 'Net::Async::Authentik::Error::API' );
  is( $missing->http_status, 404, 'status as a number' );
  is( $missing->api_message, 'No User matches the given query.', 'detail' );
  ok( $missing->is_not_found, 'is_not_found' );
  is_deeply( $missing->field_errors, {}, 'no field errors' );
  is( $missing->oauth_error, undef, 'and no OAuth code' );
  like( "$missing", qr{\QGET http://ak.test/api/v3/core/users/999999/ failed: 404\E}, 'the message names the request' );

  my $wrong_method = error_of { $api->call_f( PATCH => '/stages/all/'.$fake->_uuid.'/', {} )->get };
  is( $wrong_method->http_status, 405, '405 is a detail too' );
  like( $wrong_method->api_message, qr/not allowed/, 'with its text' );
};

subtest 'the field shape' => sub {
  $api->create_user_f( { username => 'alice', name => 'Alice' } )->get;
  my $duplicate = error_of { $api->create_user_f( { username => 'alice', name => 'Alice' } )->get };
  is( $duplicate->http_status, 400, 'a duplicate is 400, not 409' );
  ok( $duplicate->is_bad_request, 'is_bad_request' );
  is_deeply( $duplicate->field_errors, { username => ['This field must be unique.'] }, 'field_errors' );
  is( $duplicate->api_message, 'username: This field must be unique.', 'api_message names the field' );

  my $empty = error_of { $api->create_user_f( {} )->get };
  is_deeply( [ sort keys %{ $empty->field_errors } ], [qw( name username )], 'several fields at once' );
  like( $empty->api_message, qr/name: .*; username: /, 'joined to one line' );

  my $nested = error_of { $api->update_oauth2_provider_f( $provider->{pk}, { grant_types => ['banana'] } )->get };
  is_deeply( $nested->field_errors, { 'grant_types.0' => ['"banana" is not a valid choice.'] },
    'a nested field error is flattened with a dot' );

  my $binding = error_of { $api->create_binding_f( {} )->get };
  is_deeply( [ sort keys %{ $binding->field_errors } ], [qw( order stage target )], 'required fields' );
  $api->delete_user_f( $api->find_user_f('alice')->get->{pk} )->get;
};

subtest 'a refused token' => sub {
  my $wrong = Net::Async::Authentik->new( base_url => $fake->base, token => 'a-token-that-is-not-right', http => FakeHTTP->new( fake => $fake ) );
  my $error = error_of { $wrong->api->me_f->get };
  is( $error->http_status, 403, 'authentik answers 403, not 401' );
  ok( $error->is_forbidden, 'is_forbidden' );
  ok( !$error->is_unauthorized, 'and not is_unauthorized' );
  is( $error->api_message, 'Token invalid/expired', 'detail' );
  unlike( "$error", qr/a-token-that-is-not-right/, 'the token is not in the message' );

  my $naked = LWP::UserAgent->new;
  my $none  = error_of { $fake->request( HTTP::Request->new( GET => $fake->base.'/api/v3/core/users/me/' ) ) };
  my $answer = $fake->request( HTTP::Request->new( GET => $fake->base.'/api/v3/core/users/me/' ) );
  is( $answer->code, 403, 'and without any token as well' );
};

subtest 'the OAuth shape' => sub {
  my $oidc  = $ak->oidc;
  my $oauth = error_of { $oidc->client_credentials_token_f( client_id => 'probe-client', client_secret => 'the-wrong-secret' )->get };
  isa_ok( $oauth, 'Net::Async::Authentik::Error::API' );
  is( $oauth->oauth_error, 'invalid_grant', 'oauth_error' );
  like( $oauth->api_message, qr/\Ainvalid_grant: /, 'api_message is the code with its description' );
  ok( $oauth->request_id, 'request_id' );
  unlike( "$oauth", qr/the-wrong-secret/, 'the secret is not in the message' );

  is( error_of { $oidc->client_credentials_token_f( client_id => 'nobody', client_secret => 'x' )->get }->oauth_error,
    'invalid_client', 'an unknown client' );
};

subtest 'an empty body with a header' => sub {
  my $error = error_of { $ak->oidc->userinfo_f('garbage')->get };
  is( $error->http_status, 401, 'the status is 401' );
  ok( $error->is_unauthorized, 'is_unauthorized' );
  is( $error->oauth_error, 'invalid_token', 'the code out of the WWW-Authenticate header' );
  like( $error->api_message, qr/expired, revoked, malformed/, 'and the description out of it too' );
};

subtest 'a body that did not come from authentik' => sub {
  # a proxy, or a base_url pointing somewhere else, answers HTML or text, and
  # saying only "404 Not Found" would leave the reader with nothing
  my $reader = FakeAuthentik->new;
  my $probe  = Net::Async::Authentik::API->new( base_url => 'http://x', token => 't', http => FakeHTTP->new( fake => $reader ) );

  my %shapes = (
    'an HTML page'  => [ 'text/html', '<html><head><title>502 Bad Gateway</title></head><body>nginx</body></html>' ],
    'plain text'    => [ 'text/plain', "upstream timed out\n" ],
    'a JSON array'  => [ 'application/json', '["one","two"]' ]
  );
  for my $why ( sort keys %shapes ) {
    my ( $type, $content ) = @{ $shapes{$why} };
    my $response = HTTP::Response->new( 502, 'Bad Gateway', [ 'Content-Type' => $type ], $content );
    my $error = error_of { $probe->read_response( $response, GET => 'http://x/api/v3/core/users/' ) };
    isa_ok( $error, 'Net::Async::Authentik::Error::API', $why );
    ok( defined $error->api_message && length $error->api_message, $why.': says something' );
    like( $error->body, qr/\Q$content\E/, $why.': and keeps the body' );
  }

  my $long = HTTP::Response->new( 500, 'Server Error', [ 'Content-Type' => 'text/plain' ], 'x' x 2000 );
  my $cut  = error_of { $probe->read_response( $long, GET => 'http://x/' ) };
  cmp_ok( length $cut->body, '<', 600, 'a long body is cut down' );
  cmp_ok( length $cut->api_message, '<', 250, 'and the message more so' );

  my $empty = HTTP::Response->new( 500, 'Server Error', [], '' );
  is( error_of { $probe->read_response( $empty, GET => 'http://x/' ) }->body, undef, 'an empty body stays undef' );
};

subtest 'a compressed answer' => sub {
  # decoded_content undoes the Content-Encoding, the raw content does not;
  # reading the raw one would lose the whole body to any user agent that
  # asked for gzip
  SKIP: {
    eval { require IO::Compress::Gzip; 1 } or skip 'IO::Compress::Gzip is not here', 2;
    my $json = '{"pk":7,"username":"alice"}';
    IO::Compress::Gzip::gzip( \$json => \my $gzipped );
    my $response = HTTP::Response->new( 200, 'OK',
      [ 'Content-Type' => 'application/json', 'Content-Encoding' => 'gzip' ], $gzipped );
    my $probe  = Net::Async::Authentik::API->new( base_url => 'http://x', token => 't', http => FakeHTTP->new( fake => FakeAuthentik->new ) );
    my $result = $probe->read_response( $response, GET => 'http://x/api/v3/core/users/7/' );
    is( $result->{data}{username}, 'alice', 'the body survives gzip' );
    is( $result->{content}, $json, 'and content is the decoded one' );
  }
};

subtest 'no answer at all' => sub {
  my $down  = Net::Async::Authentik->new( base_url => 'http://127.0.0.1:9', application => 'x',
    http => Net::Async::HTTP->new( timeout => 2 ) );
  my $error = error_of { $down->oidc->discovery_f->get };
  isa_ok( $error, 'Net::Async::Authentik::Error::Network' );
  like( "$error", qr{\QGET http://127.0.0.1:9/application/o/x/.well-known/openid-configuration\E}, 'names the request' );
};

done_testing;
