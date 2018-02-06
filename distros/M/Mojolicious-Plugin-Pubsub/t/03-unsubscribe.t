use Mojo::IOLoop;
use Mojo::IOLoop::Server;
use Mojolicious::Lite;
use Test::More;
use File::Temp 'tempdir';

my $port = Mojo::IOLoop::Server->generate_port();
app->home(Mojo::Home->new(tempdir( CLEANUP => 1 )));

my $msg;
my $msg2;

# I know this will leak, but this is just a single test
my $subscriber; $subscriber = sub {
  $msg = shift;
  app->unsubscribe($subscriber);
  app->subscribe(sub { $msg2 = shift; Mojo::IOLoop->stop(); });
  app->publish('message');
};

plugin Pubsub => { cb => $subscriber };

app->log->level('warn');
app->publish('not message');
app->start('daemon', '-l', "http://127.0.0.1:$port");


is ($msg, 'not message', "Unsubscribing works fine.");
is ($msg2, 'message', "Subscribing works fine.");

done_testing;

unlink app->home->child(app->moniker . '.pubsub');
