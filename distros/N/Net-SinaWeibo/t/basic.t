use strict;
use warnings;
use Test::More tests => 4;
use Net::SinaWeibo::OAuth;

my $oauth = Net::SinaWeibo::OAuth->new;
$oauth->_api_error('{
    "error_code" : "403",
    "request" : "/statuses/friends_timeline.json",
    "error" : "40302:Error: auth faild!"
}');

is($oauth->last_api_error_code,403,'last_api_error_code');
is($oauth->last_api_error_subcode,40302,'last_api_subcode');

$oauth->_api_error('<html><body>XID 5555</body></html>',500);
is($oauth->last_api_error_code,500,'unknown http error');
is($oauth->last_api_error_subcode,0,'unknown http error');