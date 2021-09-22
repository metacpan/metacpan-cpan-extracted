package Test::Mock::Redis::NoOp;

=head1 NAME

Test::Mock::Redis::NoOp - A Redis mock that does not do anything useful

=head1 SYNOPSIS

    use Test::Most;
    use Test::Mock::Redis::NoOp;
    
    my $redis = Test::Mock::Redis::NoOp->mock_new( );
    
    $redis->connect( );
    $redis->ping;
    $redis->set(
        foo => 'Hello Mock',
        ex  => 3600,
    );
    $redis->keys( '*' );
    $redis->mget( qw/foo bar baz/ );
    $redis->non_existing_redis_command( 0..9 );
    $redis->quit;
    
    mock_cmp_calls $redis, [
        new     => undef,
        connect => [ $redis ],
        ping    => [ $redis ],
        set     => [ $redis, 'foo', 'Hello Mock, 'ex', 3600 ],
        keys    => [ $redis, '*' ],
        mget    => [ $redis, 'foo', 'bar', 'baz' ],
        non_existing_redis_command => [ $redis, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 ],
        quit    => [ $redis ],
    ], "Calls are dispatched unaltered";
    
    done_testing;

=head1 DESCRIPTION

Returns a mocked Redis client for the purpose of checking calls being dispatched
properly from L<Redis::OpenTracing> to its internal C<redis> client, without any
changes.

=cut



use strict;
use warnings;

use Test::Builder;
use Test::Deep qw/cmp_details deep_diag/;
use Test::MockObject;



sub mock_new {
    my $class = shift;
    
    my $mock = Test::MockObject->new( );
    
    $mock->set_isa('Redis::NoOp');
    
    $mock->mock(
        connect     => sub { "OK" },
    );
    $mock->mock(
        ping        => sub { "PONG" },
    );
    $mock->mock(
        set         => sub { "OK" },
    );
    
    $mock->set_list(
        keys        => qw/foo bar baz/,
    );
    
    $mock->{ 'server' } = 'http://redis.example.com:8080';
    
    return $mock
}



sub mock_cmp_calls {
    my ( $class, $mock, $exp, $test_name ) = @_;
    
    my @calls = $class->_extraxt_all_calls( $mock );
    my ($ok, $stack) = cmp_details(\@calls, $exp);
    
    my $test = Test::Builder->new;
    
    if (not $test->ok($ok, $test_name)) {
        $test->diag(deep_diag($stack));
        $test->diag($test->explain(\@calls));
    }
    
    return $ok;
    
}



sub _extraxt_all_calls {
    my ( $class, $mock ) = @_;
    
    my @calls;
    while ( my( $name, $args ) = $mock->next_call( ) ) {
        push @calls, $name, $args
    }
    
    return @calls;
    
}

1;
