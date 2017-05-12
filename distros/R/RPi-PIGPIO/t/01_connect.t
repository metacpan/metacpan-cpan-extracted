#!perl

use Test::More;

use strict;
use warnings;

use RPi::PIGPIO;

if ( ! $ENV{PIPGIO_IP} ) {
      plan skip_all => 'Define $ENV{PIPGIO_IP} to enable this test';
}

my $pi = RPi::PIGPIO->connect('127.0.0.1','8888');

is(ref($pi),'RPi::PIGPIO','connected');

done_testing();
