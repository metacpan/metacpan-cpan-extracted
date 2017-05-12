use lib "../lib/";
use Mojo::IRC::Server::Chinese;
my $server = Mojo::IRC::Server::Chinese->new(
    port        =>  6667,
    log_level   =>  "debug",
);
$server->run();
