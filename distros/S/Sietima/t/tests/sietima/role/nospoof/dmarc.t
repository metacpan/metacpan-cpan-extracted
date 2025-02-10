#!perl
use lib 't/lib';
use Test::Sietima;
use Net::DNS::Resolver::Mock;

my $resolver = Net::DNS::Resolver::Mock->new();

my $s = make_sietima(
    with_traits => ['NoSpoof::DMARC'],
    subscribers => [
        'one@users.example.com',
    ],
    dmarc_resolver => $resolver,
);

sub test_rewriting($from) {
    subtest "$from should rewrite" => sub {
        test_sending(
            sietima => $s,
            mail => {
                from => "a user <$from>",
            },
            mails => [
                object {
                    call [ header_str => 'from' ] => '"a user" <'.$s->return_path->address.'>';
                    call [ header_str => 'original-from' ] => qq{"a user" <$from>};
                },
            ],
        );
    }
}

sub test_no_rewriting($from) {
    subtest "$from should not rewrite" => sub {
        test_sending(
            sietima => $s,
            mail => {
                from => "a user <$from>",
            },
            mails => [
                object {
                    call [ header_str => 'sender' ] => $s->return_path->address;
                    call [ header_str => 'from' ] => qq{"a user" <$from>};
                },
            ],
        );
    }
}

$resolver->zonefile_parse(<<'EOZ');
_dmarc.none-none-pol.com 3600 TXT "v=DMARC1; p=none; sp=none; rua=mailto:foo@example.com"
_dmarc.none-q-pol.com 3600 TXT "v=DMARC1; p=none; sp=quarantine; rua=mailto:foo@example.com"
_dmarc.q-q-pol.com 3600 TXT "v=DMARC1; p=quarantine; sp=quarantine; rua=mailto:foo@example.com"
EOZ

test_no_rewriting 'foo@none-none-pol.com';
test_no_rewriting 'foo@sub.none-none-pol.com';

test_no_rewriting 'foo@none-q-pol.com';
test_rewriting    'foo@sub.none-q-pol.com';

test_rewriting    'foo@q-q-pol.com';
test_rewriting    'foo@sub.q-q-pol.com';

test_no_rewriting 'foo@example.com';

test_no_rewriting 'foo@' . $s->post_address->host;

done_testing;
