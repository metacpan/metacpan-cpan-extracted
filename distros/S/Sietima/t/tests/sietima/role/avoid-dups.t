#!perl
use lib 't/lib';
use Test::Sietima;

my $s = make_sietima(
    with_traits => ['AvoidDups'],
    subscribers => [
        'one@users.example.com',
        'two@users.example.com',
    ],
);

subtest 'in cc' => sub {
    test_sending(
        sietima => $s,
        mail => { cc => 'one@users.example.com' },
        to => ['two@users.example.com'],
    );
};

subtest 'in to' => sub {
    test_sending(
        sietima => $s,
        mail => { to => $s->return_path . ' one@users.example.com' },
        to => ['two@users.example.com'],
    );
};

done_testing;
