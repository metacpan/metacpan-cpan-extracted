#!perl -T

use strict;
use warnings;

use Test::More;
use Net::BrowserID::Verify qw(verify_remotely);

diag( "Testing a simple failure case with the hosted remote verifier (procedure)" );
my $data1 = verify_remotely('assertion', 'audience', {
    # From: https://onlinessl.netlock.hu/en/test-center/invalid-ssl-certificate.html
    url => 'https://tv.eurosport.com/',
});
is($data1->{status}, q{failure}, q{The verification failed});
ok($data1->{reason} =~ m{Can't\sconnect}xms, q{SSL cert couldn't be verified});

done_testing();
