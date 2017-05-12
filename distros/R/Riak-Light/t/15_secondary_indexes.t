BEGIN {
    unless ( $ENV{RIAK_PBC_HOST} ) {
        require Test::More;
        Test::More::plan(
            skip_all => 'variable RIAK_PBC_HOST is not defined' );
    }
}

use Test::More;
use Test::Exception;
use Riak::Light;
use JSON;

subtest "query 2i" => sub {

    my ( $host, $port ) = split ':', $ENV{RIAK_PBC_HOST};

    my $client = Riak::Light->new(
        host             => $host, port => $port,
        timeout_provider => undef
    );

    ok( $client->ping(),     "should can ping" );
    ok( $client->is_alive(), "should can ping" );
    my $hash = { baz => 1024 };

    my $bucket_name = "test_bucket_$$";

    foreach ( 1 .. 50 ) {
        ok( $client->del( $bucket_name => "key$_" ),
            "should cleanup the key in Riak"
        );
    }

    foreach ( 1 .. 50 ) {
        ok( !$client->exists( $bucket_name => "key$_" ),
            "key shouldn't exist anymore"
        );
    }

    foreach ( 1 .. 50 ) {
        ok( $client->del( $bucket_name => "other_key$_" ),
            "should cleanup the key in Riak"
        );
    }

    foreach ( 1 .. 50 ) {
        ok( !$client->exists( $bucket_name => "other_key$_" ),
            "key shouldn't exist anymore"
        );
    }

    foreach ( 1 .. 50 ) {
        ok( $client->put(
                $bucket_name => "key$_",
                $hash, undef,
                {   index_test_field_bin  => 'plop',
                    index_test_field2_bin => [ 'plop2', 'plop3' ]
                }
            ),
            "should store the hashref in Riak with indexes"
        );
    }

    foreach ( 1 .. 50 ) {
        ok( $client->put(
                $bucket_name => "other_key$_", $hash, undef,
                { index_test_field3_int => $_ }
            ),
            "should store the hashref in Riak with other index"
        );
    }

    is_deeply(
        [   sort @{
                $client->query_index(
                    $bucket_name => 'index_test_field_bin', 'plop'
                )
              }
        ],
        [ sort map {"key$_"} ( 1 .. 50 ) ],
        "querying the index should return the keys"
    );
    is_deeply(
        [   sort @{
                $client->query_index(
                    $bucket_name => 'index_test_field2_bin', 'plop2'
                )
              }
        ],
        [ sort map {"key$_"} ( 1 .. 50 ) ],
        "querying the index should return the keys"
    );
    is_deeply(
        [   sort @{
                $client->query_index(
                    $bucket_name => 'index_test_field2_bin', 'plop3'
                )
              }
        ],
        [ sort map {"key$_"} ( 1 .. 50 ) ],
        "querying the index should return the keys"
    );
    is_deeply(
        [   sort @{
                $client->query_index(
                    $bucket_name => 'index_test_field3_int', [ 30, 45 ]
                )
              }
        ],
        [ sort map {"other_key$_"} ( 30 .. 45 ) ],
        "querying the index with range should return the keys"
    );

    foreach ( 1 .. 50 ) {
        is_deeply(
            [   sort { $a->{value} cmp $b->{value} }
                  @{ $client->get_all_indexes( $bucket_name => "key$_" ) }
            ],
            [   { key => 'index_test_field_bin',  value => 'plop' },
                { key => 'index_test_field2_bin', value => 'plop2' },
                { key => 'index_test_field2_bin', value => 'plop3' },
            ],
            "querying all indexes from key$_"
        );

        is_deeply(
            $client->get_all_indexes( $bucket_name => "other_key$_" ),
            [   { key => 'index_test_field3_int', value => $_ },
            ],
            "querying all indexes from other_key$_"
        );

        is_deeply(
            $client->get_index_value(
                $bucket_name => "key$_" => 'index_test_field_bin'
            ),
            ['plop'],
            'should return the value of index_test_field_bin index "plop"'
        );

        my $data = $client->get_all_index_values( $bucket_name => "key$_" );

        $data->{index_test_field2_bin} =
          [ sort @{ $data->{index_test_field2_bin} } ];

        is_deeply $data,
          { index_test_field_bin  => ['plop'],
            index_test_field2_bin => [ 'plop2', 'plop3' ]
          },
          'should return two indexes';
    }

    foreach ( 1 .. 50 ) {
        ok( $client->del( $bucket_name => "key$_" ),
            "should cleanup the key in Riak"
        );
    }

    foreach ( 1 .. 50 ) {
        ok( !$client->exists( $bucket_name => "key$_" ),
            "key shouldn't exist anymore"
        );
    }

    foreach ( 1 .. 50 ) {
        ok( $client->del( $bucket_name => "other_key$_" ),
            "should cleanup the key in Riak"
        );
    }

    foreach ( 1 .. 50 ) {
        ok( !$client->exists( $bucket_name => "other_key$_" ),
            "key shouldn't exist anymore"
        );
    }


    is_deeply(
        $client->query_index( $bucket_name => 'index_test_field_bin', 'plop' ),
        [],
        "querying the index should return nothing"
    );

    is_deeply(
        $client->query_index(
            $bucket_name => 'index_test_field2_bin', 'plop2'
        ),
        [],
        "querying the index should return nothing"
    );

};

done_testing;
