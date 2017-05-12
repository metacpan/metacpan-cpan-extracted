BEGIN {
    unless ( $ENV{RIAK_PBC_HOST} ) {
        require Test::More;
        Test::More::plan(
            skip_all => 'variable RIAK_PBC_HOST is not defined' );
    }
}

package main;

use Test::More tests => 3;
use Test::LeakTrace;
use Riak::Light;

no_leaks_ok {

    my ( $host, $port ) = split ':', $ENV{RIAK_PBC_HOST};

    my $client = Riak::Light->new(
        host             => $host, port => $port,
        timeout_provider => undef
    );

    $client->put( foo => bar => { my => 666 } );
    $client->get( foo => 'bar' );
    $client->del( foo => 'bar' );
}
' should be ok for no timeout_provider';

my ( $host, $port ) = split ':', $ENV{RIAK_PBC_HOST};

my $client = Riak::Light->new(
    host             => $host, port => $port,
    timeout_provider => 'Riak::Light::Timeout::Select'
);

no_leaks_ok {
    for ( 1 .. 2 ) {
        $client->put( foo => bar => { my => 666 } );
        $client->get( foo => 'bar' );
        $client->del( foo => 'bar' );
    }
}
' should be ok for setsockopt timeout_provider';

leaktrace {

    $client->put( foo => bar => { my => 666 } );
    $client->get( foo => 'bar' );
    $client->del( foo => 'bar' );
};
no_leaks_ok {

    my $client2 = Riak::Light->new(
        host             => $host, port => $port,
        timeout_provider => 'Riak::Light::Timeout::Select'
    );
    $client2->put( foo => bar => { my => 666 } );
    $client2->get( foo => 'bar' );
    $client2->del( foo => 'bar' );
}
' should be ok for setsockopt timeout_provider';
