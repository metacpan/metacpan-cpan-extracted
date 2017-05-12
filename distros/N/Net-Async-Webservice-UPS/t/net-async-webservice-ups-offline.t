#!perl
use strict;
use warnings;
use Test::Most;
use Test::Fatal;
use lib 't/lib';
use Test::Net::Async::Webservice::UPS;
use Test::Net::Async::Webservice::UPS::Factory;

my ($ups,$u) = Test::Net::Async::Webservice::UPS::Factory::without_network;

Test::Net::Async::Webservice::UPS::test_it($ups);

subtest 'HTTP failure' => sub {
    my $f = $ups->validate_address(
        Net::Async::Webservice::UPS::Address->new({
            postal_code => '12345',
        }),
    );

    $f->await until $f->is_ready;

    ok(!$f->is_done && !$f->is_cancelled,'Future is failed');

    cmp_deeply(
        [$f->failure],
        [
            all(
                isa('Net::Async::Webservice::Common::Exception::HTTPError'),
                methods(
                    response => methods(code=>500),
                ),
            ),
            'webservice',
        ],
    );
};

subtest 'UPS failure' => sub {
    $u->file_for_next_test('t/data/address-fail');

    my $f = $ups->validate_address(
        Net::Async::Webservice::UPS::Address->new({
            postal_code => '12345',
        }),
    );

    $f->await until $f->is_ready;

    ok(!$f->is_done && !$f->is_cancelled,'Future is failed');

    cmp_deeply(
        [$f->failure],
        [
            all(
                isa('Net::Async::Webservice::UPS::Exception::UPSError'),
                methods(
                    error => {
                        ErrorDescription => 'manual failure for testing',
                        ErrorSeverity => 'medium',
                        ErrorCode => 999,
                    },
                ),
            ),
            'ups',
        ],
    );
};

done_testing();
