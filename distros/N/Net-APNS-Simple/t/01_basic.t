use strict;
use Test::More 0.98;
use Net::APNS::Simple;

my $apns = new_ok('Net::APNS::Simple' => [
    auth_key        => 'SAMPLE.p8',
    key_id          => 'abcdefg',
    team_id         => 'hijklmn',
    bundle_id       => 'opqrstu',
    development     => 0,
    apns_expiration => 0,
    apns_priority   => 5,
    apns_push_type  => 'background',
]);

is($apns->auth_key => 'SAMPLE.p8');
is($apns->key_id => 'abcdefg');
is($apns->team_id => 'hijklmn');
is($apns->bundle_id => 'opqrstu');
is($apns->development => 0);
is($apns->apns_expiration => 0);
is($apns->apns_priority => 5);
is($apns->apns_push_type => 'background');
is($apns->algorithm => 'ES256');
is($apns->_host => 'api.push.apple.com');
$apns->development(1);
is($apns->_host => 'api.sandbox.push.apple.com');
is($apns->_port => 443);

done_testing;

