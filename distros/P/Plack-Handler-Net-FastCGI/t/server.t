use strict;
use warnings;
use Test::More;
use Plack;
use Plack::Handler::Net::FastCGI;
use Plack::Test::Suite;
use t::FCGIUtils;

test_lighty_external(
    sub {
        my ($lighty_port, $fcgi_port) = @_;
        Plack::Test::Suite->run_server_tests(\&server_cb, $fcgi_port, $lighty_port);
    }
);

done_testing();

sub server_cb {
    my($port, $app) = @_;

    $| = 0; # Test::Builder autoflushes this. reset!

    my $server = Plack::Handler::Net::FastCGI->new(
        host => '127.0.0.1',
        port => $port,
    )->run($app);
}


