use strict;
use utf8;
use warnings;

use Test::More;
use Test::Exception;

use SMS::Send;

my ($sms, $api_key, $api_secret) = ('', 'foo', 'bar');

$sms = SMS::Send->new('Mocean', _api_key => $api_key, _api_secret => $api_secret);
is(ref $sms, 'SMS::Send', 'Expect module match.');

dies_ok {
    $sms = SMS::Send->new('Mocean');
} 'Expect exception on missing API key and secret.';

dies_ok {
    $sms = SMS::Send->new('Mocean', _api_key => $api_key);
} 'Expect exception on missing API key.';

dies_ok {
    $sms = SMS::Send->new('Mocean', _api_secret => $api_secret);
} 'Expect exception on missing API secret.';

done_testing;
