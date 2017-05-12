use strict;
use warnings;
use lib 'lib';

use Test::More tests => 2;
use Test::Requires qw(
    Test::SharedFork
);

use Net::Signalet::Client;
use Net::Signalet::Server;


if (my $pid = fork) {
    my $server = Net::Signalet::Server->new(
        saddr => "127.0.0.1",
        timeout => 0.5,
        reuse => 1,
    );
    $server->send("HEYHEY");
    $server->close;
    waitpid($pid, 0);
}
else {
    my $client = Net::Signalet::Client->new(
        daddr => "127.0.0.1",
        saddr => "127.0.0.1",
        timeout => 0.5,
    );
    my $message = $client->recv;
    if (ok $message) {
        is $message, "HEYHEY";
    }
    $client->close;
}

