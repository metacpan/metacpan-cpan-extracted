use strict;
use warnings;
use Net::Google::Analytics::MeasurementProtocol;
use Test::More;

diag 'these tests require a working Internet connection.';
if (!$ENV{ONLINE_TESTS}) {
    plan skip_all => 'Online tests disabled. Please set ONLINE_TESTS=1 in the environment';
    exit;
}
plan tests => 4;

ok my $ga = Net::Google::Analytics::MeasurementProtocol->new(
  api_secret     => 123,
  measurement_id => 456,
  debug          => 1
), 'able to instantiate class';

ok my $res = $ga->send('_badEventName', {}), 'send() called successfully';

is_deeply($res, {
  validationMessages => [
    {
      description => "Event at index: [0] has invalid name [_badEventName]. Names must start with an alphabetic character.",
      fieldPath => "events",
      validationCode => "NAME_INVALID"
    }
  ]
}, 'bad event name response');

$res = $ga->send_multiple([
  { refund => { currency => 'BRL', value => 3.14, transaction_id => '123-456' } },
  { level_up => { level => 99, character => 'Mario' } },
  { my_custom_event => { whatever => 42 } },
]);

is_deeply($res, { validationMessages => [] }, 'multiple events without error');
