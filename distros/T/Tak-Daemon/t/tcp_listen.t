use strictures 1;
use Test::More;
use Tak::Daemon::ListenerService;
use Tak::Client;
use Tak::Router;
use Tak::ConnectorService;

use Log::Contextual ();
use Log::Contextual::SimpleLogger ();

Log::Contextual::set_logger(
  Log::Contextual::SimpleLogger->new({
    levels_upto => 'info',
    coderef => sub { print STDERR @_; }
  })
);

use lib 't/lib';
use PortFinder;

my $port = empty_port;

my $l_cl = Tak::Client->new(
  service => Tak::Daemon::ListenerService->new(
    router => Tak::Client->new(service => Tak::Router->new),
    listen_on => { ip => '127.0.0.1', port => $port },
  )
);

$l_cl->do('start');

#Tak->loop_until(0);

my $conn_cl = Tak::Client->new(
  service => Tak::ConnectorService->new
);

my $cl = $conn_cl->curry(
  connection => $conn_cl->do(create => "127.0.0.1:${port}")
    => remote => 'meta'
);

cmp_ok($cl->do('pid'), '==', $$, "PID returned from TCP ok");

done_testing;
