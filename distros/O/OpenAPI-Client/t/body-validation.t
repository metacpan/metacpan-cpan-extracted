use Mojo::Base -strict;
use OpenAPI::Client;
use Test::More;
use Mojo::JSON 'true';

use Mojolicious::Lite;
app->log->level('error') unless $ENV{HARNESS_IS_VERBOSE};

my $i = 0;
post '/user/login' => sub {
  $i++;
  my $c = shift->openapi->valid_input or return;
  return $c->render(openapi => $c->req->json);
  },
  'loginUser';

plugin OpenAPI => {url => 'data://main/test.json'};

my $client = OpenAPI::Client->new('data://main/test.json', app => app);
my ($tx, $req);

$client->once(after_build_tx => sub { $req = pop->req });

$tx = $client->loginUser;
is $tx->req, $req, 'after_build_tx emitted tx';
is $tx->res->code, 400, 'invalid loginUser' or diag explain($tx->res->json);
is $tx->error->{message}, 'Invalid input', 'invalid message';

$tx = $client->loginUser({body => {email => 'superman@example.com', password => 's3cret'}});
is $tx->res->code, 200, 'valid loginUser' or diag explain($tx->res->json);
is $tx->res->json->{email}, 'superman@example.com', 'valid return';

$tx = $client->loginUser({body => {password => 's3cret'}});
is $tx->res->code, 400, 'missing email' or diag explain($tx->res->json);
is $tx->error->{message}, 'Invalid input', 'invalid message';

$client->once(after_build_tx => sub { pop->req->headers->header('X-Secret' => 'supersecret') });
$tx = $client->loginUser;
is $tx->req->env->{operationId}, 'loginUser', 'got operationId in env';
is $tx->req->headers->header('X-Secret'), 'supersecret', 'modified request';

is $i, 1, 'only sent data to server once';

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
    "/user/login": {
      "post": {
        "tags": [ "user" ],
        "summary": "Log in a user based on email and password.",
        "operationId": "loginUser",
        "parameters": [
          {
            "name": "body",
            "in": "body",
            "required": true,
            "schema": {
              "type": "object",
              "required": ["email", "password"],
              "properties": {
                "email": { "type": "string", "format": "email", "description": "User email" },
                "password": { "type": "string", "description": "User password" }
              }
            }
          }
        ],
        "responses": {
          "200": {
            "description": "User profile.",
            "schema": { "type": "object" }
          }
        }
      }
    }
  }
}
