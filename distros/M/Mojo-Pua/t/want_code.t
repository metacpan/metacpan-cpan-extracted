#BEGIN { $ENV{MOJO_USERAGENT_DEBUG} = 1 }
use Mojolicious::Lite;
use Evo 'Test::More; Mojo::Pua want_code';

# setup
any '/200' => sub($c) { $c->render(text => 'ok') };
any '/404' => sub($c) { $c->res->body("Foo"); $c->rendered(404); };


use Mojo::Server::Daemon;
app->log->level("error");
my $server = Mojo::Server::Daemon->new(
  app    => app(),
  silent => 1,
  listen => ['http://127.0.0.1']
)->start;
my $port = $server->ioloop->acceptor($server->acceptors->[0])->port;

my $ua = Mojo::Pua->new();

my ($res, $err);

$ua->get("http://127.0.0.1:$port/200")->then(want_code 200)
  ->then(sub { $res = shift; })->finally(sub { Mojo::IOLoop->stop });
Mojo::IOLoop->start;
is $res->code, 200;

$ua->get("http://127.0.0.1:$port/test_404")->then(want_code 200)
  ->catch(sub { $err = shift; })->finally(sub { Mojo::IOLoop->stop });
Mojo::IOLoop->start;
like $err, qr/Wanted \[200\], got \[404\] Not Found.+$0/;

$ua->get("http://127.0.0.1:$port/test_404")->then(want_code 404)
  ->then(sub { $res = shift; })->finally(sub { Mojo::IOLoop->stop });
Mojo::IOLoop->start;
is $res->code, 404;

undef $err;
$ua->get("http://127.0.0.1:$port/200")->then(want_code 404)
  ->catch(sub { $err = shift; })->finally(sub { Mojo::IOLoop->stop });
Mojo::IOLoop->start;
like $err, qr/Wanted \[404\], got \[200\] OK.+$0/;

undef $err;
$ua->get("http://127.0.0.1:23423445/test_404")->then(want_code 200)
  ->catch(sub { $err = shift; })->finally(sub { Mojo::IOLoop->stop });
Mojo::IOLoop->start;
ok $err;

undef $err;
$ua->get("http://127.0.0.1:23423445/test_404")
  ->then(want_code 200, sub { $err = shift; })
  ->finally(sub { Mojo::IOLoop->stop });
Mojo::IOLoop->start;
ok $err;

done_testing;
