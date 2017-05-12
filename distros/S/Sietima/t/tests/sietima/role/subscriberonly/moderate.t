#!perl
use lib 't/lib';
use Test::Sietima;
use Test::Sietima::MailStore;

my @subscriber_addresses = (
    'one@users.example.com',
    'two@users.example.com',
);
my $owner = 'owner@lists.example.com';
my $ms = Test::Sietima::MailStore->new();
my $s = make_sietima(
    with_traits => ['SubscriberOnly::Moderate'],
    subscribers => \@subscriber_addresses,
    owner => $owner,
    mail_store => $ms,
);

subtest 'from subscriber' => sub {
    $ms->clear;
    test_sending(
        sietima => $s,
        mail => { from=>'one@users.example.com' },
    );
    is(
        $ms->retrieve_by_tags('moderation'),
        [],
        'no mails held for moderation',
    );
};

sub test_from_non_sub() {
    my $from = $s->return_path->address;
    test_sending(
        sietima => $s,
        mail => { from=>'someone@users.example.com' },
        mails => [{
            o => object {
                call [header_str => 'subject'] => match qr{\bheld for moderation\b};
                call [header_str => 'from'] => match qr{\b\Q$from\E\b};
                call [header_str => 'to'] => match qr{\b\Q$owner\E\b};
                call_list parts => [
                    object {
                        call body => match qr{Use id \S+ to refer to it};
                    },
                    object {
                        call sub {Email::MIME->new(shift->body)} => object {
                            call [header_str => 'subject'] => 'Test Message';
                        };
                    },
                ];
            },
            from => $from,
            to => [$owner],
        }],
    );
}

subtest 'from non-subscriber' => sub {
    $ms->clear;
    test_from_non_sub;

    is(
        my $to_moderate = $ms->retrieve_by_tags('moderation'),
        [
            {
                id => T(),
                mail => object {
                    call [header_str => 'from'] => 'someone@users.example.com';
                    call [header_str => 'to'] => $s->return_path->address,
                },
            },
        ],
        'mails was held for moderation',
    );

    like(
        run_cmdline_sub($s, 'list_mails_in_moderation_queue'),
        hash {
            field exit => 0;
            field error => DNE;
            field output => qr{\A
                               ^\N+\b1 \s+ message\N+$ \n
                               ^\* \s+ \w+ \s+ someone\@users\.example\.com
                               \s+ "Test[ ]Message"
                               \s+ \(\N+?\)$
                          }smx;
        },
        'mails in queue should be listed from command line',
    );

    my $msg_id = $to_moderate->[0]->{id};

    like(
        run_cmdline_sub(
            $s, 'show_mail_from_moderation_queue',
            {}, { 'mail-id' => $msg_id },
        ),
        hash {
            field exit => 0;
            field error => DNE;
            field output => qr{\A
                               ^Message \s+ \w+:$
                               .*?
                               ^From: \s+ someone\@users\.example\.com \s*$
                          }smx;
        },
        'mail in queue should be shown from command line',
    );

    transport->clear_deliveries;
    $s->resume($msg_id);
    deliveries_are(
        to => \@subscriber_addresses,
    );
};

subtest 'from non-subscriber, drop' => sub {
    $ms->clear;
    test_from_non_sub;

    my $msg_id = $ms->retrieve_by_tags('moderation')->[0]{id};
    $s->drop($msg_id);
    is(
        $ms->retrieve_by_tags('moderation'),
        [],
        'message should be dropped',
    );
};

done_testing;
