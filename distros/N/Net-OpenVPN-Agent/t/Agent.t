use warnings;
use strict;
use HTTP::CookieJar;
use Test::Most;

bail_on_fail;

BEGIN{do {plan skip_all => 'tests not run on install as HMA VPN account is needed.'}};

BEGIN{use_ok('Net::OpenVPN::Agent', 'load module')}
ok(my $ua = Net::OpenVPN::Agent->new, 'construct new useragent');
ok($ua->_get_ua_string, 'get_ua_string method');
SKIP:{
    skip 'Not root user', 1 if $< and ! -e 'agent.conf';  
    ok($ua->get_page('http://perltricks.com'), 'get_page method');
}
$ua->{request_limit} = 1;
ok($ua->_decrement_request_limit, 'decrement_request_limit method');
ok(!$ua->_decrement_request_limit, 'decrement_request_limit method reached');
