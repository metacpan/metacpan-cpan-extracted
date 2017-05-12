use strict;
use warnings;
use lib 'lib';

use Test::More;
use Test::Requires qw(
    Test::Fatal
);

use Net::Signalet::Client;
use Net::Signalet::Server;

subtest "not connect" => sub {
    subtest server => sub {
        my $signalet = Net::Signalet::Server->new(
            saddr => "127.0.0.1",
            timeout => 0.1,
            reuse => 1,
        );

        if (ok $signalet) {
            isa_ok $signalet, "Net::Signalet::Server";
            ok !$signalet->{sock}, 'in case of not connecting to client';
            isa_ok $signalet->{ssock}, "IO::Socket::INET";
        }
    };

    subtest client => sub {
        like exception {
            my $signalet = Net::Signalet::Client->new(
                daddr => "127.0.0.1",
                saddr => "127.0.0.1",
                timeout => 0.1,
            );
        }, qr(^Can't connect to server:);
    };

};

done_testing;
