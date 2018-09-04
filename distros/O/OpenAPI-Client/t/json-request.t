use Mojo::Base -strict;
use OpenAPI::Client;
use Test::More;

use Mojolicious::Lite;
app->log->level('error') unless $ENV{HARNESS_IS_VERBOSE};

post '/user' => sub {
  my $c = shift->openapi->valid_input or return;
  $c->render(openapi => $c->validation->output);
  },
  'addUser';

plugin OpenAPI => {url => 'data://main/test.json'};

my $client = OpenAPI::Client->new('data://main/test.json', app => app);
my $tx = $client->addUser({user => {username => 'superwoman'}});
is $tx->res->json->{user}{username}, 'superwoman', 'echo back username (b)';
like $tx->req->headers->header('Content-Type'), qr{application/json}, 'application/json';

undef $tx;
my $p = $client->addUser_p({user => {username => 'supergirl'}})->then(sub { $tx = shift });
$p->wait;
is $tx->res->json->{user}{username}, 'supergirl', 'echo back username (p)';

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
    "/user": {
      "post": {
        "operationId": "addUser",
        "parameters": [
          {"in":"body","name":"user","schema":{}}
        ],
        "responses": {
          "200": {
            "description": "user",
            "schema": { "type": "object" }
          }
        }
      }
    }
  }
}
