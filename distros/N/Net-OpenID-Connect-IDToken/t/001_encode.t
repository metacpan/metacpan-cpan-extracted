use strict;
use Test::More;

use Net::OpenID::Connect::IDToken;
use Net::OpenID::Connect::IDToken::Constants;

my $class = "Net::OpenID::Connect::IDToken";

subtest "_generate_token_hash" => sub {
    my $token = "abcdefghijk";
    my $token_hash_1 = $class->_generate_token_hash($token, 'HS256');
    my $token_hash_2 = $class->_generate_token_hash($token, 'HS256');
    my $token_hash_3 = $class->_generate_token_hash($token, 'HS512');

    is $token_hash_1, $token_hash_2;
    isnt $token_hash_1, $token_hash_3;

    eval { $class->_generate_token_hash($token, 'AKB48') };
    is $@->code, ERROR_IDTOKEN_INVALID_ALGORITHM;
};

subtest "encode" => sub {
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

    my $id_token_1 = $class->encode($claims, $key);
    my $id_token_2 = $class->encode($claims, $key, "HS256", +{
        token => $access_token,
    });
    my $id_token_3 = encode_id_token($claims, $key, "HS256", +{
        code => $authorization_code,
    });

    note $id_token_1;
    note $id_token_2;
    note $id_token_3;

    isnt $id_token_1, $id_token_2;
    isnt $id_token_1, $id_token_3;
};

done_testing;
