use strict;
use Test::More 0.98;
use File::Basename ();
use File::Spec ();
use Net::APNS::Simple;

my $test_dir = File::Basename::dirname(__FILE__);

my $apns = Net::APNS::Simple->new(
    auth_key        => File::Spec->catfile($test_dir => 'SAMPLE.p8'),
    key_id          => 'abcdefg',
    team_id         => 'hijklmn',
    bundle_id       => 'opqrstu',
    development     => 0,
    apns_expiration => 0,
    apns_priority   => 5,
);

is($apns->prepare(1 => {alert => "Hello"}) => $apns);
is(scalar @{$apns->{_request}} => 1);
$apns->_make_client_request_single();
is(scalar @{$apns->{_request}} => 0);

done_testing;
