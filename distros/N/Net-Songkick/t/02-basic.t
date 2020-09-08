use strict;
use warnings;
use Test::More;

use Net::Songkick;

my $dummy_api_key = 'dummy';

my $sk = Net::Songkick->new({ api_key => $dummy_api_key });

ok($sk, 'Got something');
isa_ok($sk, 'Net::Songkick');
is($sk->api_key, $dummy_api_key, 'Correct api key');
isa_ok($sk->ua, 'LWP::UserAgent');

done_testing;
