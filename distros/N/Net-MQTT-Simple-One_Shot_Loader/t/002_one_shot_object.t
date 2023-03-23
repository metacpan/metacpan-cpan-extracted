use strict;
use warnings;
use Time::HiRes qw{time};
use Test::More tests => 2 + 12;
require_ok('Net::MQTT::Simple::One_Shot_Loader');
use_ok('Net::MQTT::Simple');

my $host = $ENV{'MQTT_HOST'};

SKIP: {
  skip '$ENV{"MQTT_HOST"} not set', 12 unless $host;
  my $mqtt = Net::MQTT::Simple->new($host);
  isa_ok($mqtt, 'Net::MQTT::Simple');
  can_ok($mqtt, 'one_shot');
  {
    my $timeout  = 0.5;
    my $timer    = time();
    my $response = $mqtt->one_shot(my_topic => my_topic => my_message => $timeout); #loop back
    $timer       = time() - $timer;
    ok($timer < $timeout, 'timer is faster than timeout');
    isa_ok($response, 'Net::MQTT::Simple::One_Shot_Loader::Response');
    ok(!$response->error, 'one_shot error code');
    is($response->message, 'my_message', 'one_shot message');
    is($response->topic, 'my_topic', 'one_shot topic');
  }
  {
    my $timeout  = 0.5;
    my $timer    = time();
    my $response = $mqtt->one_shot(my_timeout => my_topic => my_message => $timeout); #loop back
    $timer       = time() - $timer;
    ok($timer < $timeout * 1.5, 'timeout is less than 150% of timeout');
    isa_ok($response, 'Net::MQTT::Simple::One_Shot_Loader::Response');
    ok($response->error, 'one_shot error code');
    is($response->message, '', 'one_shot message');
    is($response->topic, 'my_timeout', 'one_shot topic');
  }
}
