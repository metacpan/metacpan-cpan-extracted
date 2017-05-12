use strict;
use warnings;
use Test::More;
use Test::Requires;
use Plack::Handler::FCGI;
use Test::TCP;
use LWP::UserAgent;
use Plack::Test::Suite;
use Plack::App::FCGIDispatcher;

my $http_port ||= empty_port();
my $fcgi_port ||= empty_port($http_port);

my $fcgi_app = Plack::App::FCGIDispatcher->new({ port => $fcgi_port })->to_app;

test_tcp(
    server => sub {
        my $server = Plack::Loader->load('Standalone', host => '127.0.0.1', port => $http_port);
        $server->run($fcgi_app);
    },
    client => sub {
        Plack::Test::Suite->run_server_tests(\&run_server, $fcgi_port, $http_port);
    },
    port => $http_port,
);

done_testing;

sub run_server {
    my($port, $app) = @_;

    $| = 0; # Test::Builder autoflushes this. reset!

    my $server = Plack::Handler::FCGI->new(
        host        => '127.0.0.1',
        port        => $port,
        manager     => '',
        keep_stderr => 1,
    );
    $server->run($app);
}


