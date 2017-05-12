#!perl
use lib 't/lib';
use Test::Sietima;

subtest 'disabled' => sub {
    my $s = make_sietima(
        with_traits => ['ReplyTo'],
        munge_reply_to => 0,
        subscribers => [
            'one@users.example.com',
            'two@users.example.com',
        ],
    );

    test_sending(
        sietima => $s,
        mails => [
            object {
                call [ header_str => 'reply-to' ] => undef;
            },
        ],
    );
};

subtest 'enabled' => sub {
    my $s = make_sietima(
        with_traits => ['ReplyTo'],
        munge_reply_to => 1,
        subscribers => [
            'one@users.example.com',
            'two@users.example.com',
        ],
    );

    test_sending(
        sietima => $s,
        mails => [
            object {
                call [ header_str => 'reply-to' ] => $s->return_path->address;
            },
        ],
    );
};

subtest 'enabled, custom post address' => sub {
    my $post_address = 'the-list@example.com';
    my $s = make_sietima(
        with_traits => ['ReplyTo'],
        munge_reply_to => 1,
        subscribers => [
            'one@users.example.com',
            'two@users.example.com',
        ],
        post_address => $post_address,
    );

    is(
        $s->list_addresses,
        hash {
            field return_path => $s->return_path;
            field post => object {
                call address => $post_address;
            };
        },
        'the custom post address should be set for the headers',
    );

    test_sending(
        sietima => $s,
        mails => [
            object {
                call [ header_str => 'reply-to' ] => $post_address;
            },
        ],
    );
};

subtest 'enabled for some' => sub {
    my $s = make_sietima(
        with_traits => ['ReplyTo'],
        munge_reply_to => 0,
        subscribers => [
            {
                primary => 'one@users.example.com',
                prefs => { munge_reply_to => 1 },
            },
            'two@users.example.com',
        ],
    );

    test_sending(
        sietima => $s,
        mails => [
            {
                o => object {
                    call [ header_str => 'reply-to' ] => $s->return_path->address;
                },
                to => [ 'one@users.example.com' ],
            },
            {
                o => object {
                    call [ header_str => 'reply-to' ] => undef;
                },
                to => [ 'two@users.example.com' ],
            },
        ],
    );
};


subtest 'disabled for some' => sub {
    my $s = make_sietima(
        with_traits => ['ReplyTo'],
        munge_reply_to => 1,
        subscribers => [
            {
                primary => 'one@users.example.com',
                prefs => { munge_reply_to => 0 },
            },
            'two@users.example.com',
        ],
    );

    test_sending(
        sietima => $s,
        mails => [
            {
                o => object {
                    call [ header_str => 'reply-to' ] => $s->return_path->address;
                },
                to => [ 'two@users.example.com' ],
            },
            {
                o => object {
                    call [ header_str => 'reply-to' ] => undef;
                },
                to => [ 'one@users.example.com' ],
            },
        ],
    );
};

done_testing;
