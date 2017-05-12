use strict;
use warnings;
BEGIN {
    unless ( $ENV{RIAK_PBC_HOST} ) {
        require Test::More;
        Test::More::plan(
            skip_all => 'variable RIAK_PBC_HOST is not defined' );
    }
}

use Test::More;
use Test::Exception;
use Riak::Client;


plan tests => 6;

my ( $host, $port ) = split ':', $ENV{RIAK_PBC_HOST};
my @buckets_to_cleanup = ( qw(foo) );


subtest "connection" => sub {
    plan tests => 2;
    my $client = Riak::Client->new(
        host => $host,
        port => $port,
        no_auto_connect => 1,
    );
    ok($client, "client created");
    ok($client->connect, "client connected");
};

subtest "simple get/set/delete test" => sub {
    plan tests => 12;

    my ( $host, $port ) = split ':', $ENV{RIAK_PBC_HOST};

    my $client = Riak::Client->new(
        host => $host, port => $port,
    );

    my $scalar = '3.14159';
    my $hash = { baz => 1024 };

    # make sure we run stuff with callbacks as well

    ok(       $client->ping(),                              "can ping" );
    ok(       $client->is_alive(),                          "is_alive" );
    ok(       $client->put(     foo => "bar",    $hash ),   "store hashref" );
    is_deeply($client->get(     foo => 'bar'  ), $hash,     "fetch hashref" );
    ok(       $client->put_raw( foo => "bar2"  , $scalar ), "store raw scalar");
    is(       $client->get_raw( foo => 'bar2' ), $scalar,   "fetch raw scalar");
    ok(       $client->exists(  foo => 'bar'  ),            "should exists" );
    ok(       $client->del(     foo => 'bar'  ),            "delete hashref" );
    ok(      !$client->get(     foo => 'bar'  ),            "fetches nothing" );

    ok( !$client->exists( foo => 'bar' ), "should not exists" );

    ok( $client->put( foo => "baz", 'TEXT', 'plain/text' ),
        "should store the text in Riak"
    );
    is( $client->get( foo => "baz" ), 'TEXT',
        "should fetch the text from Riak"
    );

    #ok(!$@, "should has no error - foo => bar is undefined");
};

subtest "get keys" => sub {
    plan tests => 5;

    my $bucket = "foo_" . int( rand(1024) ) . "_" . int( rand(1024) );
    push @buckets_to_cleanup, $bucket;

    my ( $host, $port ) = split ':', $ENV{RIAK_PBC_HOST};

    my $client = Riak::Client->new(
        host => $host, port => $port,
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
    my @keys_without_callback = @{ $client->get_keys( $bucket ) // [] };

    @keys = sort @keys;
    is( scalar @keys, 3 );
    is( scalar @keys_without_callback, 3 );
    is( $keys[0],     'bam' );
    is( $keys[1],     'bar' );
    is( $keys[2],     'baz' );
};

my $nb = 10;
subtest "sequence of $nb get/set" => sub {
    plan tests => $nb;

    my ( $host, $port ) = split ':', $ENV{RIAK_PBC_HOST};

    my $client = Riak::Client->new(
        host => $host, port => $port,
    );

    my $hash = {
        foo       => bar  => baz     => 123,
        something => very => complex => [ 1, 2, 3, 4, 5 ]
    };

    my ( $bucket, $key );
    for ( 1 .. $nb ) {
        ( $bucket, $key ) =
          ( "bucket" . int( rand(1024) ), "key" . int( rand(1024) ) );

        push @buckets_to_cleanup, $bucket;

        $hash->{random} = int( rand(1024) );

        $client->put( $bucket => $key => $hash );

        my $got_complex_structure = $client->get( $bucket => $key );
        is_deeply(
            $got_complex_structure, $hash,
            "get($bucket=>$key)should got the same structure"
        );
    }
};

subtest "get buckets" => sub {
    plan tests => 4;

    my ( $host, $port ) = split ':', $ENV{RIAK_PBC_HOST};

    my $client = Riak::Client->new(
        host => $host, port => $port,
    );

    my @new_buckets = (
        "foo_" . int( rand(1024) ) . "_" . int( rand(1024) ),
        "foo_" . int( rand(1024) ) . "_" . int( rand(1024) ),
        "foo_" . int( rand(1024) ) . "_" . int( rand(1024) ),
    );

    push @buckets_to_cleanup, @new_buckets;

    my @exp_buckets = ( @{ $client->get_buckets() // [] }, @new_buckets);

    my $key = "key" . int( rand(1024) );
    my $hash = { a => 1 };
    $client->put( $_ => $key => $hash ) foreach (@new_buckets);

    my @buckets = @{ $client->get_buckets() // [] };
    is( scalar @buckets, scalar @exp_buckets );

    foreach my $bucket (@new_buckets) {
        is(grep( $bucket eq $_, @buckets), 1, "bucket $bucket is found");
    }

};

subtest "get/set buckets props" => sub {
    plan tests => 4;

    my ( $host, $port ) = split ':', $ENV{RIAK_PBC_HOST};

    my $client = Riak::Client->new(
        host => $host, port => $port,
    );

    my @buckets = (
        "foo_" . int( rand(1024) ) . "_" . int( rand(1024) ),
        "foo_" . int( rand(1024) ) . "_" . int( rand(1024) ),
        "foo_" . int( rand(1024) ) . "_" . int( rand(1024) ),
    );

    push @buckets_to_cleanup, @buckets;

    my $key = "key" . int( rand(1024) );
    my $hash = { a => 1 };
    my $exp_props = { n_val => 1, allow_mult => 0 };
    foreach (@buckets) {
        $client->put( $_ => $key => $hash );
        $client->set_bucket_props($_, $exp_props);
    }

    my @props = map { $client->get_bucket_props($_) } @buckets;

    is( scalar @props, scalar @buckets);
    foreach my $p (@props) {
        is_deeply( { map { $_ => $p->{$_} } keys %$exp_props }, $exp_props, "wrong props structure")
    }
};

END {

    diag "\ncleaning up...";
    my $client = Riak::Client->new(
        host => $host, port => $port,
    );
    my $another_client = Riak::Client->new(
        host => $host, port => $port,
    );

    my $c = 0;
    foreach my $bucket (@buckets_to_cleanup) {
        $client->get_keys($bucket => sub{
                              my $key = $_; # also in $_[0]
                              # { local $| = 1; print "."; }
                              $c++;
                              $another_client->del($bucket => $key);
                          });
    }

    diag "done (deleted $c keys).";

}
