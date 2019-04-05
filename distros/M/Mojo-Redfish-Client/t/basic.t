use Mojo::Base -strict;

use Mojolicious;
use Mojo::Redfish::Client;

use Test::More;

my $mock = Mojolicious->new;
$mock->log->level('fatal');
my ($user, $pass, $token);
{
  my $r = $mock->routes;
  $r = $r->under(sub{
    my $c = shift;
    my $url = $c->req->url->to_abs;
    $user   = $url->username;
    $pass   = $url->password;
    $token  = $c->req->headers->header('X-Auth-Token');
    return 1;
  });
  $r->get('/redfish/v1' => {json => {
    '@odata.id' => '/redfish/v1',
    Systems => { '@odata.id' => '/redfish/v1/Systems' }
  }});
  $r->get('/redfish/v1/Systems' => {json => {
    '@odata.id' => '/redfish/v1/Systems',
    Members => [
      {'@odata.id' => '/redfish/v1/Systems/0'},
      {'@odata.id' => '/redfish/v1/Systems/1'},
    ]
  }});
  $r->get('/redfish/v1/Systems/:number' => sub {
    my $c = shift;
    my $num = $c->stash('number');
    $c->render(json => {
      '@odata.id' => "/redfish/v1/Systems/$num",
      data => "some data: $num",
    });
  });
}

my $client = Mojo::Redfish::Client->new(
  ssl => undef,
  username => 'myuser',
  password => 'mypass',
);
$client->ua->server->app($mock);

my $root = $client->root;
isa_ok $root, 'Mojo::Redfish::Client::Result', 'got a result object';
is $user, 'myuser', 'got expected username';
is $pass, 'mypass', 'got expected password';
ok !$token, 'no token';
is $root->value('/@odata.id'), '/redfish/v1', 'got expected result';
is $root->value('/Systems/@odata.id'), '/redfish/v1/Systems', 'got expected result';

$client->token('mytoken');

my $systems = $root->get('/Systems');
isa_ok $systems, 'Mojo::Redfish::Client::Result', 'got a result object';
ok !$user, 'no username';
ok !$pass, 'no password';
is $token, 'mytoken', 'token takes priority';

is_deeply $systems->value('/Members')->to_array, [
  {'@odata.id' => '/redfish/v1/Systems/0'},
  {'@odata.id' => '/redfish/v1/Systems/1'},
], 'value does not expand arrays';

my $members = $systems->get('/Members');
isa_ok $members, 'Mojo::Collection', 'got a collection';
is $members->[0]->value('/@odata.id'), '/redfish/v1/Systems/0', 'got expected result';
is $members->[0]->value('/data'), 'some data: 0', 'got expected result';
is $members->[1]->value('/@odata.id'), '/redfish/v1/Systems/1', 'got expected result';
is $members->[1]->value('/data'), 'some data: 1', 'got expected result';

done_testing;

