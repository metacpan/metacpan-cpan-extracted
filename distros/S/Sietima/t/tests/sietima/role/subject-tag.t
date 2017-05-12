#!perl
use lib 't/lib';
use Test::Sietima;

my $s = make_sietima(
    with_traits => ['SubjectTag'],
    subscribers => [
        'one@users.example.com',
        'two@users.example.com',
    ],
    subject_tag => 'foo',
);

subtest 'adding tag' => sub {
    test_sending(
        sietima => $s,
        mails => [
            object {
                call [ header_str => 'Subject' ] =>
                    '[foo] Test Message';
            },
        ],
    );
};

subtest 'tag already there' => sub {
    my $subject = "[foo] \N{HEAVY BLACK HEART} test";
    test_sending(
        sietima => $s,
        mail => {
            subject => $subject,
        },
        mails => [
            object {
                call [ header_str => 'Subject' ] =>
                    $subject;
            },
        ],
    );
};

done_testing;
