
use strict;
use warnings;

use Test::More;

use RedisScript;

plan skip_all => 'need a local redis server => define RUN_REDIS_TESTS' unless defined $ENV{RUN_REDIS_TESTS};
my $test_count = 0;

$test_count++;
use_ok( q{Redis} );

my $o = RedisScript->new( redis => Redis->new(), code => q{return {KEYS[1],KEYS[2],ARGV[1],ARGV[2]}} );

my @res = $o->runit( keys => [ qw/ a b / ], args => [ 1, 2 ] );

$test_count++;
is( $res[0], q{a}, q{first key} );
$test_count++;
is( $res[1], q{b}, q{second key} );
$test_count++;
is( $res[2], 1, q{first arg} );
$test_count++;
is( $res[3], 2, q{second arg} );

done_testing( $test_count );
