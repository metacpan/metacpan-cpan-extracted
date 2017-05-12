use strict;
use warnings;
use Test::More;
use Net::APNs::Extended::Base;

subtest 'no args' => sub {
    eval { Net::APNs::Extended::Base->new };
    like $@, qr/`cert_file` or `cert` must be specify/;
};

subtest 'specifying both cert_file and cert' => sub {
    eval {
        Net::APNs::Extended::Base->new(
            cert_file => 'xxx.cert',
            cert      => 'yyy',
        );
    };
    like $@, qr/specifying both `cert_file` and `cert` is not allowed/;
};

subtest 'specifying both key_file and key' => sub {
    eval {
        Net::APNs::Extended::Base->new(
            cert_file => 'xxx.cert',
            key_file  => 'yyy.key',
            key       => 'zzz',
        );
    };
    like $@, qr/specifying both `key_file` and `key`/;
};

subtest 'success' => sub {
    my $apns = Net::APNs::Extended::Base->new(
        cert_file => 'xxx.cert',
        key_file  => 'yyy.key',
    );
    isa_ok $apns, 'Net::APNs::Extended::Base';
};

done_testing;
