#!perl -T
use strict;

use Test::More tests => 2;
use Net::iContact;

my $api = Net::iContact->new('user', 'pass', 'key', 'secret');

### test gen_sig
my $sig = $api->gen_sig('auth/login/' . $api->username . '/' . $api->password, { 'api_key' => $api->api_key });
ok($sig eq '313ac77dab727a93eaef1104c49d9dc8');

### test gen_url
my $url = $api->gen_url('auth/login/' . $api->username . '/' . $api->password, { 'api_key' => $api->api_key });
ok ($url eq "http://api.icontact.com/icp/core/api/v1.0/auth/login/user/1a1dc91c907325c69271ddf0c944bc72/?api_sig=313ac77dab727a93eaef1104c49d9dc8&api_key=key");
