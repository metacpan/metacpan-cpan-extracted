use Mojo::Base -strict;
use Mojo::JSON 'true';
use OpenAPI::Client;
use Test::More;

use Mojolicious::Lite;
app->log->level('error') unless $ENV{HARNESS_IS_VERBOSE};

my $i = 0;
get '/pets/:type' => sub {
  $i++;
  my $c = shift->openapi->valid_input or return;
  return $c->render(openapi => [{type => $c->param('type')}]);
  },
  'listPets';

post '/pets' => sub {
  my $c = shift->openapi->valid_input or return;
  my $res = $c->req->body_params->to_hash;
  $res->{dummy} = true if $c->req->headers->header('x-dummy');
  return $c->render(openapi => $res);
  },
  'addPet';

plugin OpenAPI => {url => 'data://main/test.json'};

is(OpenAPI::Client->new('data://main/test.json')->base_url, 'http://api.example.com/v1', 'base_url');

my $client = OpenAPI::Client->new('data://main/test.json', app => app);
my ($obj, $tx);

is +ref($client), 'OpenAPI::Client::main_test_json', 'generated class';
isa_ok($client, 'OpenAPI::Client');
can_ok($client, 'addPet');

note 'Sync testing';
$tx = $client->listPets;
is $tx->res->code, 400, 'sync invalid listPets';
is $tx->error->{message}, 'Invalid input', 'sync invalid message';
is $i, 0, 'invalid on client side';

$tx = $client->listPets({type => 'dog', p => 12});
is $tx->res->code, 200, 'sync listPets';
is $tx->req->url->query->param('p'), 12, 'sync listPets p=12';
is $i, 1, 'one request';

$tx = $client->addPet({type => 'dog', name => 'Pluto', 'x-dummy' => true});
is_deeply $tx->res->json, {dummy => true, type => 'dog', name => 'Pluto'}, 'sync addPet';

note 'Async testing';
$i = 0;
is $client->listPets(sub { ($obj, $tx) = @_; Mojo::IOLoop->stop }), $client, 'async request';
Mojo::IOLoop->start;
is $obj, $client, 'got client in callback';
is $tx->res->code, 400, 'invalid listPets';
is $tx->error->{message}, 'Invalid input', 'sync invalid message';
is $i, 0, 'invalid on client side';

done_testing;

__DATA__
@@ test.json
{
  "swagger": "2.0",
  "info": { "version": "0.8", "title": "Test client spec" },
  "schemes": [ "http" ],
  "host": "api.example.com",
  "basePath": "/v1",
  "paths": {
    "x-whatever": [],
    "/pets": {
      "x-whatever": [],
      "parameters": [
        { "$ref": "#/parameters/name" }
      ],
      "post": {
        "x-whatever": [],
        "operationId": "addPet",
        "parameters": [
          { "in": "header", "name": "x-dummy", "type": "boolean" },
          { "in": "formData", "name": "type", "type": "string" }
        ],
        "responses": {
          "200": {
            "description": "pet response",
            "schema": { "type": "object" }
          }
        }
      }
    },
    "/pets/{type}": {
      "get": {
        "operationId": "listPets",
        "x-mojo-to": "listPets",
        "parameters": [
          { "in": "path", "name": "type", "type": "string", "required": true },
          { "$ref": "#/parameters/p" }
        ],
        "responses": {
          "200": {
            "description": "pet response",
            "schema": { "$ref": "#/definitions/ok" }
          }
        }
      }
    }
  },
  "parameters": {
    "name": { "in": "formData", "name": "name", "type": "string" },
    "p": { "in": "query", "name": "p", "type": "integer" }
  },
  "definitions": {
    "ok": { "type": "array" }
  }
}
