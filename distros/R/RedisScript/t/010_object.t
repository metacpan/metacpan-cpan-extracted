use strict;
use warnings;

use Test::More;
use RedisScript;

plan skip_all => 'need a local redis server => define RUN_REDIS_TESTS' unless defined $ENV{RUN_REDIS_TESTS};

my $test_count = 0;

$test_count++;
use_ok( q{Redis} );

my $o = RedisScript->new( redis => Redis->new(), code => q{return 1} );

$test_count++;
isa_ok( $o, q{RedisScript} );

done_testing( $test_count );
