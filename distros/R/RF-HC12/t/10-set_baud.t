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

for ($rf->_baud_rates){
    $rf->baud($_);
    is $rf->baud, "OK+B$_", "baud rate set to $_ ok";
}

for (qw(1 a A ! 1111 9999)){
    is
        eval { $rf->baud($_); 1; },
        undef,
        "baud croaks if sent in $_";

    like $@, qr/baud rate '$_' is invalid/, "...and error is sane";
}

is $rf->baud(9600), 'OK+B9600', "baud set back to default ok";

done_testing();
