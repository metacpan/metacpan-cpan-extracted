#!/usr/bin/perl
#
# Copyright (C) 2011 by Mark Hindess

use warnings;
use strict;
$|=1;

use Test::More tests => 31;
BEGIN { use_ok('Net::MQTT::TopicStore'); }

my $topic_store;
ok($topic_store = Net::MQTT::TopicStore->new, 'topic store');
ok($topic_store->add('finance/stock/ibm/closingprice'),
   '... add finance/stock/ibm/closingprice');
check_matches($topic_store,
              'finance/stock/ibm/closingprice',
              'finance/stock/ibm/closingprice',
              'simple topic');

ok($topic_store = Net::MQTT::TopicStore->new('finance/stock/ibm/#'),
   'topic finance/stock/ibm/#');

foreach my $topic_name (qw!finance/stock/ibm
                           finance/stock/ibm/closingprice
                           finance/stock/ibm/currentprice!) {
  check_matches($topic_store, $topic_name, 'finance/stock/ibm/#',
                '... matches '.$topic_name);
}

foreach my $topic_name (qw!finance/stock/ibmblah finance/stock/ibmblah/1/2/3!) {
  check_matches($topic_store, $topic_name, '',
                '... doesn\'t matches '.$topic_name);
}

ok($topic_store = Net::MQTT::TopicStore->new('finance/stock/+'),
   'topic finance/stock/+');
foreach my $topic_name (qw!finance/stock/ibm finance/stock/xyz!) {
  check_matches($topic_store, $topic_name, 'finance/stock/+',
                '... matches '.$topic_name);
}
foreach my $topic_name (qw!finance/stock/ibm/closingprice!) {
  check_matches($topic_store, $topic_name, '',
                '... doesn\'t matches '.$topic_name);
}

ok($topic_store = Net::MQTT::TopicStore->new('finance/+/ibm'),
   'topic finance/+/ibm');
foreach my $topic_name (qw!finance/stock/ibm!) {
  check_matches($topic_store, $topic_name, 'finance/+/ibm',
                '... matches '.$topic_name);
}
foreach my $topic_name (qw!finance/stock/xyz finance/stock/ibm/closingprice!) {
  check_matches($topic_store, $topic_name, '',
                '... doesn\'t matches '.$topic_name);
}

ok($topic_store = Net::MQTT::TopicStore->new('+/+'), 'topic +/+');
ok($topic_store->add('/+'), '... add /+');
check_matches($topic_store, '/finance', '+/+, /+',
                '... matches /finance');

ok($topic_store = Net::MQTT::TopicStore->new('+'), 'topic +');
check_matches($topic_store, '/finance', '', '... doesn\'t match /finance');

ok($topic_store = Net::MQTT::TopicStore->new('$SYS/#'), 'topic $SYS/#');
check_matches($topic_store, '$SYS/test', '$SYS/#', '... matches $SYS/test');

ok($topic_store = Net::MQTT::TopicStore->new('/#'), 'topic /#');
check_matches($topic_store, '/test', '/#', '... matches /test');
check_matches($topic_store, 'test', '', '... doesn\'t match test');

ok($topic_store = Net::MQTT::TopicStore->new('#'), 'topic #');
check_matches($topic_store, '/test', '#', '... matches /test');
check_matches($topic_store, 'test', '#', '... matches test');

sub check_matches {
  my ($store, $topic, $expect, $desc) = @_;
  my $matches = $store->values($topic);
  is((join ', ', sort @{$matches||[]}), $expect, $desc);
}
