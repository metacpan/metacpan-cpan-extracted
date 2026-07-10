use strictures 2;

use Test::More;

use Net::Blossom::AuthToken;

{
    package Local::Key;
    use strictures 2;
    sub new { bless { pubkey => $_[1] }, $_[0] }
    sub pubkey_hex { $_[0]->{pubkey} }
    sub sign_event { $_[1]->sig('c' x 128); $_[1]->sig }
}

my $PUBKEY = '79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798';
my $HASH = 'b1674191a88ec5cdd733e4240a81803105dc412d6c6708d53ab94fc248f4f553';
my $FUTURE = time + 3600;
my $PAST = time - 1;

subtest 'BUD-11 authorization token uses kind 24242 and required tags' => sub {
    my $event = Net::Blossom::AuthToken->new(
        key => Local::Key->new($PUBKEY),
        action => 'upload',
        content => 'Upload Blob',
        expiration => $FUTURE,
        hashes => [$HASH],
    )->to_event;

    is($event->kind, 24242, 'kind 24242');
    is_deeply($event->tags, [
        ['t', 'upload'],
        ['expiration', '' . $FUTURE],
        ['x', $HASH],
    ], 'required tags');
};

subtest 'BUD-11 authorization token may include multiple server scopes' => sub {
    my $event = Net::Blossom::AuthToken->new(
        key => Local::Key->new($PUBKEY),
        action => 'get',
        content => 'Get Blob',
        expiration => $FUTURE,
        servers => ['cdn.example.com', 'media.example.com'],
    )->to_event;

    is_deeply($event->tags, [
        ['t', 'get'],
        ['expiration', '' . $FUTURE],
        ['server', 'cdn.example.com'],
        ['server', 'media.example.com'],
    ], 'multiple server tags');
};

subtest 'BUD-11 Authorization header uses Nostr scheme' => sub {
    my $header = Net::Blossom::AuthToken->new(
        key => Local::Key->new($PUBKEY),
        action => 'list',
        content => 'List Images',
        expiration => $FUTURE,
    )->authorization_header;

    like($header, qr/\ANostr /, 'Nostr scheme');
};

subtest 'BUD-11 authorization token expiration must be in the future' => sub {
    my $error = eval {
        Net::Blossom::AuthToken->new(
            key => Local::Key->new($PUBKEY),
            action => 'get',
            content => 'Get Blob',
            expiration => $PAST,
        );
        undef;
    } || $@;

    like($error, qr/expiration.*future/, 'expired token rejected');
};

subtest 'BUD-11 hash-scoped endpoints require x tags' => sub {
    for my $action (qw(upload delete media)) {
        my $error = eval {
            Net::Blossom::AuthToken->new(
                key => Local::Key->new($PUBKEY),
                action => $action,
                content => 'Hash scoped action',
                expiration => $FUTURE,
            );
            undef;
        } || $@;
        like($error, qr/requires at least one hash/, "$action requires x tag");
    }
};

done_testing;
