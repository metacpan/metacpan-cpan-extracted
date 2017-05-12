#use IO::Socket::SSL 'debug4';
use IO::Socket::SSL;
use Mojo::IOLoop;
use Test::More;
use Test::Mojo;

# Make sure sockets are working
plan skip_all => 'working sockets required for this test!'
  unless Mojo::IOLoop::Server->generate_port;    # Test server

# Lite app
use Mojolicious::Lite;

# Silence
app->log->level('error');

plugin 'ssl_auth';

get '/' => sub {
  my $self = shift;

  return $self->render(text => 'ok')
    if $self->ssl_auth(
    sub { return 1 if shift->peer_certificate('cn') eq 'client' });

  $self->render(text => '', status => 401);
};

my $ioloop = Mojo::IOLoop->singleton;
my $daemon = Mojo::Server::Daemon->new(app => app, ioloop => $ioloop);
my $port   = Mojo::IOLoop::Server->generate_port;
$daemon->listen(
  [     "https://127.0.0.1:$port"
      . '?cert=t/certs/server.crt'
      . '&key=t/certs/server.key'
      . '&ca=t/certs/ca.crt'
  ]
)->start;

# Success - expected common name
my $ua = Mojo::UserAgent->new(
  ioloop => $ioloop,
  cert   => 't/certs/client.crt',
  key    => 't/certs/client.key'
);
my $t = Test::Mojo->new;
$t->ua($ua);
$t->get_ok("https://127.0.0.1:$port")->status_is(200)->content_is('ok');

# Fail - different common name
$t->ua(
  Mojo::UserAgent->new(
    ioloop => $ioloop,
    cert   => 't/certs/anotherclient.crt',
    key    => 't/certs/anotherclient.key'
  )
);
$t->get_ok("https://127.0.0.1:$port")->status_is(401)->content_is('');

done_testing;
