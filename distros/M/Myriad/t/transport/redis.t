use strict;
use warnings;

use Test::More;

use IO::Async::Loop;
use Myriad::Redis::Pending;

subtest 'pending instance' => sub {
    my $redis = do {
        package Placeholder::Redis;
        sub loop { IO::Async::Loop->new }
        bless {}, __PACKAGE__;
    };
    my $pending = new_ok('Myriad::Redis::Pending', [
        redis => $redis,
        stream => 'the-stream',
        group => 'the-group',
        id => 1234
    ]);
    isa_ok($pending->finished, qw(Future));
};

done_testing;

