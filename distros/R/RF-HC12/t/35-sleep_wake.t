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

is $rf->sleep, 'OK+SLEEP', "device is sleeping";

sleep 1;

is $rf->wake, 'OK', "device is awake again";

my $defaults = $rf->config;

like $defaults, qr/B9600/, "all defaults in one call ok";
like $defaults, qr/RC001/, "all defaults in one call ok";
like $defaults, qr/20dBm/, "all defaults in one call ok";
like $defaults, qr/FU3/, "all defaults in one call ok";

done_testing();

