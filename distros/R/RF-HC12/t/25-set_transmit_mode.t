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

for (-1, 4){
    is eval {$rf->mode($_); 1;}, undef, "$_ croaks if trying to use it as mode";
}

for (1..3){
    $rf->mode($_);
    like $rf->mode, qr/$_$/, "mode set to $_ ok";
}

$rf->mode(3);
like $rf->mode, qr/3$/, "mode set to default 'FU3' ok";

done_testing();
