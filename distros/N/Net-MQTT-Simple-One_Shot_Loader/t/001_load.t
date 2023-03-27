#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 4;
BEGIN { require_ok('Net::MQTT::Simple::One_Shot_Loader') };

my $host = 'mqtt'; #we are not actually connecting

{
  require_ok('Net::MQTT::Simple');
  my $mqtt = Net::MQTT::Simple->new($host);
  can_ok($mqtt, 'one_shot');
}

{
  local $@;
  my $eval  = eval{require Net::MQTT::Simple::SSL};
  my $error = $@;

  SKIP: {
    skip 'Net::MQTT::Simple::SSL not installed', 1 if $error;
    my $mqtt = Net::MQTT::Simple::SSL->new($host);
    can_ok($mqtt, 'one_shot');
  }
}
