#!perl
use lib 't/lib';
use Test::Sietima;

subtest 'default should no-op' => sub {
    my $s = make_sietima(
        with_traits => ['StripHeaders'],
        name => 'test-list',
        subscribers => [
            'one@users.example.com',
            'two@users.example.com',
        ],
    );

    test_sending(
        sietima => $s,
        mail => {
            headers => {
                dkim => 'some pretend signature',
            },
        },
        mails => [
            object {
                call sub { +{ shift->header_raw_pairs } } => hash {
                    field 'Date' => D();
                    field 'MIME-Version' => D();
                    field 'Content-Type' => D();
                    field 'Content-Transfer-Encoding' => D();
                    field 'From' => 'someone@users.example.com';
                    field 'To' => 'sietima-test@list.example.com';
                    field 'Subject' => 'Test Message';
                    field 'Dkim' => 'some pretend signature';

                    end;
                };
            },
        ],
    );
};

subtest 'matching headers should be stripped' => sub {
    my $s = make_sietima(
        with_traits => ['StripHeaders'],
        name => 'test-list',
        subscribers => [
            'one@users.example.com',
            'two@users.example.com',
        ],
        strip_headers => [ qr{^dkim\b}i, qr{^arc\b}i ],
    );

    test_sending(
        sietima => $s,
        mail => {
            headers => {
                'dkim-signature' => 'some pretend signature',
                'arc-seal' => 'some different signature',
            },
        },
        mails => [
            object {
                call sub { +{ shift->header_raw_pairs } } => hash {
                    field 'Date' => D();
                    field 'MIME-Version' => D();
                    field 'Content-Type' => D();
                    field 'Content-Transfer-Encoding' => D();
                    field 'From' => 'someone@users.example.com';
                    field 'To' => 'sietima-test@list.example.com';
                    field 'Subject' => 'Test Message';

                    end;
                };
            },
        ],
    );
};

done_testing;
