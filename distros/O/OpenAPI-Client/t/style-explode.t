use Mojo::Base -strict;
use OpenAPI::Client;
use Test::More;

use Mojolicious::Lite;
app->log->level('error') unless $ENV{HARNESS_IS_VERBOSE};

# Echo the received query parameters straight back, so the test can assert on
# what the client actually put on the wire.
get '/x'    => sub { my $c = shift; $c->render(json => $c->req->url->query->to_hash) }, 'getX';
get '/form' => sub { my $c = shift; $c->render(json => $c->req->url->query->to_hash) }, 'getForm';

# Object parameters serialized with style "deepObject"/"form" and explode are
# handed to the validate_request callback with an undefined name, asking for
# the whole parameter hash. Regression test for
# https://github.com/jhthorsen/json-validator/issues/282
my $client = OpenAPI::Client->new('data://main/test.json', app => app);

subtest 'deepObject explode' => sub {
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, $_[0] };

  my $tx = $client->getX({'deep[a]' => 'hello', 'deep[b]' => 'world'});

  ok !$tx->res->error, 'request is valid' or diag $tx->res->body;
  is_deeply $tx->req->url->query->to_hash, {'deep[a]' => 'hello', 'deep[b]' => 'world'},
    'deepObject keys passed through to the query string';
  is_deeply \@warnings, [], 'no uninitialized-value warning';
};

subtest 'deepObject explode nested' => sub {
  my $tx = $client->getX({'deep[a]' => 'x', 'deep[c][gte]' => '1'});
  ok !$tx->res->error, 'nested request is valid' or diag $tx->res->body;
  is_deeply $tx->req->url->query->to_hash, {'deep[a]' => 'x', 'deep[c][gte]' => '1'},
    'nested deepObject keys passed through';
};

subtest 'deepObject explode missing optional param' => sub {
  my $tx = $client->getX({});
  ok !$tx->res->error, 'request without the optional object is valid' or diag $tx->res->body;
  is $tx->req->url->query->to_string, '', 'no query string when object omitted';
};

subtest 'form explode object' => sub {
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, $_[0] };

  my $tx = $client->getForm({lat => '1.5', lon => '2.5'});
  ok !$tx->res->error, 'form-exploded object is valid' or diag $tx->res->body;
  is_deeply $tx->req->url->query->to_hash, {lat => '1.5', lon => '2.5'},
    'form-exploded object properties passed through';
  is_deeply \@warnings, [], 'no uninitialized-value warning';
};

done_testing;

__DATA__
@@ test.json
{
  "openapi": "3.0.0",
  "info": { "title": "style/explode", "version": "0" },
  "servers": [{ "url": "http://api.example.com" }],
  "paths": {
    "/x": {
      "get": {
        "operationId": "getX",
        "parameters": [
          {
            "name": "deep",
            "in": "query",
            "style": "deepObject",
            "explode": true,
            "schema": {
              "type": "object",
              "properties": {
                "a": { "type": "string" },
                "b": { "type": "string" },
                "c": {
                  "type": "object",
                  "properties": { "gte": { "type": "string" } }
                }
              }
            }
          }
        ],
        "responses": { "200": { "description": "ok" } }
      }
    },
    "/form": {
      "get": {
        "operationId": "getForm",
        "parameters": [
          {
            "name": "loc",
            "in": "query",
            "style": "form",
            "explode": true,
            "schema": {
              "type": "object",
              "properties": {
                "lat": { "type": "string" },
                "lon": { "type": "string" }
              }
            }
          }
        ],
        "responses": { "200": { "description": "ok" } }
      }
    }
  }
}
