#!perl
use lib 't/lib';
use Test::Sietima;

ok(make_sietima(),'should instantiate') or bail_out;

subtest 'no subscribers' => sub {
    test_sending(
        to => [],
    );
};

subtest 'with subscribers' => sub {
    my @subscriber_addresses = (
        'one@users.example.com',
        'two@users.example.com',
    );
    test_sending(
        sietima => { subscribers => \@subscriber_addresses },
        to => \@subscriber_addresses,
    );
};

done_testing;
