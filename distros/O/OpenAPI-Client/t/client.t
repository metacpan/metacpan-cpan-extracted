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
  $c->render(openapi => [{type => $c->param('type')}]);
  },
  'listPetsByType';

get '/pets' => sub {
  my $c = shift->openapi->valid_input or return;
  $c->render(openapi => [$c->req->params->to_hash]);
  },
  'list pets';

post '/pets' => sub {
  my $c   = shift->openapi->valid_input or return;
  my $res = $c->req->body_params->to_hash;
  $res->{dummy} = true if $c->req->headers->header('x-dummy');
  $c->render(openapi => $res);
  },
  'addPet';

plugin OpenAPI => {url => 'data://main/test.json'};

is(OpenAPI::Client->new('data://main/test.json')->base_url,       'http://api.example.com:3000/v1', 'base_url');
is(OpenAPI::Client->new('data://main/test.json')->base_url->host, 'api.example.com',                'base_url host');
is(OpenAPI::Client->new('data://main/test.json')->base_url->port, '3000',                           'base_url port');

my $client = OpenAPI::Client->new('data://main/test.json', app => app);
my ($obj, $tx);

is +ref($client), 'OpenAPI::Client::main_test_json', 'generated class';

isa_ok($client, 'OpenAPI::Client');
can_ok($client, 'addPet');

subtest 'subclassing' => sub {
  package OpenAPI::Child {
    use Mojo::Base 'OpenAPI::Client';
    sub frobnicate {}
  }
  my $old_client = OpenAPI::Client->new('data://main/test.json');
  my $new_client = OpenAPI::Child->new('data://main/test.json');
  can_ok($new_client, 'frobnicate');
  ok(!$old_client->can('frobnicate'), 'does not bleed over');
};

note 'Sync testing';
$tx = $client->listPetsByType;
is $tx->res->code, 400, 'sync invalid listPetsByType';
is $tx->error->{message}, 'Invalid input', 'sync invalid message';
is $i, 0, 'invalid on client side';

$tx = $client->listPetsByType({type => 'dog', p => 12});
is $tx->res->code, 200, 'sync listPetsByType';
is $tx->req->url->query->param('p'), 12, 'sync listPetsByType p=12';
is $i, 1, 'one request';

$tx = $client->addPet({age => '5', type => 'dog', name => 'Pluto', 'x-dummy' => true});
is $tx->res->code, 200, 'coercion for "age":"5" works';
ok $tx->remote_address, 'server side response';

$tx = $client->addPet({});
is $tx->req->method, 'POST', 'correct method on invalid input';
ok !$tx->remote_address, 'client side error';

note 'Async testing';
$i = 0;
is $client->listPetsByType(sub { ($obj, $tx) = @_; Mojo::IOLoop->stop }), $client, 'async request';
Mojo::IOLoop->start;
is $obj, $client, 'got client in callback';
is $tx->res->code, 400, 'invalid listPetsByType';
is $tx->error->{message}, 'Invalid input', 'sync invalid message';
is $i, 0, 'invalid on client side';

note 'Promise testing';
my $p = $client->listPetsByType_p->then(sub { $tx = shift });
$tx = undef;
$p->wait;
is $tx->res->code, 400, 'invalid listPetsByType';
is $tx->error->{message}, 'Invalid input', 'sync invalid message';
is $i, 0, 'invalid on client side';

note 'call()';
$tx = $client->call('list pets', {page => 2});
is_deeply $tx->res->json, [{page => 2}], 'call(list pets)';

eval { $tx = $client->call('nope') };
like $@, qr{No such operationId.*client\.t}, 'call(nope)';

# this approach from https://metacpan.org/source/SRI/Mojolicious-7.59/t/mojo/promise.t and user_agent.t
note 'call_p()';
my $promise = $client->call_p('list pets', {page => 2});
my (@results, @errors);
$promise->then(sub { @results = @_ }, sub { @errors = @_ });
$promise->wait;
is_deeply $results[0]->res->json, [{page => 2}], 'call_p(list pets)';
is_deeply \@errors, [], 'promise not rejected';

note 'call_p() rejecting';
$promise = $client->call_p('list all pets', {page => 2});
(@results, @errors) = ();
$promise->then(sub { @results = @_ }, sub { @errors = @_ });
$promise->wait;
is_deeply \@results, [], 'call_p(list all pets) does not exist';
is_deeply \@errors, ['[OpenAPI::Client] No such operationId'], 'promise got rejected';

note 'boolean';
my $err;
$client->listPetsByType_p({type => 'cat', is_cool => true})->then(sub { $tx = shift }, sub { $err = shift })->wait;
is $tx->res->code, 200, 'accepted is_cool=true';
is $tx->req->url->query->to_string, 'is_cool=1', 'is_cool in query parameter';

done_testing;

__DATA__
@@ test.json
{
  "swagger": "2.0",
  "info": { "version": "0.8", "title": "Test client spec" },
  "schemes": [ "http" ],
  "host": "api.example.com:3000",
  "basePath": "/v1",
  "paths": {
    "x-whatever": [],
    "/pets": {
      "x-whatever": [],
      "parameters": [
        { "$ref": "#/parameters/name" }
      ],
      "get": {
        "operationId": "list pets",
        "parameters": [
          { "in": "query", "name": "page", "type": "integer" }
        ],
        "responses": {
          "200": {
            "description": "pets",
            "schema": { "type": "array" }
          }
        }
      },
      "post": {
        "x-whatever": [],
        "operationId": "addPet",
        "parameters": [
          { "in": "header", "name": "x-dummy", "type": "boolean" },
          { "in": "formData", "name": "age", "type": "integer" },
          { "in": "formData", "name": "type", "type": "string", "required": true }
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
        "operationId": "listPetsByType",
        "parameters": [
          { "in": "query", "name": "is_cool", "type": "boolean" },
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
