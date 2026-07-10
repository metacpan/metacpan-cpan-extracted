use strictures 2;

use Test::More;
use JSON ();
use MIME::Base64 qw(encode_base64);

BEGIN {
    *CORE::GLOBAL::time = sub { 2_000_000_000 };
}

use Net::Blossom::AuthToken;
use Net::Blossom::Server::Authorization;
use Net::Blossom::Server::Error;
use Net::Blossom::Server::Request;
use Net::Nostr::Event;
use Net::Nostr::Key;

my $SHA256 = '0f343b0931126a20f133d67c2b018a3b5ceca63dd3585a76cb1f3289a274707f';
my $OTHER_SHA256 = 'b1674191a88ec5cdd733e4240a81803105dc412d6c6708d53ab94fc248f4f553';
my $LIST_PUBKEY = '79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798';
my $NOW = time;
my $JSON = JSON->new->utf8->canonical;

sub dies(&) {
    my ($code) = @_;
    my $ok = eval { $code->(); 1 };
    return $ok ? undef : $@;
}

sub header_from_hash {
    my ($hash) = @_;
    my $b64 = encode_base64($JSON->encode($hash), '');
    $b64 =~ tr{+/}{-_};
    $b64 =~ s/=+\z//;
    return "Nostr $b64";
}

sub decode_header_hash {
    my ($header) = @_;
    my ($scheme, $payload) = split / /, $header, 2;
    $payload =~ tr{-_}{+/};
    $payload .= '=' while length($payload) % 4;
    return JSON->new->utf8->decode(MIME::Base64::decode_base64($payload));
}

sub signed_header {
    my ($key, %args) = @_;
    my $event = Net::Nostr::Event->new(
        pubkey     => $key->pubkey_hex,
        kind       => exists $args{kind} ? $args{kind} : 24242,
        created_at => exists $args{created_at} ? $args{created_at} : $NOW - 1,
        tags       => $args{tags} || [
            ['t', $args{action} || 'get'],
            ['expiration', '' . (exists $args{expiration} ? $args{expiration} : $NOW + 3600)],
        ],
        content    => exists $args{content} ? $args{content} : 'Authorize Blossom request',
    );
    $key->sign_event($event);
    return header_from_hash($event->to_hash);
}

sub token_header {
    my ($key, %args) = @_;
    return Net::Blossom::AuthToken->new(
        key        => $key,
        action     => $args{action},
        content    => 'Authorize Blossom request',
        expiration => exists $args{expiration} ? $args{expiration} : $NOW + 3600,
        hashes     => $args{hashes} || [],
        servers    => $args{servers} || [],
        created_at => exists $args{created_at} ? $args{created_at} : $NOW - 1,
    )->authorization_header;
}

sub request {
    my (%args) = @_;
    my %headers;
    $headers{Authorization} = $args{authorization} if defined $args{authorization};
    $headers{'X-SHA-256'} = $args{x_sha256} if defined $args{x_sha256};
    return Net::Blossom::Server::Request->new(
        method  => $args{method},
        path    => $args{path},
        headers => \%headers,
    );
}

sub error_status(&) {
    my ($code) = @_;
    my $error = dies { $code->() };
    isa_ok($error, 'Net::Blossom::Server::Error');
    return $error->status;
}

subtest 'constructs BUD-11 authorizer and typed errors' => sub {
    my $auth = Net::Blossom::Server::Authorization->new(
        domains => ['cdn.example.com'],
        clock   => sub { $NOW },
    );
    isa_ok($auth, 'Net::Blossom::Server::Authorization');
    is_deeply($auth->domains, ['cdn.example.com'], 'domain accessor returns copy');
    is($auth->clock_skew_seconds, 30, 'default created_at clock skew');

    my $domains = $auth->domains;
    push @$domains, 'mutated.example.com';
    is_deeply($auth->domains, ['cdn.example.com'], 'domain accessor does not alias');

    my $error = Net::Blossom::Server::Error->new(
        status  => 401,
        reason  => 'Unauthorized',
        headers => { 'WWW-Authenticate' => 'Nostr' },
    );
    is($error->status, 401, 'error status');
    is($error->reason, 'Unauthorized', 'error reason');
    is($error->header('www-authenticate'), 'Nostr', 'error header lookup');
    is($error->as_response->status, 401, 'error converts to response');

    like(dies { Net::Blossom::Server::Authorization->new(domains => 'cdn.example.com') },
        qr/domains must be an array reference/, 'domains arrayref required');
    like(dies { Net::Blossom::Server::Authorization->new(domains => ['https://cdn.example.com']) },
        qr/domain must be a lowercase domain name/, 'domain URLs rejected');
    like(dies { Net::Blossom::Server::Authorization->new(clock => 'time') },
        qr/clock must be a code reference/, 'clock coderef required');
    like(dies { Net::Blossom::Server::Authorization->new(clock_skew_seconds => -1) },
        qr/clock_skew_seconds must be a non-negative integer/, 'negative clock skew rejected');
    like(dies { Net::Blossom::Server::Authorization->new(clock_skew_seconds => '1.5') },
        qr/clock_skew_seconds must be a non-negative integer/, 'fractional clock skew rejected');
    like(dies { Net::Blossom::Server::Authorization->new(bogus => 1) },
        qr/unknown argument\(s\): bogus/, 'unknown argument rejected');
};

subtest 'authorizes implemented Blossom endpoints' => sub {
    my $key = Net::Nostr::Key->new;
    my $auth = Net::Blossom::Server::Authorization->new(
        domains => ['cdn.example.com'],
        clock   => sub { $NOW },
    );

    is($auth->authorize_request(request(
        method        => 'DELETE',
        path          => "/$SHA256",
        authorization => token_header(
            $key,
            action  => 'delete',
            hashes  => [$SHA256],
            servers => ['cdn.example.com'],
        ),
    )), $key->pubkey_hex, 'delete token returns event pubkey');

    is($auth->authorize_request(request(
        method        => 'PUT',
        path          => '/upload',
        x_sha256      => $SHA256,
        authorization => token_header($key, action => 'upload', hashes => [$SHA256]),
    )), $key->pubkey_hex, 'upload token uses X-SHA-256 hash');

    is($auth->authorize_request(request(
        method        => 'HEAD',
        path          => '/upload',
        x_sha256      => $SHA256,
        authorization => token_header($key, action => 'upload', hashes => [$SHA256]),
    )), $key->pubkey_hex, 'upload preflight token uses X-SHA-256 hash');

    is($auth->authorize_request(request(
        method        => 'GET',
        path          => "/$SHA256",
        authorization => token_header($key, action => 'get'),
    )), $key->pubkey_hex, 'get token may omit x tag');

    is($auth->authorize_request(request(
        method        => 'HEAD',
        path          => "/$SHA256.pdf",
        authorization => token_header($key, action => 'get', hashes => [$SHA256]),
    )), $key->pubkey_hex, 'head token uses URL hash without extension');

    is($auth->authorize_request(request(
        method        => 'GET',
        path          => "/list/$LIST_PUBKEY",
        authorization => token_header($key, action => 'list'),
    )), $key->pubkey_hex, 'list token does not require hash scope');

    is($auth->authorize_request(request(
        method        => 'PUT',
        path          => '/media',
        x_sha256      => $SHA256,
        authorization => token_header($key, action => 'media', hashes => [$SHA256]),
    )), $key->pubkey_hex, 'media token uses X-SHA-256 hash');

    is($auth->authorize_request(request(
        method        => 'HEAD',
        path          => '/media',
        x_sha256      => $SHA256,
        authorization => token_header($key, action => 'media', hashes => [$SHA256]),
    )), $key->pubkey_hex, 'media preflight token uses X-SHA-256 hash');
};

subtest 'authorizes fresh client AuthToken in the same second' => sub {
    my $key = Net::Nostr::Key->new;
    my $auth = Net::Blossom::Server::Authorization->new(clock => sub { $NOW });
    my $header = Net::Blossom::AuthToken->new(
        key        => $key,
        action     => 'get',
        content    => 'Authorize Blossom request',
        expiration => $NOW + 3600,
    )->authorization_header;

    my $pubkey = eval { $auth->authorize_request(request(
        method        => 'GET',
        path          => "/$SHA256",
        authorization => $header,
    )) };
    my $error = $@;

    is($error, '', 'fresh AuthToken default created_at is not rejected');
    is($pubkey, $key->pubkey_hex, 'fresh AuthToken default created_at is accepted');
};

subtest 'allows configurable created_at clock skew' => sub {
    my $key = Net::Nostr::Key->new;
    my $auth = Net::Blossom::Server::Authorization->new(clock => sub { $NOW });

    my $default_pubkey = eval { $auth->authorize_request(request(
        method        => 'GET',
        path          => "/$SHA256",
        authorization => signed_header($key, action => 'get', created_at => $NOW + 30),
    )) };
    my $default_error = $@;

    is($default_error, '', 'default leeway does not reject created_at thirty seconds ahead');
    is($default_pubkey, $key->pubkey_hex, 'default leeway accepts created_at thirty seconds ahead');

    is(error_status { $auth->authorize_request(request(
        method        => 'GET',
        path          => "/$SHA256",
        authorization => signed_header($key, action => 'get', created_at => $NOW + 31),
    )) }, 401, 'default leeway rejects created_at more than thirty seconds ahead');

    my $strict_auth = Net::Blossom::Server::Authorization->new(
        clock              => sub { $NOW },
        clock_skew_seconds => 0,
    );
    is(error_status { $strict_auth->authorize_request(request(
        method        => 'GET',
        path          => "/$SHA256",
        authorization => signed_header($key, action => 'get', created_at => $NOW),
    )) }, 401, 'zero leeway preserves strict past-only behavior');

    my $custom_auth = Net::Blossom::Server::Authorization->new(
        clock              => sub { $NOW },
        clock_skew_seconds => 5,
    );
    my $custom_pubkey = eval { $custom_auth->authorize_request(request(
        method        => 'GET',
        path          => "/$SHA256",
        authorization => signed_header($key, action => 'get', created_at => $NOW + 5),
    )) };
    my $custom_error = $@;

    is($custom_error, '', 'custom leeway does not reject created_at at its boundary');
    is($custom_pubkey, $key->pubkey_hex, 'custom leeway accepts created_at at its boundary');
    is(error_status { $custom_auth->authorize_request(request(
        method        => 'GET',
        path          => "/$SHA256",
        authorization => signed_header($key, action => 'get', created_at => $NOW + 6),
    )) }, 401, 'custom leeway rejects created_at past its boundary');
};

subtest 'returns rich authorization results for deferred mirror hash checks' => sub {
    my $key = Net::Nostr::Key->new;
    my $auth = Net::Blossom::Server::Authorization->new(
        domains => ['cdn.example.com'],
        clock   => sub { $NOW },
    );

    my $result = $auth->authorize(request(
        method        => 'PUT',
        path          => '/mirror',
        authorization => token_header(
            $key,
            action  => 'upload',
            hashes  => [$SHA256, $OTHER_SHA256],
            servers => ['cdn.example.com'],
        ),
    ));

    isa_ok($result, 'Net::Blossom::Server::AuthorizationResult');
    is($result->pubkey, $key->pubkey_hex, 'result pubkey');
    is($result->action, 'upload', 'result action');
    is_deeply($result->hashes, [$SHA256, $OTHER_SHA256], 'result hashes');
    ok($result->require_hash($OTHER_SHA256, status => 409), 'deferred mirror hash can be checked later');
};

subtest 'rejects malformed or missing authorization headers' => sub {
    my $auth = Net::Blossom::Server::Authorization->new(clock => sub { $NOW });

    is(error_status { $auth->authorize_request(request(method => 'GET', path => "/$SHA256")) },
        401, 'missing header rejected');
    is(error_status { $auth->authorize_request(request(method => 'GET', path => "/$SHA256", authorization => 'Bearer token')) },
        401, 'wrong scheme rejected');
    is(error_status { $auth->authorize_request(request(method => 'GET', path => "/$SHA256", authorization => 'Nostr ###')) },
        401, 'invalid base64url rejected');
    is(error_status { $auth->authorize_request(request(method => 'GET', path => "/$SHA256", authorization => 'Nostr bm90LWpzb24')) },
        401, 'invalid JSON rejected');
};

subtest 'rejects invalid BUD-11 events' => sub {
    my $key = Net::Nostr::Key->new;
    my $auth = Net::Blossom::Server::Authorization->new(
        domains => ['cdn.example.com'],
        clock   => sub { $NOW },
    );

    is(error_status { $auth->authorize_request(request(
        method        => 'GET',
        path          => "/$SHA256",
        authorization => signed_header($key, kind => 1, action => 'get'),
    )) }, 401, 'wrong kind rejected');

    is(error_status { $auth->authorize_request(request(
        method        => 'GET',
        path          => "/$SHA256",
        authorization => signed_header($key, action => 'get', created_at => $NOW + 31),
    )) }, 401, 'created_at beyond default clock skew rejected');

    is(error_status { $auth->authorize_request(request(
        method        => 'GET',
        path          => "/$SHA256",
        authorization => signed_header($key, action => 'get', expiration => $NOW - 1),
    )) }, 401, 'expired token rejected');

    is(error_status { $auth->authorize_request(request(
        method        => 'DELETE',
        path          => "/$SHA256",
        authorization => token_header($key, action => 'get'),
    )) }, 401, 'wrong action rejected');

    is(error_status { $auth->authorize_request(request(
        method        => 'GET',
        path          => "/$SHA256",
        authorization => token_header($key, action => 'get', servers => ['media.example.com']),
    )) }, 401, 'server scope mismatch rejected');

    my $decoded = decode_header_hash(token_header($key, action => 'get'));
    $decoded->{content} = 'tampered';
    is(error_status { $auth->authorize_request(request(
        method        => 'GET',
        path          => "/$SHA256",
        authorization => header_from_hash($decoded),
    )) }, 401, 'bad signature rejected');
};

subtest 'enforces BUD-11 hash scopes' => sub {
    my $key = Net::Nostr::Key->new;
    my $auth = Net::Blossom::Server::Authorization->new(clock => sub { $NOW });

    is(error_status { $auth->authorize_request(request(
        method        => 'PUT',
        path          => '/upload',
        authorization => signed_header($key, action => 'upload'),
    )) }, 401, 'upload without X-SHA-256 rejected');

    is(error_status { $auth->authorize_request(request(
        method        => 'PUT',
        path          => '/upload',
        x_sha256      => $SHA256,
        authorization => signed_header($key, action => 'upload'),
    )) }, 401, 'upload without x tag rejected');

    is(error_status { $auth->authorize_request(request(
        method        => 'DELETE',
        path          => "/$SHA256",
        authorization => token_header($key, action => 'delete', hashes => [$OTHER_SHA256]),
    )) }, 401, 'delete mismatched x tag rejected');

    is(error_status { $auth->authorize_request(request(
        method        => 'GET',
        path          => "/$SHA256",
        authorization => token_header($key, action => 'get', hashes => [$OTHER_SHA256]),
    )) }, 401, 'optional get x tag still scopes the token');

    is(error_status { $auth->authorize_request(request(
        method        => 'HEAD',
        path          => '/media',
        authorization => signed_header($key, action => 'media'),
    )) }, 401, 'media preflight without X-SHA-256 rejected');

    is(error_status { $auth->authorize_request(request(
        method        => 'PUT',
        path          => '/mirror',
        authorization => signed_header($key, action => 'upload'),
    )) }, 401, 'mirror without x tag rejected');

    is(error_status { $auth->authorize_request(request(
        method        => 'PUT',
        path          => '/media',
        x_sha256      => $SHA256,
        authorization => token_header($key, action => 'upload', hashes => [$SHA256]),
    )) }, 401, 'media requires media action');
};

done_testing;
