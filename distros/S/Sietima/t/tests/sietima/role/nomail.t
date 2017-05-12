#!perl
use lib 't/lib';
use Test::Sietima;

subtest 'disabled' => sub {
    my $s = make_sietima(
        with_traits => ['NoMail'],
        subscribers => [
            {
                primary => 'one@users.example.com',
                prefs => { wants_mail => 0 },
            },
            'two@users.example.com',
        ],
    );

    test_sending(
        sietima => $s,
        to => ['two@users.example.com'],
    );
};

subtest 'enabled' => sub {
    my $s = make_sietima(
        with_traits => ['NoMail'],
        subscribers => [
            {
                primary => 'one@users.example.com',
                prefs => { wants_mail => 1 },
            },
            'two@users.example.com',
        ],
    );

    test_sending(
        sietima => $s,
        to => ['one@users.example.com','two@users.example.com'],
    );
};

done_testing;
