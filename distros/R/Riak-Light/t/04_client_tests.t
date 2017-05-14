use Test::More tests => 7;
use Test::Exception;
use Test::MockObject;
use Riak::Light;
use Riak::Light::PBC;
use POSIX qw(ETIMEDOUT strerror);
use JSON;

subtest "error handling" => sub {
    plan tests => 1;

    dies_ok {
        Riak::Light->new( host => 'not.exist', port => 9999 );
    };
};

subtest "exists" => sub {
    plan tests => 2;

    subtest "should return false if the key does not exist" => sub {
        plan tests => 1;
        my $mock = Test::MockObject->new;

        my $mock_response = {
            error => undef,
            code  => 10,
            body  => RpbGetResp->encode( { content => undef } )
        };

        $mock->set_true('perform_request');
        $mock->set_always( read_response => $mock_response );

        my $client = Riak::Light->new(
            host   => 'host', port => 1234, autodie => 1,
            driver => $mock
        );

        ok( !$client->exists( foo => "bar" ) );
    };
    subtest "should return true if the key exist" => sub {
        plan tests => 1;
        my $mock = Test::MockObject->new;

        my $mock_response = {
            error => undef,
            code  => 10,
            body  => RpbGetResp->encode(
                {   content => {
                        value        => q(),
                        content_type => 'application/json'
                    }
                }
            )
        };

        $mock->set_true('perform_request');
        $mock->set_always( read_response => $mock_response );

        my $client = Riak::Light->new(
            host   => 'host', port => 1234, autodie => 1,
            driver => $mock
        );

        ok( $client->exists( foo => "bar" ) );
    };
};

subtest "ping" => sub {
    plan tests => 5;

    subtest "pong should return true in case of sucess" => sub {
        plan tests => 2;
        my $mock = Test::MockObject->new;

        my $mock_response = {
            code => 2,
            body => q()
        };

        $mock->set_true('perform_request');
        $mock->set_always( read_response => $mock_response );


        my $client = Riak::Light->new(
            host   => 'host', port => 1234, autodie => 1,
            driver => $mock
        );

        ok $client->ping(),     "should return true";
        ok $client->is_alive(), "should return true";
    };

    subtest "ping/is_alive should die in case of internal error" => sub {
        plan tests => 2;
        my $mock = Test::MockObject->new;

        $mock->set_true('perform_request');
        $mock->set_false('read_response');

        my $client = Riak::Light->new(
            host   => 'host', port => 1234, autodie => 1,
            driver => $mock
        );

        $! = ETIMEDOUT;
        my $errmsg = strerror(ETIMEDOUT);
        throws_ok { $client->ping() } qr/Error in 'ping' : $errmsg/,
          "should die";
        lives_ok { $client->is_alive() } "Should not die";
    };

    subtest "ping should die in case of riak error" => sub {
        plan tests => 1;
        my $mock = Test::MockObject->new;

        my $mock_response = {
            error => undef,
            code  => 0,
            body  => RpbErrorResp->encode(
                { errmsg => "some riak error", errcode => 123 }
            )
        };

        $mock->set_true('perform_request');
        $mock->set_always( read_response => $mock_response );

        my $client = Riak::Light->new(
            host   => 'host', port => 1234, autodie => 1,
            driver => $mock
        );

        throws_ok { $client->ping() }
        qr/Error in 'ping' : Riak Error \(code: 123\) 'some riak error'/,
          "should die";
    };

    subtest "ping should die in case of unexpected response" => sub {
        plan tests => 1;
        my $mock = Test::MockObject->new;

        my $mock_response = {
            error => undef,
            code  => 10,
            body  => q()
        };

        $mock->set_true('perform_request');
        $mock->set_always( read_response => $mock_response );

        my $client = Riak::Light->new(
            host   => 'host', port => 1234, autodie => 1,
            driver => $mock
        );

        throws_ok { $client->ping() }
        qr/Error in 'ping' : Unexpected Response Code in \(got: 10, expected: 2\)/,
          "should die";
    };

    subtest "ping should die in case of can't send the request" => sub {
        plan tests => 1;
        my $mock = Test::MockObject->new;

        my $mock_response = {
            error => undef,
            code  => 10,
            body  => q()
        };

        $! = ETIMEDOUT;
        $mock->set_false('perform_request');

        my $client = Riak::Light->new(
            host   => 'host', port => 1234, autodie => 1,
            driver => $mock
        );

        my $errmsg = strerror(ETIMEDOUT);
        throws_ok { $client->ping() }
        qr/Error in 'ping' : $errmsg/,
          "should die";
    };
};

subtest "get" => sub {
    plan tests => 5;

    subtest "get fetch simple value " => sub {
        plan tests => 2;
        my $mock = Test::MockObject->new;

        my $hash = { lol => 123 };

        my $mock_response = {
            error => undef,
            code  => 10,
            body  => RpbGetResp->encode(
                {   content => {
                        value        => encode_json($hash),
                        content_type => 'application/json'
                    }
                }
            )
        };

        $mock->set_true('perform_request');
        $mock->set_always( read_response => $mock_response );

        my $client = Riak::Light->new(
            host   => 'host', port => 1234, autodie => 1,
            driver => $mock
        );

        is_deeply(
            $client->get( foo => "bar" ), $hash,
            "should return the same structure"
        );

        is_deeply(
            decode_json( $client->get_raw( foo => "bar" ) ), $hash,
            "should return the same structure"
        );
    };

    subtest "get fetch simple text/plain value " => sub {
        plan tests => 2;
        my $mock = Test::MockObject->new;

        my $text = "LOL";

        my $mock_response = {
            error => undef,
            code  => 10,
            body  => RpbGetResp->encode(
                {   content => {
                        value        => $text,
                        content_type => 'text/plain'
                    }
                }
            )
        };

        $mock->set_true('perform_request');
        $mock->set_always( read_response => $mock_response );

        my $client = Riak::Light->new(
            host   => 'host', port => 1234, autodie => 1,
            driver => $mock
        );

        is( $client->get( foo => "bar" ), $text,
            "should return the same structure"
        );
        is( $client->get_raw( foo => "bar" ), $text,
            "should return the same structure"
        );
    };

    subtest "get fetch undef value" => sub {
        plan tests => 1;
        my $mock = Test::MockObject->new;

        my $mock_response = {
            error => undef,
            code  => 10,
            body  => RpbGetResp->encode( { content => undef } )
        };

        $mock->set_true('perform_request');
        $mock->set_always( read_response => $mock_response );

        my $client = Riak::Light->new(
            host   => 'host', port => 1234, autodie => 1,
            driver => $mock
        );

        ok( !$client->get( foo => "bar" ), "should return nothing" );
    };

    subtest "get fetch undef body should die" => sub {
        plan tests => 1;
        my $mock = Test::MockObject->new;

        my $mock_response = {
            error => undef,
            code  => 10,
            body  => undef
        };

        $mock->set_true('perform_request');
        $mock->set_always( read_response => $mock_response );

        my $client = Riak::Light->new(
            host   => 'host', port => 1234, autodie => 1,
            driver => $mock
        );

        throws_ok { $client->get( foo => "bar" ) }
        qr/Error in 'get' \(bucket: foo, key: bar\): Undefined Message/,
          "should return nothing";
    };

    subtest "get fetch dies in case of error" => sub {
        plan tests => 1;
        my $mock = Test::MockObject->new;

        my $mock_response = { error => "some error" };

        $mock->set_true('perform_request');
        $mock->set_always( read_response => $mock_response );

        my $client = Riak::Light->new(
            host   => 'host', port => 1234, autodie => 1,
            driver => $mock
        );

        throws_ok { $client->get( foo => "bar" ) }
        qr/Error in 'get' \(bucket: foo, key: bar\): some error/, "should die";
    };
};
subtest "put" => sub {
    plan tests => 3;

    subtest "put simple data " => sub {
        plan tests => 2;
        my $mock = Test::MockObject->new;

        my $mock_response = {
            error => undef,
            code  => 12,
            body  => q()
        };

        $mock->set_true('perform_request');
        $mock->set_always( read_response => $mock_response );

        my $client = Riak::Light->new(
            host   => 'host', port => 1234, autodie => 1,
            driver => $mock
        );

        my $scalar = '3.14159';
        my $hash = { foo => 123 };
        ok( $client->put( foo => "bar", $hash ), "should store data" );
        ok( $client->put_raw( foo => "bar", $scalar ), "should store data" );
    };

    subtest "put simple data in other encoding" => sub {
        plan tests => 2;
        my $mock = Test::MockObject->new;

        my $mock_response = {
            error => undef,
            code  => 12,
            body  => q()
        };

        $mock->set_true('perform_request');
        $mock->set_always( read_response => $mock_response );

        my $client = Riak::Light->new(
            host   => 'host', port => 1234, autodie => 1,
            driver => $mock
        );

        my $scalar = '3.14159';
        my $hash = { foo => 123 };
        ok( $client->put( foo => "bar", $scalar, 'text/plain' ),
            "should store data"
        );
        ok( $client->put_raw(
                foo => "bar", encode_json($hash), 'application/json'
            ),
            "should store data"
        );
    };


    subtest "put should die in case of error " => sub {
        plan tests => 1;
        my $mock = Test::MockObject->new;

        my $mock_response = { error => "some error" };

        $mock->set_true('perform_request');
        $mock->set_always( read_response => $mock_response );

        my $client = Riak::Light->new(
            host   => 'host', port => 1234, autodie => 1,
            driver => $mock
        );
        my $hash = { foo => 123 };
        throws_ok { $client->put( foo => "bar", $hash ) }
        qr/Error in 'put' \(bucket: foo, key: bar\): some error/, "should die";
    };
};
subtest "del" => sub {
    plan tests => 2;

    subtest "del simple data " => sub {
        plan tests => 1;
        my $mock = Test::MockObject->new;

        my $mock_response = {
            error => undef,
            code  => 14,
            body  => q()
        };

        $mock->set_true('perform_request');
        $mock->set_always( read_response => $mock_response );

        my $client = Riak::Light->new(
            host   => 'host', port => 1234, autodie => 1,
            driver => $mock
        );

        ok( $client->del( foo => "bar" ), "should delete data" );
    };

    subtest "del should die in case of error " => sub {
        plan tests => 1;
        my $mock = Test::MockObject->new;

        my $mock_response = { error => "some error" };

        $mock->set_true('perform_request');
        $mock->set_always( read_response => $mock_response );

        my $client = Riak::Light->new(
            host   => 'host', port => 1234, autodie => 1,
            driver => $mock
        );

        throws_ok { $client->del( foo => "bar" ) }
        qr/Error in 'del' \(bucket: foo, key: bar\): some error/, "should die";
    };
};

subtest "get_keys" => sub {
    plan tests => 3;

    subtest "should throw error" => sub {
        plan tests => 1;
        my $mock = Test::MockObject->new;

        my $mock_response = {
            error => "ops",
            code  => -1,
            body  => undef
        };

        $mock->set_true('perform_request');
        $mock->set_always( 'read_response', $mock_response );

        my $client = Riak::Light->new(
            host   => 'host', port => 1234, autodie => 1,
            driver => $mock
        );

        throws_ok {
            $client->get_keys(
                foo => sub {
                    fail("should not be called");
                }
            );
        }
        qr/Error in 'get_keys' \(bucket: foo, key: \*\): ops/;
    };


    subtest "get no keys" => sub {
        plan tests => 1;
        my $mock = Test::MockObject->new;

        my $mock_response = {
            error => undef,
            code  => 18,
            body  => RpbListKeysResp->encode( { keys => [], done => 1 } )
        };

        $mock->set_true('perform_request');
        $mock->set_always( 'read_response', $mock_response );

        my $client = Riak::Light->new(
            host   => 'host', port => 1234, autodie => 1,
            driver => $mock
        );

        my @keys;
        $client->get_keys(
            foo => sub {
                fail("should not be called");
            }
        );

        is( scalar @keys, 0 );
    };

    subtest "simple retrieve" => sub {
        plan tests => 3;
        my $mock = Test::MockObject->new;

        my $mock_response1 = {
            error => undef,
            code  => 18,
            body  => RpbListKeysResp->encode( { keys => [ 1, 2 ], done => 0 } )
        };

        my $mock_response2 = {
            error => undef,
            code  => 18,
            body  => RpbListKeysResp->encode( { keys => [], done => 1 } )
        };

        $mock->set_true('perform_request');
        $mock->set_series( 'read_response', $mock_response1, $mock_response2 );

        my $client = Riak::Light->new(
            host   => 'host', port => 1234, autodie => 1,
            driver => $mock
        );

        my @keys;
        $client->get_keys(
            foo => sub {
                push @keys, $_[0];
            }
        );
        @keys = sort @keys;

        is( scalar @keys, 2 );
        is( $keys[0],     1 );
        is( $keys[1],     2 );
    };
};
