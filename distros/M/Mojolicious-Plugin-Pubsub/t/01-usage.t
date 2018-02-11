use Mojo::IOLoop;
use Mojo::IOLoop::Server;
use Mojolicious::Lite;
use Test::More;
use File::Temp 'tempdir';

my $port = Mojo::IOLoop::Server->generate_port();
app->home(Mojo::Home->new(tempdir( CLEANUP => 1 )));

my $msg;
plugin Pubsub => { cb => sub { $msg = shift; Mojo::IOLoop->stop; } };

app->log->level('warn');
app->pubsub->publish('message');
app->start('daemon', '-l', "http://127.0.0.1:$port");



is ($msg, 'message', "Pubsub works fine.");

done_testing;

unlink app->home->child(app->moniker . '.pubsub');
