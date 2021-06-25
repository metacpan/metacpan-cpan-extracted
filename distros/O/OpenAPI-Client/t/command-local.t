use Mojo::Base -strict;
use Mojo::File 'path';
use Mojolicious::Command::openapi;
use Mojolicious;
use Test::More;

$ENV{MOJO_LOG_LEVEL} //= 'warn';

my @said;
Mojo::Util::monkey_patch('Mojolicious::Command::openapi', _say  => sub { push @said, @_ });
Mojo::Util::monkey_patch('Mojolicious::Command::openapi', _warn => sub { push @said, @_ });

eval {
  my $app = Mojolicious->new;
  $app->routes->post(
    '/pets' => sub {
      my $c   = shift;
      my $res = $c->req->json;
      $res->{key} = $c->param('key');
      $c->render(openapi => $res);
    }
  )->name('addPet');
  $app->plugin('OpenAPI', {url => 'data://main/test.json'});

  my $cmd = Mojolicious::Command::openapi->new(app => $app);
  $cmd->run('/v1');
  like "@said", qr{addPet}, 'validated spec from local app';

  @said = ();
  $cmd->run('/v1', 'addPet', -p => "key=abc", -c => '{"type":"dog"}');
  like "@said", qr{"key":"abc"},  'addPet with key';
  like "@said", qr{"type":"dog"}, 'addPet with type';

  @said = ();
  my $characters = qq(\x{88c5}\x{903c}\x{4e2d});
  my $encoded    = Mojo::Util::encode("UTF-8", $characters);
  $cmd->run('/v1', 'addPet', -p => "key=abc", -c => qq[{"type":"$encoded"}]);
  like "@said", qr{"key":"abc"},          'addPet with key';
  like "@said", qr{"type":"$characters"}, 'addPet with unicode';
} or do {

  # Getting "Service Unavailable" from some of the cpantesters
  plan skip_all => $@;
};

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
    "/pets": {
      "post": {
        "operationId": "addPet",
        "parameters": [
          { "in": "query", "name": "key", "type": "string" },
          {
            "in": "body",
            "name": "body",
            "required": true,
            "schema": {
              "type": "object",
              "properties": {
                "type": { "type": "string", "description": "Type" }
              }
            }
          }
        ],
        "responses": {
          "200": {
            "description": "pet response",
            "schema": { "type": "object" }
          }
        }
      }
    }
  }
}
