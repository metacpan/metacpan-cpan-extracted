use Mojo::Base -strict;
use Test::More;
use Mojo::UserAgent;
use Mojo::UserAgent::SecureServer;
use Mojolicious;

my $app = Mojolicious->new;
my $ua  = Mojo::UserAgent->new->insecure(1);
$ua->server->app($app);

my $server = Mojo::UserAgent::SecureServer->from_ua($ua);
isa_ok $server, 'Mojo::UserAgent::Server';
is $server->listen->to_string, 'https://127.0.0.1', 'default listen';
is $server->app, $app, 'app';
is $server->ioloop, $ua->server->{ioloop}, 'ioloop';

$ua->insecure(0);
is $server->from_ua($ua), $server, 'from_ua';
is $server->listen->to_string, 'https://127.0.0.1?verify=1', 'verify';

$server->from_ua($ua->ca('ca.pem')->cert('cert.pem')->key('key.pem'));
$server->from_ua($ua);
is $server->listen->to_string, 'https://127.0.0.1?ca=ca.pem&cert=cert.pem&key=key.pem&verify=1',
  'ca, cert, key, verify';

done_testing;
