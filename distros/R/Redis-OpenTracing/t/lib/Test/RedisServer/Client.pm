package Test::RedisServer::Client;

=head1 NAME

Test::RedisServer::Client - Possibly return a testing client with Redis

=head1 SYNOPSIS

    use Test::Most;
    use Test::LoadRedis;
    
    my $redis = Test::RedisServer::Client->connect
        or plan skip_all => 'Can not run integration tests with Redis';
    
    is $redis->ping, 'PONG', 'ping pong ok';
    
    done_testing;



=head1 DESCRIPTION

This module will simplify running test with C<redis-server> and the L<Redis>
client. It only provides one method L<< C<connect> >>.



=head1 CLASS METHODS

=cut



use strict;
use warnings;

use Test::RedisServer;

our $redis_server;
#
# we need to keep this, otherwise the connection gets dropped



=head2 C<connect>

This method will try to bootstrap a temporary Redis server (based on
L<Test::RedisServer>) and return a client based on the L<Redis> if installed.

It returns nothing if anything fails in the middle.

=cut

sub connect {
    my $self = shift;
    
    eval {
        $redis_server = Test::RedisServer->new;
    } or return;
    
    eval {
        use Redis; 1
    } or return;
    
    my $redis_client;
    eval {
        $redis_client = Redis->new( $redis_server->connect_info );
    } or return;
    
    return $redis_client
}


# END
#
# we need to manually stop the redis server once we're done testing, or it will
# hang the Test suit :-)
#
END {
    $redis_server and $redis_server->stop( );
}


1;
