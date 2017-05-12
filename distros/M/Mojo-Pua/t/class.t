#BEGIN { $ENV{MOJO_USERAGENT_DEBUG} = 1 }
use Mojolicious::Lite;
use Evo 'Test::More; Mojo::Pua';

# setup
any '/200' =>
  sub($c) { $c->render(text => join ';', "working", $c->req->url); };

any '/200_post' =>
  sub($c) { $c->render(text => join ';', "working", $c->req->body); };

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

# shouldn't use callback
eval {
  $ua->get("http://127.0.0.1:$port", sub {fail})->then();
};
like $@, qr/Got callback.+$0/;

POST_FORM: {
  my $tx;
  $ua->post("http://127.0.0.1:$port/200_post", form => {foo => 33})
    ->then(sub { $tx = shift; })->finally(sub { Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
  is $tx->res->body, 'working;foo=33';
}

# promise get
GET: {
  my $tx;
  $ua->get("http://127.0.0.1:$port/200")->then(sub { $tx = shift; })
    ->finally(sub { Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
  is $tx->res->body, 'working;/200';
}

GET_FORM: {
  my $tx;
  $ua->get("http://127.0.0.1:$port/200", form => {foo => 33})
    ->then(sub { $tx = shift; })->finally(sub { Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
  is $tx->res->body, 'working;/200?foo=33';
}

NOT_EXCEPTION_404: {
  my $tx;
  $ua->get("http://127.0.0.1:$port/404")->then(sub { $tx = shift; })
    ->finally(sub { Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
  is $tx->error->{message}, 'Not Found';
}

EXCEPTION: {
  my $err;
  $ua->get("http://127.0.0.1:23423445/404")->catch(sub { $err = shift; })
    ->finally(sub { Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
  ok $err;
}

done_testing;
