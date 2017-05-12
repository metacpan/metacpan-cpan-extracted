use strict;
use warnings;
use Test::More;
use Plack;
use Plack::Handler::AnyEvent::FCGI;
use Plack::Test::Suite;
use t::FCGIUtils;

my $lighty_port;
my $fcgi_port;

test_lighty_external(
   sub {
       ($lighty_port, $fcgi_port) = @_;
       Plack::Test::Suite->run_server_tests(\&run_server, $fcgi_port, $lighty_port);
       done_testing();
    }
);

sub run_server {
    my($port, $app) = @_;

    $| = 0; # Test::Builder autoflushes this. reset!

    my $server = Plack::Handler::AnyEvent::FCGI->new(
        host       => '127.0.0.1',
        listen     => [ ":$port" ],
    );
    $server->run($app);
}


