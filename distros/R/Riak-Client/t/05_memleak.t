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

use Test::LeakTrace;

my ( $host, $port ) = split ':', $ENV{RIAK_PBC_HOST};


no_leaks_ok {
    my $client = Riak::Client->new(
        host => $host,
        port => $port,
        no_auto_connect => 1,
    );
    $client->connect;
} "connection";

no_leaks_ok {

    my ( $host, $port ) = split ':', $ENV{RIAK_PBC_HOST};

    my $client = Riak::Client->new(
        host => $host, port => $port,
    );

    my $scalar = '3.14159';
    my $hash = { baz => 1024 };

    # make sure we run stuff with callbacks as well
    
    $client->ping();
    $client->is_alive();    $client->get(     foo => 'bar' );
    $client->put_raw( foo => "bar2", $scalar );
    $client->get_raw( foo => 'bar2' );
    $client->exists(  foo => 'bar' );
    $client->del(     foo => 'bar' );
    $client->get(     foo => 'bar' );

    $client->exists( foo => 'bar' );

    $client->put( foo => "baz", 'TEXT', 'plain/text' );
    $client->get( foo => "baz" );    #ok(!$@, "should has no error - foo => bar is undefined");
} "memleak test for simple get/set/delete test";


no_leaks_ok {

    my @buckets_to_cleanup;
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

    _cleanup(@buckets_to_cleanup);

} "memleak test for get keys";

done_testing;

END { _cleanup('foo'); }

sub _cleanup {
    my @buckets_to_cleanup = @_;

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
