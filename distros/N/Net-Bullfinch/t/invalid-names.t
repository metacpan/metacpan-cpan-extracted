use strict;
use Test::More;
use Test::Exception;

use Net::Bullfinch;

my $bf = Net::Bullfinch->new(host => '256.256.256.256');
throws_ok(sub {
    $bf->send(
        request_queue => 'blah-blah-blah',
        request => { statement => 'getCurrentTime' },
        response_queue_suffix => 'cory...',
    )
},
    qr/did not pass/,
    "failed on a n invalid response_queue_suffix"
);

throws_ok(sub {
    $bf->send(
        request_queue => 'blah.blah.blah',
        request => { statement => 'getCurrentTime' },
        response_queue_suffix => 'cory',
    )
},
    qr/did not pass/,
    "failed on a n invalid request_queue"
);

done_testing;