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

my $return_path = $s->return_path;
my $return_path_address = $return_path->address;
my $return_path_host = $return_path->host;

test_sending(
    sietima => $s,
    mail => {
        from => 'a user <one@users.example.com>',
    },
    mails => [
        object {
            call [ header_str => 'from' ] => qq{"a user" <$return_path_address>};
        },
    ],
);

test_sending(
    sietima => $s,
    mail => {
        from => qq{a user <one\@$return_path_host>},
    },
    mails => [
        object {
            call [ header_str => 'from' ] => qq{"a user" <one\@$return_path_host>};
        },
    ],
);

done_testing;
