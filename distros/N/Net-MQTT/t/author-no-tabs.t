
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

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
    'lib/Net/MQTT/TopicStore.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-message.t',
    't/01-topic.t',
    't/02-messages.t',
    't/03-errors.t',
    't/author-critic.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-no404s.t',
    't/author-pod-syntax.t',
    't/msg/01-connect.txt',
    't/msg/02-connack.txt',
    't/msg/03-publish.txt',
    't/msg/04-puback.txt',
    't/msg/05-pubrec.txt',
    't/msg/06-pubrel.txt',
    't/msg/07-pubcomp.txt',
    't/msg/08-subscribe.txt',
    't/msg/09-suback.txt',
    't/msg/10-unsubscribe.txt',
    't/msg/11-unsuback.txt',
    't/msg/12-pingreq.txt',
    't/msg/13-pingresp.txt',
    't/msg/14-disconnect.txt',
    't/msg/15-connect-auth.txt',
    't/msg/16-publish-qos-level-2.txt',
    't/msg/17-connack-with-error.txt',
    't/msg/18-connect-will.txt',
    't/msg/19-pingreq-with-payload.txt',
    't/msg/20-pingresp-with-payload.txt',
    't/release-common_spelling.t',
    't/release-kwalitee.t',
    't/release-pod-linkcheck.t'
);

notabs_ok($_) foreach @files;
done_testing;
