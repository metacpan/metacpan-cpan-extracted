#!perl

use strict;
use warnings;
use Test::Most tests => 3002;

use_ok('OAuthomatic::Caller');

my $prev_nonce = OAuthomatic::Caller::_nonce();
ok( $prev_nonce > 0, "First nonce makes sense" );

foreach my $idx (1..1000) {
    my $nonce = OAuthomatic::Caller::_nonce();
    isnt($nonce, $prev_nonce, "nonce changed ($nonce)");
    is(($nonce - $prev_nonce) % 2**6, 1, "nonce final bits incremented by one");
    isnt($nonce - $prev_nonce, 1, "random part is not fixed");
    # print STDERR $nonce, "\n";
    $prev_nonce = $nonce;
}

done_testing;
