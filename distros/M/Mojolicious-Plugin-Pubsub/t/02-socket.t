use Mojo::IOLoop;
use Mojo::IOLoop::Server;
use Mojolicious::Lite;
use Test::More;
use File::Temp 'tempdir';

my $port = Mojo::IOLoop::Server->generate_port();

my $msg;
my $socket = tempdir( CLEANUP => 1 ) . "/pubsub.sock";
plugin Pubsub => { cb => sub { $msg = -e $socket; Mojo::IOLoop->stop; }, socket => $socket };

app->log->level('warn');
app->publish('message');
app->start('daemon', '-l', "http://127.0.0.1:$port");



is ($msg, 1, "Socket option works fine.");

done_testing;
