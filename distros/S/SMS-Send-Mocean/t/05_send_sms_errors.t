use strict;
use utf8;
use warnings;

use Test::More;
use Test::Exception;

use SMS::Send;

BEGIN {
    unless ($ENV{MOCEAN_API_KEY}
            && $ENV{MOCEAN_API_SECRET}
            && $ENV{MOCEAN_FROM}
            && $ENV{MOCEAN_TO}) {
        plan skip_all => '$ENV for MOCEAN_XXX not set, skipping live tests'
    }
}

my ($got, $gateway) = ('', '');

$gateway = SMS::Send->new(
    'Mocean',
    _api_key => $ENV{MOCEAN_API_KEY} . 'xxx',
    _api_secret => $ENV{MOCEAN_API_SECRET} . 'xxx',
);


dies_ok {
    $got = $gateway->send_sms(
        text => 'Hello world',
        to => $ENV{MOCEAN_TO},
        _from => $ENV{MOCEAN_FROM},
    );
} 'Expect die on incorrect API authentication.';

done_testing;
