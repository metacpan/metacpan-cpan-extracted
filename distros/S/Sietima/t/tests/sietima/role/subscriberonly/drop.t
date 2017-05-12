#!perl
use lib 't/lib';
use Test::Sietima;

my @subscriber_addresses = (
    'one@users.example.com',
    {
        primary => 'two@users.example.com',
        aliases => [ 'two-two@users.example.com' ],
    },
);
my $s = make_sietima(
    with_traits => ['SubscriberOnly::Drop'],
    subscribers => \@subscriber_addresses,
);

subtest 'from subscriber' => sub {
    test_sending(
        sietima => $s,
        mail => { from=>'one@users.example.com' },
    );
};

subtest 'from subscriber alias' => sub {
    test_sending(
        sietima => $s,
        mail => { from=>'two-two@users.example.com' },
    );
};

subtest 'from non-subscriber' => sub {
    test_sending(
        sietima => $s,
        mail => { from=>'someone@users.example.com' },
        to => [],
    );
};

done_testing;
