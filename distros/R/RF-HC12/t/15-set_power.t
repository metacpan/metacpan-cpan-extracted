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

my $power_rates = {
    1   => -1,
    2   => 2,
    3   => 5,
    4   => 8,
    5   => 11,
    6   => 14,
    7   => 17,
    8   => 20
};

for (keys %$power_rates){
    $rf->power($_);
    if ($_ == 1){
        like $rf->power, qr/-01dBm/, "DB ok for power $_";

    }
    else {
        like $rf->power, qr/$power_rates->{$_}dBm/, "DB ok for power $_";
    }
}

$rf->power(8);
like $rf->power, qr/20dBm/, "back to default +20dBm";

done_testing();
