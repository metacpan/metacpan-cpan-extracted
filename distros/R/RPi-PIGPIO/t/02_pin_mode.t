#!perl

use Test::More;

use strict;
use warnings;

use RPi::PIGPIO;

if ( ! $ENV{PIPGIO_IP} ) {
      plan skip_all => 'Define $ENV{PIPGIO_IP} to enable this test';
}

my $pi = RPi::PIGPIO->connect($ENV{PIPGIO_IP},$ENV{PIPGIO_PORT} // '8888');

is(ref($pi),'RPi::PIGPIO','connected');

foreach (0..40) {
  ok($pi->get_mode($_) >= 0, "We can detect $_ mode");
}

done_testing();
