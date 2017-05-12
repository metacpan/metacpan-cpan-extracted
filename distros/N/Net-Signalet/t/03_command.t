use strict;
use warnings;
use lib 'lib';

use Test::More skip_all => 'Not working';
use Test::Requires qw(
    Test::SharedFork
    Capture::Tiny
);

use Net::Signalet::Client;
use Net::Signalet::Server;


if (my $pid = fork) {
    my $server = Net::Signalet::Server->new(
        saddr => "127.0.0.1",
        timeout => 0.5,
        reuse => 1,
    );

    $server->run(
        code => sub {
            while (1) {
            }
        },
    );

    $server->term_worker;
    $server->close;
}
else {
    my $client = Net::Signalet::Client->new(
        daddr => "127.0.0.1",
        saddr => "127.0.0.1",
        timeout => 0.5,
    );

    my $result = Capture::Tiny::capture_stdout {
        $client->run(
            command => "echo 'HEYHEY'",
        );
    };

    $client->term_worker;
    $client->close;
}

done_testing;
