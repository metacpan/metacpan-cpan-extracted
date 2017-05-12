#!perl -T

use strict;
use warnings;
use lib ();
use Test::More;
use Regexp::NumRange qw/ rx_max rx_range /;

{
    my $rx = rx_max(255);

    like '100',   qr/^$rx$/, '100 is less than 255';
    unlike '256', qr/^$rx$/, '256 is greater tha 255';
}

{
    my $string = rx_range( 256, 1024 );
    my $rx = qr/^$string$/;

    ok "10" !~ $rx;
    ok "300" =~ $rx;
    ok "2000" !~ $rx;
}

{
    # create a string matching numbers between 0 and 1024
    my $rx_string = rx_max(1024);
    is $rx_string, '(102[0-4]|10[0-1][0-9]|0?[0-9]{1,3})';
}

done_testing();

