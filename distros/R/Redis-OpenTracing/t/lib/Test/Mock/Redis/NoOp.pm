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

sub mock_new {
    my $class = shift;
    
    bless [], $class;
}

sub connect { _push_calls(@_); "OK" }
sub ping    { _push_calls(@_); "PONG" }
sub set     { _push_calls(@_); "OK" }
sub keys    { _push_calls(@_); my @keys = (qw/foo bar baz/); return @keys }
sub dies    { _push_calls(@_); die "$_[1]" // "Exception in Redis::NoOp" }



sub _push_calls {
    my $self = shift;
    my $sub = [ caller(1)]->[3];
    $sub =~ s/.*:://;

    push @$self, $sub, [$self, @_]
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
    
    
    return @$mock;
    
}

1;
