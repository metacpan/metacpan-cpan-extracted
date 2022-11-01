use strict;
use warnings;
use Test::More tests => 17;
BEGIN { use_ok('SMS::Send::NANP::Twilio') };

my $ws = SMS::Send::NANP::Twilio->new(
                                      AccountSid          => 'myAccountSid',
                                      AuthToken           => 'myAuthToken',
                                      MessagingServiceSid => '',
                                      From                => 'myFrom',
                                     );

isa_ok($ws, 'SMS::Send::NANP::Twilio');
can_ok($ws, 'AccountSid');
can_ok($ws, 'AuthToken');
can_ok($ws, 'url');
can_ok($ws, 'From');
can_ok($ws, 'MessagingServiceSid');
can_ok($ws, 'StatusCallback');
can_ok($ws, 'ApplicationSid');
can_ok($ws, 'MaxPrice');
can_ok($ws, 'ProvideFeedback');
can_ok($ws, 'ValidityPeriod');
isa_ok($ws->uat, 'HTTP::Tiny');

is($ws->AccountSid, 'myAccountSid', 'AccountSid');
is($ws->AuthToken, 'myAuthToken', 'AuthToken');
is($ws->From, 'myFrom', 'From');
ok(!$ws->MessagingServiceSid, 'MessagingServiceSid');
