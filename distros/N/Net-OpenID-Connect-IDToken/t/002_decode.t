use strict;
use Test::More;
use Test::Exception;

use Net::OpenID::Connect::IDToken;
use Net::OpenID::Connect::IDToken::Constants;

my $class = "Net::OpenID::Connect::IDToken";


subtest "decode" => sub {
    my $claims = +{
        jti   => 1,
        sub   => "http://example.owner.com/user/1",
        aud   => "http://example.client.com",
        iat   => 1234567890,
        exp   => 1234567890,
    };
    my $key = "hogehoge";
    my $access_token = "fugafuga";
    my $authorization_code = "piyopiyo";

    my $id_token = $class->encode($claims, $key, "HS256");
    my $id_token_with_hashes = $class->encode($claims, $key, "HS256", +{
        token => $access_token,
        code  => $authorization_code,
    });

    subtest "just only to decode when key is not specified" => sub {
        my $got_claims = $class->decode($id_token);
        is_deeply $got_claims, $claims;
    };

    subtest "decode and verify as JWT when key is specified" => sub {
        lives_ok {
            my $got_claims = $class->decode($id_token, $key);
            is_deeply $got_claims, $claims;
        };
    };

    subtest "decode and verify as JWT and with at_hash and c_hash when key and tokens are specified" => sub {
        lives_ok {
            my $got_claims = $class->decode($id_token_with_hashes, $key, +{
                token => $access_token,
                code  => $authorization_code,
            });
            ok $got_claims->{at_hash};
            ok $got_claims->{c_hash};
        };
    };

    subtest "decode and verify as JWT and at_hash is ..." => sub {
        subtest "not found" => sub {
            my $id_token = $class->encode($claims, $key, "HS256", +{
                code => $authorization_code,
            });
            eval {
                $class->decode($id_token, $key, +{
                    token => $access_token,
                });
            };
            is $@->code, ERROR_IDTOKEN_TOKEN_HASH_NOT_FOUND;
        };
        subtest "invalid" => sub {
            my $id_token = $class->encode($claims, $key, "HS256", +{
                token => $authorization_code,
            });
            eval {
                $class->decode($id_token, $key, +{
                    token => $access_token,
                });
            };
            is $@->code, ERROR_IDTOKEN_TOKEN_HASH_INVALID;
        };
    };

    subtest "decode and verify as JWT and c_hash is ..." => sub {
        subtest "not found" => sub {
            my $id_token = $class->encode($claims, $key, "HS256", +{
                token => $access_token,
            });
            eval {
                $class->decode($id_token, $key, +{
                    code => $authorization_code,
                });
            };
            is $@->code, ERROR_IDTOKEN_CODE_HASH_NOT_FOUND;
        };
        subtest "invalid" => sub {
            my $id_token = $class->encode($claims, $key, "HS256", +{
                code => $access_token,
            });
            eval {
                $class->decode($id_token, $key, +{
                    code => $authorization_code,
                });
            };
            is $@->code, ERROR_IDTOKEN_CODE_HASH_INVALID;
        };
    };
};

done_testing;
