use strict;
use warnings;

use RF::HC12;
use Test::More;

if (! $ENV{UART_DEV}){
    plan skip_all => "UART_DEV env var not set";
}

my $dev = $ENV{UART_DEV};

my $rf = RF::HC12->new($dev);

is $rf->test, 'OK', "connectivity test ok";

if ($rf->test ne 'OK'){
    plan skip_all => "HC-12 CONN TEST FAILED... CAN'T CONTINUE";
}

like $rf->baud, qr/9600/, "baud is default ok";
like $rf->power, qr/20dBm/, "power is default ok";
like $rf->channel, qr/001/, "channel is default ok";
like $rf->mode, qr/FU3/, "transmit mode is default ok";

done_testing();

