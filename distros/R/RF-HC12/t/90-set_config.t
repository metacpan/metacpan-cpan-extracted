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

like $rf->baud(9600), qr/9600/, "baud set back to default ok";
like $rf->channel(1), qr/001/, "channel set back to default ok";
like $rf->mode(3), qr/FU3/, "transmit mode set back to default ok";
$rf->power(8);
like $rf->power, qr/20dBm/, "power set back to default ok";

my $defaults = $rf->config;

like $defaults, qr/B9600/, "all defaults in one call ok";
like $defaults, qr/RC001/, "all defaults in one call ok";
like $defaults, qr/20dBm/, "all defaults in one call ok";
like $defaults, qr/FU3/, "all defaults in one call ok";

print $rf->config;

done_testing();

