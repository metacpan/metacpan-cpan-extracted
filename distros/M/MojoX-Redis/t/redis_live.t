#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Mojo::IOLoop;
use utf8;

plan skip_all => 'Setup $REDIS_SERVER'
  unless $ENV{REDIS_SERVER};

plan tests => 15;

use_ok 'MojoX::Redis';

my $redis =
  new_ok 'MojoX::Redis' => [server => $ENV{REDIS_SERVER}, timeout => 5];

my $errors = 0;
$redis->on_error(sub { $errors++ });

$redis->execute(
    ping => sub {
        is_deeply $_[1], ['PONG'], "Line result test";
    }
);

$redis->execute(
    qwe => sub {
        is_deeply $_[1], undef, 'Uknown command result';
        is $redis->error, q|ERR unknown command 'QWE'|,
          'Unknown command message';
        is $errors, 1, 'on_error works';
    }
);

$redis->execute(
    set => [test => 'test_ok'],
    sub { is_deeply $_[1], ['OK'], "Another line result"; }
);

$redis->execute(
    get => 'test',
    sub { is_deeply $_[1], ['test_ok'], "Bulk result"; }
);

$redis->execute(del => 'test')->execute(rpush => [test => 'test1'])
  ->execute(rpush => [test => 'test2'])->execute(
    lrange => ['test', 0, -1],
    sub {
        is_deeply $_[1], [["test1"], ["test2"]], "Multi-bulk result";
    }
  );

$redis->execute(set => [test => 'привет'])->execute(
    get => 'test',
    sub { ok utf8::is_utf8($_[1]->[0]), "Unicode test" }
);

$redis->execute(del => 'test');
$redis->execute(hmset => ['test', key => 'привет']);
$redis->execute(
    hmget => [test => 'key'],
    sub {
        ok utf8::is_utf8($_[1]->[0]->[0]), "Unicode test on multibulk reply";
    }
);

$redis->execute(del => 'test')->execute(
    get => 'test',
    sub { is_deeply $_[1], [undef], "Bulk nil return check" }
);

$redis->execute(
    lrange => ['test', 0, -1],
    sub {
        is_deeply $_[1], [], "Multi-bulk nil return check";
    }
);

$redis->execute(
    ping => sub {
        is_deeply $_[1], ['PONG'], "Last check";
    }
);

$redis->set(test => 'ok')->get(
    test => sub {
        is_deeply $_[1], ['ok'], "Fast command check";
    }
);

$redis->quit(sub { shift->stop; })->start;

