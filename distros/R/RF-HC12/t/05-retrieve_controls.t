use strict;
use warnings;
use feature 'say';

use RF::HC12;
use Test::More;

if (! $ENV{UART_DEV}){
    plan skip_all => "UART_DEV env var not set";
}

my $dev = $ENV{UART_DEV};

my $rf = RF::HC12->new($dev);

is $rf->test, 'OK', "connectivity test ok";
is $rf->baud, 'OK+B9600', "default baud rate (9600) ok";
is $rf->channel, 'OK+RC001', "default channel (001) is ok";
is $rf->mode, 'OK+FU3', "default functional mode (3) is ok";
is $rf->power, 'OK+RP:+20dBm', "default transmit power (+20db) ok";
is $rf->version, 'www.hc01.com  HC-12_V2.4', "version returns ok";

done_testing();

