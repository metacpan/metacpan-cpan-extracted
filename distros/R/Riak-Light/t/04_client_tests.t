use Test::More tests => 10;
use Test::Exception;
use Test::MockObject;
use Riak::Light;
use Riak::Light::PBC;
use POSIX qw(ETIMEDOUT strerror);
use JSON;

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

subtest "vclock" => sub {
    plan tests                         => 3;
    subtest "should return the vclock" => sub {
        plan tests => 1;
        my $mock = Test::MockObject->new;

        my $mock_response = {
            error => undef,
            code  => 10,
            body  => RpbGetResp->encode(
                {   content => {
                        value        => encode_json( { foo => 1 } ),
                        content_type => 'application/json',
                    },
                    vclock => 12345,
                }
            )
        };

        $mock->set_true('perform_request');
        $mock->set_always( read_response => $mock_response );

        my $client = Riak::Light->new(
            host   => 'host', port => 1234, autodie => 1,
            driver => $mock
        );

        is( $client->get_vclock( foo => "bar" ), 12345,
            "should return the same vclock"
        );
    };

    subtest "should return the vclock in get_full" => sub {
        plan tests => 1;
        my $mock = Test::MockObject->new;

        my $mock_response = {
            error => undef,
            code  => 10,
            body  => RpbGetResp->encode(
                {   content => {
                        value        => encode_json( { foo => 1 } ),
                        content_type => 'application/json',
                        indexes => [ { key => 'foo_int', value => 1 } ]
                    },
                    vclock => 12345,
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
            $client->get_full( foo => "bar" ),
            {   value => { foo => 1 },
                indexes => [ { key => 'foo_int', value => 1 } ],
                vclock  => 12345
            },
            "should return the same vclock"
        );
    };

    subtest "should return the vclock in get_full_raw" => sub {
        plan tests => 1;
        my $mock = Test::MockObject->new;

        my $mock_response = {
            error => undef,
            code  => 10,
            body  => RpbGetResp->encode(
                {   content => {
                        value        => encode_json( { foo => 1 } ),
                        content_type => 'application/json',
                        indexes => [ { key => 'foo_int', value => 1 } ]
                    },
                    vclock => 12345,
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
            $client->get_full_raw( foo => "bar" ),
            {   value => encode_json { foo => 1 },
                indexes => [ { key => 'foo_int', value => 1 } ],
                vclock  => 12345
            },
            "should return the same vclock"
        );
    };
};

subtest 'get_all_indexes' => sub {
    plan tests                    => 2;
    subtest 'should list indexes' => sub {
        plan tests => 1;
        my $mock = Test::MockObject->new;

        my $mock_response = {
            error => undef,
            code  => 10,
            body  => RpbGetResp->encode(
                {   content => {
                        value        => encode_json( { foo => 1 } ),
                        content_type => 'application/json',
                        indexes      => [
                            { key => 'foo_int', value => 1 },
                            { key => 'foo_int', value => 2 },
                            { key => 'foo_bin', value => 'bar' },
                        ],
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
            $client->get_all_indexes( foo => "bar" ),
            [   { key => 'foo_int', value => 1 },
                { key => 'foo_int', value => 2 },
                { key => 'foo_bin', value => 'bar' },
            ],
            "should return the same structure"
        );
    };

    subtest 'should not list indexes if it is missing' => sub {
        plan tests => 1;
        my $mock = Test::MockObject->new;

        my $mock_response = {
            error => undef,
            code  => 10,
            body  => RpbGetResp->encode(
                {   content => {
                        value        => encode_json( { foo => 1 } ),
                        content_type => 'application/json',
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
            $client->get_all_indexes( foo => "bar" ), [],
            "should return the empty structure"
        );
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


subtest "query_index" => sub {
    plan tests => 5;

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
            $client->query_index( foo => bar => 1 );
        }
        qr/Error in 'query_index' \(bucket: foo, 2i query on index='bar' => 1\): ops/;
    };


    subtest "get no keys" => sub {
        plan tests => 1;
        my $mock = Test::MockObject->new;

        my $mock_response = {
            error => undef,
            code  => 26,
            body  => RpbIndexResp->encode(
                { keys => [], done => undef, continuation => undef }
            )
        };

        $mock->set_true('perform_request');
        $mock->set_always( 'read_response', $mock_response );

        my $client = Riak::Light->new(
            host   => 'host', port => 1234, autodie => 1,
            driver => $mock
        );

        my $keys = $client->query_index( foo => bar => 1 );

        is( scalar @{$keys}, 0 );
    };

    subtest "simple retrieve" => sub {
        plan tests => 2;
        my $mock = Test::MockObject->new;

        my $mock_response = {
            error => undef,
            code  => 26,
            body  => RpbIndexResp->encode(
                { keys => [ 1, 2, 3 ], done => undef, continuation => undef }
            )
        };

        $mock->set_true('perform_request');
        $mock->set_always( 'read_response', $mock_response );

        my $client = Riak::Light->new(
            host   => 'host', port => 1234, autodie => 1,
            driver => $mock
        );

        my $keys = $client->query_index( foo => bar => 1 );

        is scalar @{$keys}, 3;
        is_deeply [ sort @{$keys} ], [ 1, 2, 3 ];
    };

    subtest "simple retrieve (wantarray)" => sub {
        plan tests => 11;
        my $mock = Test::MockObject->new;

        my $mock_response = {
            error => undef,
            code  => 26,
            body  => RpbIndexResp->encode(
                { keys => [ 1, 2, 3 ], done => 0, continuation => 'foo' }
            )
        };

        $mock->set_true('perform_request');
        $mock->set_always( 'read_response', $mock_response );

        my $client = Riak::Light->new(
            host   => 'host', port => 1234, autodie => 1,
            driver => $mock
        );

        my ( $keys, $continuation, $done ) =
          $client->query_index( foo => bar => 1, { max_results => 1024 } );

        is_deeply [ sort @{$keys} ], [ 1, 2, 3 ];
        is $continuation, 'foo';
        is $done,         0;
        my ( $name, $args ) = $mock->next_call();

        is $name, 'perform_request', 'call perform_request';
        my ( undef, %hash ) = @{$args};

        my $request = RpbIndexReq->decode( $hash{body} );

        is $request->index,        'bar';
        is $request->bucket,       'foo';
        is $request->key,          1;
        is $request->qtype,        0;
        is $request->max_results,  1024;
        is $request->continuation, undef;

        $mock->called_ok('read_response');
    };

    subtest "query_index_loop" => sub {
        plan tests => 18;
        my $mock = Test::MockObject->new;

        my $mock_response1 = {
            error => undef,
            code  => 26,
            body  => RpbIndexResp->encode(
                { keys => [ 1, 2 ], done => 0, continuation => 'foo' }
            )
        };

        my $mock_response2 = {
            error => undef,
            code  => 26,
            body  => RpbIndexResp->encode(
                { keys => [ 3, 4 ], done => 1, continuation => undef }
            )
        };

        $mock->set_true('perform_request');
        $mock->set_series( 'read_response', $mock_response1, $mock_response2 );

        my $client = Riak::Light->new(
            host   => 'host', port => 1234, autodie => 1,
            driver => $mock
        );

        my $keys = $client->query_index_loop( foo => bar => 1 );

        is scalar @{$keys}, 4;
        is_deeply [ sort @{$keys} ], [ 1, 2, 3, 4 ];

        my ( $name, $args ) = $mock->next_call();

        is $name, 'perform_request', 'call perform_request';
        my ( undef, %hash ) = @{$args};

        my $request = RpbIndexReq->decode( $hash{body} );

        is $request->index,        'bar';
        is $request->bucket,       'foo';
        is $request->key,          1;
        is $request->qtype,        0;
        is $request->max_results,  100;
        is $request->continuation, undef;

        ( $name, $args ) = $mock->next_call();
        is $name, 'read_response', 'call perform_request';

        ( $name, $args ) = $mock->next_call();

        is $name, 'perform_request', 'call perform_request again';
        ( undef, %hash ) = @{$args};

        $request = RpbIndexReq->decode( $hash{body} );

        is $request->index,        'bar';
        is $request->bucket,       'foo';
        is $request->key,          1;
        is $request->qtype,        0;
        is $request->max_results,  100;
        is $request->continuation, 'foo';

        ( $name, $args ) = $mock->next_call();
        is $name, 'read_response', 'call perform_request again';
    };
};

subtest "map_reduce" => sub {
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
            $client->map_reduce('some-js-map-reduce...');
        }
        qr/Error in 'map_reduce' : ops/, 'should die with the correct message';
    };

    subtest "should return arrayref" => sub {
        plan tests => 2;
        my $mock = Test::MockObject->new;

        my $mock_response1 = {
            error => undef,
            code  => 24,
            body  => RpbMapRedResp->encode(
                {   done     => undef,
                    phase    => 0,
                    response => '[["foo",1]]',
                }
            )
        };
        my $mock_response2 = {
            error => undef,
            code  => 24,
            body  => RpbMapRedResp->encode(
                {   done     => 1,
                    phase    => undef,
                    response => undef,
                }
            )
        };

        $mock->set_true('perform_request');
        $mock->set_series( 'read_response', $mock_response1, $mock_response2 );


        my $client = Riak::Light->new(
            host   => 'host', port => 1234, autodie => 1,
            driver => $mock
        );

        my $arrayref;
        lives_ok {
            $arrayref = $client->map_reduce('some-js-map-reduce...');
        }
        'should not die';

        is_deeply [
            {   phase    => 0,
                response => [ [ "foo", 1 ] ],
            }
          ],
          $arrayref, 'should return';
    };
    subtest "should call the callback" => sub {
        plan tests => 3;
        my $mock = Test::MockObject->new;

        my $mock_response1 = {
            error => undef,
            code  => 24,
            body  => RpbMapRedResp->encode(
                {   done     => undef,
                    phase    => 0,
                    response => '[["foo",1]]',
                }
            )
        };
        my $mock_response2 = {
            error => undef,
            code  => 24,
            body  => RpbMapRedResp->encode(
                {   done     => 1,
                    phase    => undef,
                    response => undef,
                }
            )
        };

        $mock->set_true('perform_request');
        $mock->set_series( 'read_response', $mock_response1, $mock_response2 );

        my $client = Riak::Light->new(
            host   => 'host', port => 1234, autodie => 1,
            driver => $mock
        );

        my ( $phase, $response );
        my $callback = sub {
            ( $response, $phase ) = @_;
        };
        lives_ok {
            $client->map_reduce( 'some-js-map-reduce...', $callback );
        }
        'should not die';

        is $phase, 0, 'phase should be 1';
        is_deeply [ [ "foo", 1 ] ], $response, 'should return';
    };
};
