use strict;
use warnings;
use OPCUA::Open62541 qw(:STATUSCODE :SESSIONSTATE :SECURECHANNELSTATE);
use IO::Socket::INET;
use Scalar::Util qw(looks_like_number);
use Time::HiRes qw(sleep);

use OPCUA::Open62541::Test::Server;
use OPCUA::Open62541::Test::Client;
use Test::More tests => 13;
use Test::Deep;
use Test::Exception;
use Test::NoWarnings;
use Test::LeakTrace;

my $server = OPCUA::Open62541::Test::Server->new();
$server->start();

# dont start server to trigger immediate callback in first run_iterate
# $server->run();

my $data;
{
    my $client = OPCUA::Open62541::Client->new();
    my $config = $client->getConfig();
    is($config->setDefault(), STATUSCODE_GOOD, "config set default");
    my $url = "opc.tcp://localhost:" . $server->port();

    $config->setStateCallback(sub { print "perl callback\n" });
    $config->setClientContext("foobar");
    is($client->connectAsync($url), STATUSCODE_GOOD, "connectAsync good");

    $data->{client} = $client;
}
sleep .1;

# different timing and open62541 version return various status codes
cmp_deeply($data->{client}->run_iterate(0), any(
    STATUSCODE_GOOD, STATUSCODE_BADDISCONNECT, STATUSCODE_BADCONNECTIONCLOSED),
    "client: run iterate");

is($data->{client}->disconnect(), STATUSCODE_GOOD, "client: disconnect");

# not run, so don't stop
# $server->stop();
