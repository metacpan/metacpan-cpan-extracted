
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'bin/net-mqtt-pub',
    'bin/net-mqtt-sub',
    'bin/net-mqtt-trace',
    'lib/Net/MQTT.pod',
    'lib/Net/MQTT/Constants.pm',
    'lib/Net/MQTT/Message.pm',
    'lib/Net/MQTT/Message/ConnAck.pm',
    'lib/Net/MQTT/Message/Connect.pm',
    'lib/Net/MQTT/Message/Disconnect.pm',
    'lib/Net/MQTT/Message/JustMessageId.pm',
    'lib/Net/MQTT/Message/PingReq.pm',
    'lib/Net/MQTT/Message/PingResp.pm',
    'lib/Net/MQTT/Message/PubAck.pm',
    'lib/Net/MQTT/Message/PubComp.pm',
    'lib/Net/MQTT/Message/PubRec.pm',
    'lib/Net/MQTT/Message/PubRel.pm',
    'lib/Net/MQTT/Message/Publish.pm',
    'lib/Net/MQTT/Message/SubAck.pm',
    'lib/Net/MQTT/Message/Subscribe.pm',
    'lib/Net/MQTT/Message/UnsubAck.pm',
    'lib/Net/MQTT/Message/Unsubscribe.pm',
    'lib/Net/MQTT/TopicStore.pm'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
