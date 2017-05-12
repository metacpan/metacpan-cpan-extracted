#!perl
use lib 't/lib';
use Test::Sietima;
use Test::Sietima::MailStore;

sub test_one($traits,$should_send=1) {
    my @subscriber_addresses = (
        'one@users.example.com',
        'two@users.example.com',
    );
    my $owner = 'owner@lists.example.com';
    my $ms = Test::Sietima::MailStore->new();

    my $s = make_sietima(
        with_traits => $traits,
        subscribers => \@subscriber_addresses,
        owner => $owner,
        mail_store => $ms,
    );

    test_sending(
        sietima => $s,
        mail => { from=>'someone@users.example.com' },
        mails => [{
            o => object {
                call [header_str => 'subject'] => match qr{\bheld for moderation\b};
            },
        }],
    );
    transport->clear_deliveries;

    my $to_moderate = $ms->retrieve_by_tags('moderation');
    my $msg_id = $to_moderate->[0]->{id};
    $s->resume($msg_id);

    if ($should_send) {
        deliveries_are(
            to => \@subscriber_addresses,
            test_message => 'the resumed message should be sent',
        );
    }
    else {
        deliveries_are(
            mails => [],
            test_message => 'the resumed message should be dropped',
        );
    }
}

# there's an ordering dependency between Debounce and Moderate: if we
# moderate a message that already has the X-Been-There header, it will
# be dropped when resumed; the simplest solution is to apply Debounce
# *before* Moderate, so messages are moderated *before* getting the
# anti-loop header

subtest 'debounce first' => sub {
    test_one(['Debounce','SubscriberOnly::Moderate'],1);
};

subtest 'moderate first' => sub {
    test_one(['SubscriberOnly::Moderate','Debounce'],0);
};

done_testing;
