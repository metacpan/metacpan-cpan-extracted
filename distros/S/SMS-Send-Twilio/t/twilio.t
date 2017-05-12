use strict;
use warnings;

use Test::More;
use SMS::Send;

my $sender;

eval { $sender = SMS::Send->new('Twilio'); };

ok(!$sender, 'requires _accounsid');

$sender = SMS::Send->new('Twilio',
  _accountsid => 'ACb657bdcb16f06893fd127e099c070eca',
  _authtoken  => 'b857f7afe254fa86c689648447e04cff',
  _from       => '+15005550006',
);

isa_ok($sender, 'SMS::Send', 'Created SMS::Send object');

done_testing;
