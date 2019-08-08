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

for (-1, 128){
    is eval {$rf->channel($_); 1;}, undef, "$_ croaks if trying to use it as channel";
}

for (1..127){
    $rf->channel($_);
    like $rf->channel, qr/$_$/, "channel set to $_ ok";
}

$rf->channel(1);
like $rf->channel, qr/001$/, "channel set to default '001' ok";

done_testing();
