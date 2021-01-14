use Mojo::Base -strict;
use Test::Mojo;
use Test::More;
use Mojo::UserAgent::SecureServer;
use Mojolicious;

plan skip_all => 'IO::Socket::SSL is required'    unless eval 'use IO::Socket::SSL 2;1';
plan skip_all => 'ca-chain.cert.pem not readable' unless -r 't/pki/certs/ca-chain.cert.pem';

my $app = Mojolicious->new;
$app->routes->get(
  '/' => sub {
    my $c      = shift;
    my $handle = Mojo::IOLoop->stream($c->tx->connection)->handle;
    $c->render(json => {cn => $handle->peer_certificate('cn')});
  }
);

my $t = Test::Mojo->new($app);
$t->ua->insecure(0);
$t->ua->ca('t/pki/certs/ca-chain.cert.pem')->cert('t/pki/mojo.example.com.cert.pem')
  ->key('t/pki/mojo.example.com.key.pem');
$t->ua->server(Mojo::UserAgent::SecureServer->from_ua($t->ua));
$t->get_ok('/')->status_is(200)->json_is('/cn', 'mojo.example.com');

done_testing;
