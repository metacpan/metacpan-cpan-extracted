use strict;
use warnings;
use Test::More;

use Net::Zendesk;
pass 'Net::Zendesk loaded successfully';

ok my $zen = Net::Zendesk->new(
    domain => 'obscura.zendesk.com',
    email  => 'whatever@example.com',
    token  => 'mytoken',
), 'Net::Zendesk object creation';

can_ok $zen, qw(create_ticket search make_request);

done_testing;
