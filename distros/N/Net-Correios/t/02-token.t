use strict;
use warnings;

use Test2::V0;
use JSON ();
use MIME::Base64 ();

use Net::Correios;

plan 14;

my $api = Net::Correios->new( username => 'foo', password => 'bar' );
can_ok $api, 'token';

ok my $token = $api->token, 'got the token object';;
isa_ok $token, 'Net::Correios::Token';

can_ok $token, 'autentica';
my $response_data = {
    ambiente   => 'PRODUCAO',
    cnpj       => '11111111000111',
    emissao    => '2023-09-21T14:40:03',
    expiraEm   => '2023-09-22T14:40:03',
    id         => 'myusername',
    ip         => '192.168.1.1,192.168.1.2',
    perfil     => 'PJ',
    token      => 'thisISaMOCk3dT0k3N.weUSE1tf0RtESt1nGTheACtu4lOn3ISmUChbiGG3R',
    zoneOffset => '-03:00',
};

my $mocked_ua = mock 'HTTP::Tiny' => (
  override => [
    request => sub {
      my ($self, $method, $url, $args) = @_;
      is $method, 'POST', 'proper token method';
      is $url, 'https://api.correios.com.br/token/v1/autentica', 'proper token url';
      is $args, { headers => { Authorization => 'Basic Zm9vOmJhcg==' } }, 'proper header';
      return { success => 1, content => JSON::encode_json($response_data) };
    }
  ],
);

my $res = $token->autentica();
is $res, $response_data, 'properly decoded data from API';

# the mock above is only for autentica() itself. restore the original
# HTTP::Tiny::request before testing the token cache.
undef $mocked_ua;

subtest 'access_token reuses a valid cached token' => sub {
    my $api = Net::Correios->new(
        username => 'foo',
        password => 'bar',
        cartao   => '1234',
        contrato => '4321',
    );
    $api->{token_cartao}         = 'cached-token';
    $api->{token_expires_cartao} = time + 3600;

    my $requests = 0;
    my $mocked = mock 'HTTP::Tiny' => (
        override => [
            request => sub { $requests++; return { success => 0, status => 500 } },
        ],
    );

    is $api->access_token('cartao'), 'cached-token', 'returns the cached token';
    is $requests, 0, 'no HTTP request was made';
};

subtest 'access_token trusts a token with no expiration info' => sub {
    my $api = Net::Correios->new(
        username => 'foo',
        password => 'bar',
        cartao   => '1234',
        contrato => '4321',
    );
    $api->{token_cartao} = 'hand-set-token';

    my $requests = 0;
    my $mocked = mock 'HTTP::Tiny' => (
        override => [
            request => sub { $requests++; return { success => 0, status => 500 } },
        ],
    );

    is $api->access_token('cartao'), 'hand-set-token', 'returns the hand-set token';
    is $requests, 0, 'no HTTP request was made';
};

subtest 'access_token renews an expired token' => sub {
    my $api = Net::Correios->new(
        username => 'foo',
        password => 'bar',
        cartao   => '1234',
        contrato => '4321',
    );
    $api->{token_cartao}         = 'stale-token';
    $api->{token_expires_cartao} = time - 1;

    my $expires = time + 86400;
    my $fresh   = _fake_jwt(exp => $expires);

    my $requests = 0;
    my $mocked = mock 'HTTP::Tiny' => (
        override => [
            request => sub {
                my ($self, $method, $url, $args) = @_;
                $requests++;
                is $method, 'POST', 'token request method';
                is $url, 'https://api.correios.com.br/token/v1/autentica/cartaopostagem', 'token request url';
                is $args->{headers}{Authorization}, 'Basic Zm9vOmJhcg==', 'basic auth header';
                return {
                    success => 1,
                    status  => 201,
                    content => JSON::encode_json({ token => $fresh }),
                };
            },
        ],
    );

    is $api->access_token('cartao'), $fresh, 'returns the renewed token';
    is $requests, 1, 'token endpoint was called once';
    is $api->{token_expires_cartao}, $expires, 'expiration taken from the JWT exp claim';
};

subtest 'make_request refreshes and retries once on expired token' => sub {
    my $api = Net::Correios->new(
        username => 'foo',
        password => 'bar',
        cartao   => '1234',
        contrato => '4321',
    );
    my $old_token = _fake_jwt(exp => time + 3600);
    my $new_token = _fake_jwt(exp => time + 86400);
    $api->{token_cartao}         = $old_token;
    $api->{token_expires_cartao} = time + 3600;

    my (@sent_auth, $token_calls);
    $token_calls = 0;
    my $mocked = mock 'HTTP::Tiny' => (
        override => [
            request => sub {
                my ($self, $method, $url, $args) = @_;
                if ($url =~ m{/token/v1/autentica}) {
                    $token_calls++;
                    return {
                        success => 1,
                        status  => 201,
                        content => JSON::encode_json({ token => $new_token }),
                    };
                }
                push @sent_auth, $args->{headers}{Authorization};
                if (@sent_auth == 1) {
                    return {
                        success => 0,
                        status  => 403,
                        content => '{"msgs":["GTW-007: Token expirado."]}',
                    };
                }
                return { success => 1, status => 200, content => '{"ok":true}' };
            },
        ],
    );

    my $res = $api->make_request('cartao', 'GET', 'srorastro/v1/objetos');
    is $res->{status}, 200, 'retried request succeeded';
    is \@sent_auth, [ 'Bearer ' . $old_token, 'Bearer ' . $new_token ],
        'retried with the renewed token';
    is $token_calls, 1, 'token was refreshed exactly once';
};

subtest 'make_request does not retry other 401/403 errors' => sub {
    my $api = Net::Correios->new(
        username => 'foo',
        password => 'bar',
        cartao   => '1234',
        contrato => '4321',
    );
    $api->{token_cartao} = 'some-token';

    foreach my $case (
        { status => 403, content => '{"msgs":["PPN-202: Destinatário inválido."]}' },
        { status => 403, content => '{"msgs":["GTW-006: Token inválido."]}' },
        { status => 401, content => '' },
    ) {
        my $requests = 0;
        my $mocked = mock 'HTTP::Tiny' => (
            override => [
                request => sub {
                    $requests++;
                    return { success => 0, %$case };
                },
            ],
        );

        my $res = $api->make_request('cartao', 'GET', 'prepostagem/v1/prepostagens');
        is $res->{status}, $case->{status}, "returns the $case->{status} response";
        is $requests, 1, 'request was not retried';
    }
};

subtest 'make_request retries only once' => sub {
    my $api = Net::Correios->new(
        username => 'foo',
        password => 'bar',
        cartao   => '1234',
        contrato => '4321',
    );
    $api->{token_cartao} = 'stale-token';

    my $requests = 0;
    my $token_calls = 0;
    my $mocked = mock 'HTTP::Tiny' => (
        override => [
            request => sub {
                my ($self, $method, $url) = @_;
                $requests++;
                if ($url =~ m{/token/v1/autentica}) {
                    $token_calls++;
                    return {
                        success => 1,
                        status  => 201,
                        content => JSON::encode_json({ token => 'another-token' }),
                    };
                }
                return {
                    success => 0,
                    status  => 403,
                    content => '{"msgs":["GTW-007: Token expirado."]}',
                };
            },
        ],
    );

    my $res = $api->make_request('cartao', 'GET', 'srorastro/v1/objetos');
    is $res->{status}, 403, 'returns the second failure';
    is $requests, 3, 'two API calls plus a single token refresh';
    is $token_calls, 1, 'token was refreshed exactly once';
};

# builds a token that looks like the JWTs returned by Correios.
sub _fake_jwt {
    my (%claims) = @_;
    my $encode = sub {
        my $b64 = MIME::Base64::encode_base64(JSON::encode_json($_[0]), '');
        $b64 =~ tr{+/}{-_}; # base64url
        $b64 =~ s/=+\z//;
        return $b64;
    };
    return $encode->({ alg => 'RS512', typ => 'JWT' })
         . '.' . $encode->(\%claims)
         . '.signature';
}
