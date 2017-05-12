package RedisClientTest;

use strict;
use warnings;

use Redis::Client;

sub server { 
    my $host = $ENV{PERL_REDIS_TEST_SERVER}   || 'localhost';
    my $port = $ENV{PERL_REDIS_TEST_PORT}     || '6379';
    my $pw   = $ENV{PERL_REDIS_TEST_PASSWORD} || undef;

    my $client = eval { 
        my $c = Redis::Client->new( host => $host,
                                    port => $port,
                                    $pw ? ( password => $pw ) : ( ) );

        # sockets are lazy, so test connection here
        my $test = $c->echo( 'foobar' );
        die 'something strange happened' if $test ne 'foobar';
        $c;
    };

    if ( my $err = $@ ) { 
        warn $err;
        return;
    }

    return $client;
}


1;
