use strict;
use warnings;
use FindBin;
use Test::More;
use HTTP::Request::Common;
use Plack::Test;
use Plack::Builder;

sub decode_callback {
    my ( $token, $env ) = @_;
    return { sub => 'fake' } if $token eq 'not-a-JWT';
    die "Bad Token $token";
}
my $ok_app = sub {
    my $env = shift;

    return [ 200, [ 'Content-Type' => 'text/plain' ], ['ok'] ];
};
my $echo_app = sub {
    my $env = shift;

    return [
        200,
        [ 'Content-Type' => 'text/plain' ],
        [         'token:'
                . ( $env->{'psgix.token'} || 'none' ) . ';'
                . 'claim:'
                . ( $env->{'psgix.claims'}{sub} || 'none' )
        ]
    ];
};

subtest 'decode_callback, all defaults' => sub {

    my $handler = builder {
        enable "Plack::Middleware::Auth::JWT",
            decode_callback => \&decode_callback;
        $echo_app
    };

    test_psgi
        app    => $handler,
        client => sub {
        my $cb = shift;
        {
            subtest 'fake token via header' => sub {
                my $res = $cb->(
                    GET "http://localhost",
                    Authorization => "Bearer not-a-JWT"
                );
                is( $res->code, 200, 'status' );
                like( $res->content, qr/token:not-a-JWT/, 'psgix token' );
                like( $res->content, qr/claim:fake/,      'psgix claim' );
            };
            subtest 'fake token via param' => sub {
                my $res = $cb->( GET "http://localhost/?token=not-a-JWT" );
                is( $res->code, 200, 'status' );
                like( $res->content, qr/token:not-a-JWT/, 'psgix token' );
                like( $res->content, qr/claim:fake/,      'psgix claim' );
            };

            subtest 'missing token' => sub {
                my $res = $cb->( GET "http://localhost/?" );
                is( $res->code, 200, 'status' );
                like( $res->content, qr/token:none/, 'no psgix token' );
                like( $res->content, qr/claim:none/, 'no psgix claim' );
            };
        }
    };
};

subtest 'decode_callback, override defaults' => sub {
    my $app = sub {
        my $env = shift;

        return [
            200,
            [ 'Content-Type' => 'text/plain' ],
            [         'token:'
                    . $env->{'psgix.raw_token'} . ';'
                    . 'claim:'
                    . $env->{'psgix.tokendata'}{sub}
            ]
        ];
    };

    my $handler = builder {
        enable "Plack::Middleware::Auth::JWT",
            decode_callback   => \&decode_callback,
            token_header_name => 'Bear',
            token_query_name  => 'toktok',
            token_required    => 1,
            psgix_claims      => 'tokendata',
            psgix_token       => 'raw_token';
        $app
    };

    # and finally the tests!

    test_psgi
        app    => $handler,
        client => sub {
        my $cb = shift;
        {
            subtest 'fake token via header' => sub {
                my $res = $cb->(
                    GET "http://localhost",
                    Authorization => "bear not-a-JWT"
                );
                is( $res->code, 200, 'status' );
                like( $res->content, qr/token:not-a-JWT/, 'psgix token' );
                like( $res->content, qr/claim:fake/,      'psgix claim' );
            };
            subtest 'fake token via param' => sub {
                my $res = $cb->( GET "http://localhost/?toktok=not-a-JWT" );
                is( $res->code, 200, 'status' );
                like( $res->content, qr/token:not-a-JWT/, 'psgix token' );
                like( $res->content, qr/claim:fake/,      'psgix claim' );
            };
            subtest 'missing token, but token_required => 1' => sub {
                my $res = $cb->( GET "http://localhost/?" );
                is( $res->code, 401, 'status 401' );
            };
        }
        };
};
subtest 'decode_callback, bad token' => sub {

    my $handler = builder {
        enable "Plack::Middleware::Auth::JWT",
            decode_callback => \&decode_callback;
        $ok_app
    };

    test_psgi
        app    => $handler,
        client => sub {
        my $cb = shift;
        {
            subtest 'fake token via header' => sub {
                my $res = $cb->(
                    GET "http://localhost",
                    Authorization => "Bearer wrong-JWT"
                );
                is( $res->code, 401, 'status 401, bad token' );
            };
            subtest 'fake token via param' => sub {
                my $res = $cb->( GET "http://localhost/?token=wrong-JWT" );
                is( $res->code, 401, 'status 401, bad token' );
            };
        }
        };

};

subtest 'disallow token_query_name' => sub {

    my $handler = builder {
        enable "Plack::Middleware::Auth::JWT",
            decode_callback  => \&decode_callback,
            token_query_name => 0,
            token_required   => 1;
        $ok_app
    };

    test_psgi
        app    => $handler,
        client => sub {
        my $cb = shift;
        {
            subtest 'works via header' => sub {
                my $res = $cb->(
                    GET "http://localhost",
                    Authorization => "Bearer not-a-JWT"
                );
                is( $res->code, 200, 'status' );
            };
            subtest '401 via query' => sub {
                my $res = $cb->( GET "http://localhost/?token=not-a-JWT" );
                is( $res->code, 401, 'status 401' );
            };
            subtest '401 via query if we try 0' => sub {
                my $res = $cb->( GET "http://localhost/?0=not-a-JWT" );
                is( $res->code, 401, 'status 401' );
            };
        }
        };
};

subtest 'disallow token_header_name' => sub {

    my $handler = builder {
        enable "Plack::Middleware::Auth::JWT",
            decode_callback   => \&decode_callback,
            token_header_name => 0,
            token_required    => 1;
        $ok_app
    };

    test_psgi
        app    => $handler,
        client => sub {
        my $cb = shift;
        {
            subtest '401 via header' => sub {
                my $res = $cb->(
                    GET "http://localhost",
                    Authorization => "Bearer not-a-JWT"
                );
                is( $res->code, 401, 'status 401' );
            };
            subtest '401 via header if we try 0' => sub {
                my $res = $cb->(
                    GET "http://localhost",
                    Authorization => "0 not-a-JWT"
                );
                is( $res->code, 401, 'status 401' );
            };
            subtest 'works via query' => sub {
                my $res = $cb->( GET "http://localhost/?token=not-a-JWT" );
                is( $res->code, 200, 'status 200' );
            };
        };
        }
};


done_testing;
