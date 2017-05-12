use strict;
use warnings;
use Test::More;
use FindBin;
use lib ($FindBin::RealBin);
use testlib::Master;
use Test::Requires {
    "Coro" => "0",
    "Corona::Server" => "0"
};
use Coro;
use Corona::Server;

testlib::Master::run_tests sub {
    my ($port, $app) = @_;
    async {
        my $corona = Corona::Server->new(
            host => "127.0.0.1",
            log_level => 0,
        );
        $corona->{app} = $app;
        $corona->run(port => $port);
    };
    cede;
};

done_testing;
