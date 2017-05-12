#!perl
use lib 't/lib';
use Test::Sietima;

my $s = make_sietima(
    with_traits => ['Headers','ManualSubscription'],
    name => 'test-list',
    owner => 'owner@example.com',
    subscribers => [
        'one@users.example.com',
        'two@users.example.com',
    ],
);

subtest '(un)sub headers should be added' => sub {
    test_sending(
        sietima => $s,
        mails => [
            object {
                call sub { +{ shift->header_raw_pairs } } => hash {
                    field 'List-Subscribe' => '<mailto:owner@example.com?subject=Please+add+me+to+test-list>';
                    field 'List-Unsubscribe' => '<mailto:owner@example.com?subject=Please+remove+me+from+test-list>';

                    etc;
                };
            },
        ],
    );
};

done_testing;
