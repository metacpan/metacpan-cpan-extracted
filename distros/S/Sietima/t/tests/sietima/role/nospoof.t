#!perl
use lib 't/lib';
use Test::Sietima;

my $s = make_sietima(
    with_traits => ['NoSpoof'],
    subscribers => [
        'one@users.example.com',
        'two@users.example.com',
    ],
);

test_sending(
    sietima => $s,
    mail => {
        from => 'a user <one@users.example.com>',
    },
    mails => [
        object {
            call [ header_str => 'from' ] => '"a user" <'.$s->return_path->address.'>';
        },
    ],
);

done_testing;
