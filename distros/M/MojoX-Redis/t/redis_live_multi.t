#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Mojo::IOLoop;
use utf8;

plan skip_all => 'Setup $REDIS_SERVER'
  unless $ENV{REDIS_SERVER};

plan tests => 3;

use_ok 'MojoX::Redis';

my $redis =
  new_ok 'MojoX::Redis' => [server => $ENV{REDIS_SERVER}, timeout => 5];

my $result;
$redis->del('test')->multi->rpush(test => 'ok')->lrange(test => 0, -1)->exec(
    sub {
        my ($redis, $res) = @_;
        $result = $res;
        $redis->stop;
    }
)->start;

is_deeply $result, [[1], [['ok']]];
