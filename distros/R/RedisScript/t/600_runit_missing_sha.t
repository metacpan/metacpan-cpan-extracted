
use strict;
use warnings;

use Test::More;

use RedisScript;

plan skip_all => 'devel only tests'
  unless( defined $ENV{RUN_REDIS_TESTS}
          and defined $ENV{DEVEL_TESTS} );

my $test_count = 0;

$test_count++;
skip q{need a local redis server - RUN_REDIS_TESTS}, 1 unless defined $ENV{RUN_REDIS_TESTS};
use_ok( q{Redis} );

my $o = RedisScript->new( redis => Redis->new(), code => q{return {KEYS[1],KEYS[2],ARGV[1],ARGV[2]}} );

$test_count++;
ok( $o->{_sha_cache} =~ m{\w{40}}, q{sha found} );

$test_count++;
is( $o->{redis}->script_flush(), q{OK}, q{Lua scripts cache flushed} );

$test_count++;
is( $o->{redis}->script_exists( $o->{_sha_cache} )->[0], 0, q{flush check} );

my @res = $o->runit( keys => [ qw/ a b / ], args => [ 1, 2 ] );

$test_count++;
is( $res[0], q{a}, q{check result} );

done_testing( $test_count );
