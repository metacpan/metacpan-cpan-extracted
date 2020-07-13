use strict;
use warnings;

use Test::More;

use RedisDB;

use Log::Any::Adapter qw(TAP);

use OpenTracing::Any qw($tracer);
use OpenTracing::Integration qw(RedisDB);

my $redis = RedisDB->new;
$redis->get('some_key');

my @spans = $tracer->span_list;
is(@spans, 1, 'have expected span count');
{
    my $span = shift @spans;
    is($span->operation_name, 'redis: GET', 'have correct operation');
}

done_testing;

