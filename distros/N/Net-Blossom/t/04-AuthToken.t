use strictures 2;

use Test::More;
use JSON ();
use MIME::Base64 qw(decode_base64);

BEGIN {
    *CORE::GLOBAL::time = sub { 2_000_000_000 };
}

use Net::Blossom::AuthToken;

sub dies(&) {
    my ($code) = @_;
    my $ok = eval { $code->(); 1 };
    return $ok ? undef : $@;
}

{
    package Local::PubkeyOnly;
    use strictures 2;

    sub pubkey_hex {
        return '7' x 64;
    }
}

{
    package Local::Key;
    use strictures 2;

    sub new {
        my ($class, $pubkey) = @_;
        return bless { pubkey => $pubkey, signed => 0 }, $class;
    }

    sub pubkey_hex {
        my ($self) = @_;
        return $self->{pubkey};
    }

    sub sign_event {
        my ($self, $event) = @_;
        $self->{signed}++;
        $event->sig('b' x 128);
        return $event->sig;
    }

    sub signed {
        my ($self) = @_;
        return $self->{signed};
    }
}

my $PUBKEY = '79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798';
my $HASH = 'b1674191a88ec5cdd733e4240a81803105dc412d6c6708d53ab94fc248f4f553';
my $NOW = time;
my $FUTURE = $NOW + 3600;
my $PAST = $NOW - 1;

sub decode_b64url {
    my ($value) = @_;
    $value =~ tr/-_/+\//;
    $value .= '=' while length($value) % 4;
    return decode_base64($value);
}

subtest 'creates signed BUD-11 kind 24242 event' => sub {
    my $key = Local::Key->new($PUBKEY);
    my $token = Net::Blossom::AuthToken->new(
        key        => $key,
        action     => 'upload',
        content    => 'Upload Blob',
        expiration => $FUTURE,
        server     => 'cdn.example.com',
        hashes     => [$HASH],
        created_at => 1708850000,
    );

    my $event = $token->to_event;
    is($event->kind, 24242, 'kind');
    is($event->pubkey, $PUBKEY, 'pubkey');
    is($event->content, 'Upload Blob', 'content');
    is($event->sig, 'b' x 128, 'signed');
    is($key->signed, 1, 'key signed event once');

    is_deeply($event->tags, [
        ['t', 'upload'],
        ['expiration', '' . $FUTURE],
        ['server', 'cdn.example.com'],
        ['x', $HASH],
    ], 'tags');
};

subtest 'defaults BUD-11 created_at to the previous second' => sub {
    my $key = Local::Key->new($PUBKEY);
    my $token = Net::Blossom::AuthToken->new(
        key        => $key,
        action     => 'get',
        content    => 'Get Blob',
        expiration => $FUTURE,
    );

    is($token->created_at, $NOW - 1, 'token default created_at is immediately in the past');
    is($token->to_event->created_at, $NOW - 1, 'event uses the default created_at');
};

subtest 'creates BUD-11 server-scoped events with multiple server tags' => sub {
    my $key = Local::Key->new($PUBKEY);
    my $token = Net::Blossom::AuthToken->new(
        key        => $key,
        action     => 'get',
        content    => 'Get Blob',
        expiration => $FUTURE,
        servers    => ['cdn.example.com', 'media.example.com'],
        created_at => 1708850000,
    );

    is_deeply($token->to_event->tags, [
        ['t', 'get'],
        ['expiration', '' . $FUTURE],
        ['server', 'cdn.example.com'],
        ['server', 'media.example.com'],
    ], 'multiple server tags');
};

subtest 'encodes Authorization header as Nostr base64url without padding' => sub {
    my $key = Local::Key->new($PUBKEY);
    my $token = Net::Blossom::AuthToken->new(
        key        => $key,
        action     => 'delete',
        content    => 'Delete Blob',
        expiration => $FUTURE,
        hashes     => [$HASH],
        created_at => 1708850000,
    );

    my $header = $token->authorization_header;
    like($header, qr/\ANostr [A-Za-z0-9_-]+\z/, 'base64url Nostr header without padding');

    my ($scheme, $payload) = split / /, $header, 2;
    is($scheme, 'Nostr', 'scheme');

    my $data = JSON->new->utf8->decode(decode_b64url($payload));
    is($data->{kind}, 24242, 'decoded kind');
    is($data->{tags}[0][1], 'delete', 'decoded action tag');
};

subtest 'validates BUD-11 token inputs' => sub {
    my $key = Local::Key->new($PUBKEY);

    like(dies { Net::Blossom::AuthToken->new(key => 'not-a-key', action => 'get', content => 'x', expiration => $FUTURE) },
        qr/key must provide pubkey_hex and sign_event/, 'scalar key rejected');
    like(dies { Net::Blossom::AuthToken->new(key => bless({}, 'Local::PubkeyOnly'), action => 'get', content => 'x', expiration => $FUTURE) },
        qr/key must provide pubkey_hex and sign_event/, 'partial key object rejected');
    like(dies { Net::Blossom::AuthToken->new(key => $key, action => 'bogus', content => 'x', expiration => $FUTURE) },
        qr/action/, 'unknown action rejected');
    like(dies { Net::Blossom::AuthToken->new(key => $key, action => 'upload', content => 'x', expiration => $PAST, hashes => [$HASH]) },
        qr/expiration.*future/, 'expired token rejected');
    like(dies { Net::Blossom::AuthToken->new(key => $key, action => 'upload', content => 'x', expiration => $FUTURE, server => 'https://cdn.example.com') },
        qr/server.*domain/, 'server URL rejected');
    like(dies { Net::Blossom::AuthToken->new(key => $key, action => 'get', content => 'x', expiration => $FUTURE, server => '.') },
        qr/server.*domain/, 'bare dot server rejected');
    like(dies { Net::Blossom::AuthToken->new(key => $key, action => 'get', content => 'x', expiration => $FUTURE, server => 'bad..example') },
        qr/server.*domain/, 'empty domain label rejected');
    like(dies { Net::Blossom::AuthToken->new(key => $key, action => 'get', content => 'x', expiration => $FUTURE, server => '-bad.example') },
        qr/server.*domain/, 'leading label hyphen rejected');
    like(dies { Net::Blossom::AuthToken->new(key => $key, action => 'get', content => 'x', expiration => $FUTURE, server => 'bad-.example') },
        qr/server.*domain/, 'trailing label hyphen rejected');
    like(dies { Net::Blossom::AuthToken->new(key => $key, action => 'get', content => 'x', expiration => $FUTURE, servers => 'cdn.example.com') },
        qr/servers.*array reference/, 'servers arrayref required');
    like(dies { Net::Blossom::AuthToken->new(key => $key, action => 'get', content => 'x', expiration => $FUTURE, servers => ['https://cdn.example.com']) },
        qr/server.*domain/, 'server URL in servers rejected');
    like(dies { Net::Blossom::AuthToken->new(key => $key, action => 'upload', content => 'x', expiration => $FUTURE, hashes => ['A' x 64]) },
        qr/hash.*lowercase hex/, 'uppercase hash rejected');
};

subtest 'requires hash scope for BUD-11 hash-scoped actions' => sub {
    my $key = Local::Key->new($PUBKEY);

    for my $action (qw(upload delete media)) {
        like(dies { Net::Blossom::AuthToken->new(key => $key, action => $action, content => 'x', expiration => $FUTURE) },
            qr/requires at least one hash/, "$action requires default hash scope");
        like(dies { Net::Blossom::AuthToken->new(key => $key, action => $action, content => 'x', expiration => $FUTURE, hashes => []) },
            qr/requires at least one hash/, "$action rejects empty hash scope");
    }

    ok(Net::Blossom::AuthToken->new(key => $key, action => 'get', content => 'x', expiration => $FUTURE),
        'get may omit hash scope');
    ok(Net::Blossom::AuthToken->new(key => $key, action => 'list', content => 'x', expiration => $FUTURE),
        'list does not use hash scope');
};

done_testing;
