use strict;
use utf8;
use warnings;

use Test::More;

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
    _api_key => $ENV{MOCEAN_API_KEY},
    _api_secret => $ENV{MOCEAN_API_SECRET},
);

$got = $gateway->send_sms(
    text => 'Hello world',
    to => $ENV{MOCEAN_TO},
    _from => $ENV{MOCEAN_FROM},
);

is($got->{status}, 0, 'Expect SMS sent. OK and no error encountered.');
is(q|+| . $got->{receiver}, $ENV{MOCEAN_TO}, 'Expect receiver mobile number match.');

done_testing;
