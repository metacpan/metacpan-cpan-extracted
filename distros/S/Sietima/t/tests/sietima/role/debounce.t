#!perl
use lib 't/lib';
use Test::Sietima;

my $s = make_sietima(
    with_traits => ['Debounce'],
    subscribers => [
        'one@users.example.com',
        'two@users.example.com',
    ],
);

my $return_path = $s->return_path->address;

subtest 'header should be added' => sub {
    test_sending(
        sietima => $s,
        mails => [
            object {
                call [ header_str => 'X-Been-There' ] =>
                    match qr{\b\Q$return_path\E\b};
            },
        ],
    );
};

subtest 'header should inhibit sending' => sub {
    test_sending(
        sietima => $s,
        mail => {
            headers => { 'x-been-there' => $return_path },
        },
        to => [],
    );
};

done_testing;
