use strict;
use warnings;
use FindBin;
use Test::More;
use HTTP::Request::Common;
use Plack::Test;
use Plack::Builder;
use Crypt::JWT qw(encode_jwt);

my $app = sub {
    my $env = shift;

    return [
        200,
        [ 'Content-Type' => 'text/plain' ],
        [   join( '|',
                map { $_ || 'none' } $env->{'psgix.token'},
                $env->{'psgix.claims'}{sub} )
        ]
    ];
};

my $jwt = encode_jwt(
    alg          => "HS256",
    key          => "12345",
    relative_exp => 10,
    payload      => { sub => "bart" }
);
my $jwt_bad_secret = encode_jwt(
    alg          => "HS256",
    key          => "XXXXX",
    relative_exp => 10,
    payload      => { sub => "bart" }
);
my $jwt_expired = encode_jwt(
    alg     => "HS256",
    key     => "12345",
    payload => { sub => "bart", exp => 10000 }
);
my $jwt_invalid = 'not.a.jwt';

subtest 'decode_args, all defaults' => sub {

    my $handler = builder {
        enable "Plack::Middleware::Auth::JWT",
            decode_args => { key => "12345" };
        $app
    };

    test_psgi
        app    => $handler,
        client => sub {
        my $cb = shift;
        {
            subtest 'token via header' => sub {
                my $res = $cb->(
                    GET "http://localhost",
                    Authorization => "Bearer " . $jwt
                );
                is( $res->code, 200, 'status' );
                my ( $token, $sub ) = split( /\|/, $res->content );
                is( $token, $jwt,   'psgix token' );
                is( $sub,   'bart', 'psgix claim' );
            };
            subtest 'token via param' => sub {
                my $res = $cb->( GET "http://localhost/?token=" . $jwt );
                is( $res->code, 200, 'status' );
                my ( $token, $sub ) = split( /\|/, $res->content );
                is( $token, $jwt,   'psgix token' );
                is( $sub,   'bart', 'psgix claim' );
            };
            subtest 'invalid token' => sub {
                my $res = $cb->( GET "http://localhost/?token=NotAToken" );
                is( $res->code, 401, 'status 401' );
                like($res->content,qr/invalid token/,'error message');
            };

            subtest 'missing token' => sub {
                my $res = $cb->( GET "http://localhost/?" );
                is( $res->code, 200, 'status' );
                my ( $token, $sub ) = split( /\|/, $res->content );
                is( $token, 'none', 'no token' );
                is( $sub,   'none', 'no claim' );
            };
        }
    };
};

subtest 'decode_args, token required' => sub {
    my $handler = builder {
        enable "Plack::Middleware::Auth::JWT",
            decode_args    => { key => "12345" },
            token_required => 1;
        $app
    };

    test_psgi
        app    => $handler,
        client => sub {
        my $cb = shift;
        {
            subtest 'token via header' => sub {
                my $res = $cb->(
                    GET "http://localhost",
                    Authorization => "Bearer " . $jwt
                );
                is( $res->code, 200, 'status' );
                my ( $token, $sub ) = split( /\|/, $res->content );
                is( $token, $jwt,   'psgix token' );
                is( $sub,   'bart', 'psgix claim' );
            };
            subtest 'token via param' => sub {
                my $res = $cb->( GET "http://localhost/?token=" . $jwt );
                is( $res->code, 200, 'status' );
                my ( $token, $sub ) = split( /\|/, $res->content );
                is( $token, $jwt,   'psgix token' );
                is( $sub,   'bart', 'psgix claim' );
            };

            subtest 'missing token, but token_required => 1' => sub {
                my $res = $cb->( GET "http://localhost/?" );
                is( $res->code, 401, 'status 401' );
            };
        }
    };
};

subtest 'decode_args, ignore invalid token' => sub {
    my $handler = builder {
        enable "Plack::Middleware::Auth::JWT",
            decode_args    => { key => "12345" },
            ignore_invalid_token => 1;
        $app
    };

    test_psgi
        app    => $handler,
        client => sub {
        my $cb = shift;
        {
            subtest 'valid token via header' => sub {
                my $res = $cb->(
                    GET "http://localhost",
                    Authorization => "Bearer " . $jwt
                );
                is( $res->code, 200, 'status' );
                my ( $token, $sub ) = split( /\|/, $res->content );
                is( $token, $jwt,   'psgix token' );
                is( $sub,   'bart', 'psgix claim' );
            };
            subtest 'invalid token via header' => sub {
                my $res = $cb->(
                    GET "http://localhost",
                    Authorization => "Bearer NotAToken"
                );
                is( $res->code, 200, 'status 200, even though token is invalid' );
                my ( $token, $sub ) = split( /\|/, $res->content );
                is( $token, 'none',   'no psgix token' );
                is( $sub,   'none', 'no psgix claim' );
            };
         }
    };
};

subtest 'some bad tokens' => sub {
    my $handler = builder {
        enable "Plack::Middleware::Auth::JWT",
            decode_args => { key => "12345" };
        $app
    };

    test_psgi
        app    => $handler,
        client => sub {
        my $cb = shift;
        {
            subtest 'bad secret' => sub {
                my $res = $cb->(
                    GET "http://localhost",
                    Authorization => "Bearer " . $jwt_bad_secret
                );
                is( $res->code, 401, 'status 401' );
                like( $res->content, qr/decode failed/, 'cannot decode' );
            };

            subtest 'expired token' => sub {
                my $res = $cb->(
                    GET "http://localhost",
                    Authorization => "Bearer " . $jwt_expired
                );
                is( $res->code, 401, 'status 401' );
                like(
                    $res->content,
                    qr/exp claim check failed/,
                    'exp claim check failed'
                );
            };

            subtest 'not a JWT' => sub {
                my $res = $cb->(
                    GET "http://localhost",
                    Authorization => "Bearer " . $jwt_invalid
                );
                is( $res->code, 401, 'status 401' );
                like(
                    $res->content,
                    qr/invalid header part/,
                    'cannot decode'
                );
            };
        }
    };
};

subtest 'some more Crypt::JWT args' => sub {
    my $handler = builder {
        enable "Plack::Middleware::Auth::JWT",
            decode_args => {
            key        => "12345",
            verify_exp => 0,
            verify_nbf => 1,
            };
        $app
    };

    test_psgi
        app    => $handler,
        client => sub {
        my $cb = shift;
        {
            my $jwt = encode_jwt(
                alg          => "HS256",
                key          => "12345",
                relative_nbf => 10,
                relative_exp => 10,
                payload      => { sub => "bart" }
            );
            subtest 'not-before' => sub {
                my $res = $cb->(
                    GET "http://localhost",
                    Authorization => "Bearer " . $jwt
                );
                is( $res->code, 401, 'status 401' );
                like(
                    $res->content,
                    qr/nbf claim check failed/,
                    'cannot decode'
                );
            };

        }
    };

    test_psgi
        app    => $handler,
        client => sub {
        my $cb = shift;
        {
            my $jwt = encode_jwt(
                alg          => "HS256",
                key          => "12345",
                relative_exp => -10,
                relative_nbf => -10,
                payload      => { sub => "bart" }
            );
            subtest 'exp ignored' => sub {
                my $res = $cb->(
                    GET "http://localhost",
                    Authorization => "Bearer " . $jwt
                );
                is( $res->code, 200, 'status 200' );
            };
        }
    };

    test_psgi
        app    => $handler,
        client => sub {
        my $cb = shift;
        {
            my $jwt = encode_jwt(
                alg          => "HS256",
                key          => "12345",
                relative_exp => 4,
                relative_nbf => 4,
                payload      => { sub => "bart" }
            );
            subtest 'nbf inside leeway' => sub {
                my $res = $cb->(
                    GET "http://localhost",
                    Authorization => "Bearer " . $jwt
                );
                is( $res->code, 200, 'status 200' );
            };
        }
    };

    test_psgi
        app    => $handler,
        client => sub {
        my $cb = shift;
        {
            my $jwt = encode_jwt(
                alg          => "HS256",
                key          => "12345",
                relative_exp => 4,
                relative_nbf => 6,
                payload      => { sub => "bart" }
            );
            subtest 'nbf outside leeway' => sub {
                my $res = $cb->(
                    GET "http://localhost",
                    Authorization => "Bearer " . $jwt
                );
                is( $res->code, 401, 'status 401' );
                like(
                    $res->content,
                    qr/nbf claim check failed/,
                    'cannot decode'
                );
            };
        }
    };
};

done_testing;
