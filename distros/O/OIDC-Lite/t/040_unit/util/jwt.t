use strict;
use warnings;

use Test::More;
use JSON::WebToken;
use OIDC::Lite::Util::JWT;
use JSON::XS qw/decode_json encode_json/;

TEST_HEADER: {
    my %header =    (
                        typ => 'JWS',
                        alg => 'HS256',
                    );
    my %payload =   (
                        foo => 'bar'
                    );
    my $key = '';
    my $jwt = JSON::WebToken->encode(\%payload, $key, $header{alg}, \%header);
    my $decode_header = OIDC::Lite::Util::JWT::header($jwt);
    is( $decode_header->{typ}, q{JWS});
    is( $decode_header->{alg}, q{HS256});
    my $decode_payload = OIDC::Lite::Util::JWT::payload($jwt);
    is( $decode_payload->{foo}, q{bar});
    ok( !OIDC::Lite::Util::JWT::header('invalid_jwt') );
    ok( !OIDC::Lite::Util::JWT::header('invalid_header.invalid_payload.') );
};

TEST_PAYLOAD: {
    my %header =    (
                        typ => 'JWS',
                        alg => 'HS256',
                    );
    my %payload =   (
                        foo => 'bar'
                    );
    my $key = '';
    my $jwt = JSON::WebToken->encode(\%payload, $key, $header{alg}, \%header);
    is(encode_json(OIDC::Lite::Util::JWT::payload($jwt)), encode_json(\%payload));
    ok( !OIDC::Lite::Util::JWT::payload('invalid_jwt') );
    ok( !OIDC::Lite::Util::JWT::payload('invalid_header.invalid_payload.') );
};

done_testing;
