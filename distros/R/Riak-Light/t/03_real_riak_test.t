BEGIN {
    unless ( $ENV{RIAK_PBC_HOST} ) {
        require Test::More;
        Test::More::plan(
            skip_all => 'variable RIAK_PBC_HOST is not defined' );
    }
}

use Test::More tests => 3;
use Test::Exception;
use Riak::Light;
use JSON;

subtest "simple get/set/delete test" => sub {
    plan tests => 13;

    my ( $host, $port ) = split ':', $ENV{RIAK_PBC_HOST};

    my $client = Riak::Light->new(
        host             => $host, port => $port,
        timeout_provider => undef
    );

    my $scalar = '3.14159';
    my $hash = { baz => 1024 };

    ok( $client->ping(),     "should can ping" );
    ok( $client->is_alive(), "should can ping" );
    ok( $client->put( foo => "bar", $hash ),
        "should store the hashref in Riak"
    );
    is_deeply(
        $client->get( foo => 'bar' ), $hash,
        "should fetch the stored hashref from Riak"
    );

    ok( $client->put_raw( foo => "bar2", $scalar ),
        "should store the raw scalar in Riak"
    );
    is( $client->get_raw( foo => 'bar2' ), $scalar,
        "should fetch the raw scalar from Riak"
    );

    ok( $client->exists( foo => 'bar' ), "should exists" );
    ok( $client->del( foo => 'bar' ), "should delete the hashref" );
    ok( !$client->get( foo => 'bar' ), "should fetch UNDEF from Riak" );
    ok( !$client->exists( foo => 'bar' ), "should not exists" );

    ok( $client->put( foo => "baz", 'TEXT', 'plain/text' ),
        "should store the text in Riak"
    );
    is( $client->get( foo => "baz" ), 'TEXT',
        "should fetch the text from Riak"
    );

    my $vclock = $client->get_vclock( foo => "baz" );

    ok $vclock, "should return vclock=$vclock";

    #ok(!$@, "should has no error - foo => bar is undefined");
};

subtest "get keys" => sub {
    plan tests => 4;

    my $bucket = "foo_" . int( rand(1024) ) . "_" . int( rand(1024) );

    my ( $host, $port ) = split ':', $ENV{RIAK_PBC_HOST};

    my $client = Riak::Light->new(
        host             => $host, port => $port,
        timeout_provider => undef
    );

    my @keys;
    $client->get_keys( $bucket => sub { push @keys, $_[0] } );

    foreach my $key (@keys) {
        $client->del( $bucket => $key );
    }
    my $hash = { a => 1 };

    $client->put( $bucket => "bar", $hash );
    $client->put( $bucket => "baz", $hash );
    $client->put( $bucket => "bam", $hash );

    @keys = ();
    $client->get_keys( $bucket => sub { push @keys, $_[0] } );

    @keys = sort @keys;
    is( scalar @keys, 3,     'should return 3 items' );
    is( $keys[0],     'bam', '..bam' );
    is( $keys[1],     'bar', '..bar' );
    is( $keys[2],     'baz', '..baz' );
};

subtest "sequence of 1024 get/set" => sub {
    plan tests => 1024;

    my ( $host, $port ) = split ':', $ENV{RIAK_PBC_HOST};

    my $client = Riak::Light->new(
        host             => $host, port => $port,
        timeout_provider => undef
    );

    my $hash = {
        foo       => bar  => baz     => 123,
        something => very => complex => [ 1, 2, 3, 4, 5 ]
    };

    my ( $bucket, $key );
    for ( 1 .. 1024 ) {
        ( $bucket, $key ) =
          ( "bucket" . int( rand(1024) ), "key" . int( rand(1024) ) );

        $hash->{random} = int( rand(1024) );

        $client->put( $bucket => $key => $hash );

        my $got_complex_structure = $client->get( $bucket => $key );
        is_deeply(
            $got_complex_structure, $hash,
            "get($bucket=>$key)should got the same structure"
        );
    }
};
