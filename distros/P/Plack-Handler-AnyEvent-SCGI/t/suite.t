use strict;
use warnings;
use Test::More;
use Plack;
use Plack::Handler::AnyEvent::SCGI;
use Plack::Test::Suite;
use t::SCGIUtils;

my $lighty_port;
my $scgi_port;

test_lighty_external(
   sub {
       ($lighty_port, $scgi_port) = @_;
       Plack::Test::Suite->run_server_tests(\&run_server, $scgi_port, $lighty_port);
       done_testing();
    }
);

sub run_server {
    my($port, $app) = @_;

    $| = 0; # Test::Builder autoflushes this. reset!

    my $server = Plack::Handler::AnyEvent::SCGI->new(
        host        => '127.0.0.1',
        port        => $port,
    );
    $server->run($app);
}


