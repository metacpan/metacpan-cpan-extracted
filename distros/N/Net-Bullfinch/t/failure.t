use strict;
use Test::More;
use Test::Exception;

use Net::Bullfinch;

my $bf = Net::Bullfinch->new(host => '256.256.256.256');
throws_ok(sub {
    $bf->send(
        request_queue => 'blah-blah-blah',
        request => { statement => 'getCurrentTime' },
        response_queue_suffix => 'cory',
    ) },
    qr/Failed to send/,
    "failed on a busted host"
);

done_testing;
