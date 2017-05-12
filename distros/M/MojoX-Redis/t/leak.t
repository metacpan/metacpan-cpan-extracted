#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Mojo::IOLoop;
use utf8;
use MojoX::Redis;

BEGIN {
    eval q{use Test::LeakTrace};
    plan skip_all => "Test::LeakTrace required" if $@;
}

plan skip_all => 'Setup $REDIS_SERVER'
  unless $ENV{REDIS_SERVER};

plan tests => 4;

my $redis = MojoX::Redis->new(server => $ENV{REDIS_SERVER}, timeout => 5);

$redis->on_error(sub { });

no_leaks_ok {
    $redis->ping(\&cb_ioloop_stop)->start;
}
"ping";

no_leaks_ok {
    $redis->execute("strange_command", \&cb_ioloop_stop)->start;
}
"error";

no_leaks_ok {
    $redis->set(test => 'test_ok', \&cb_ioloop_stop)->start;
}
"set";

no_leaks_ok {
    $redis->get(test => \&cb_ioloop_stop)->start;
}
"get";

sub cb_ioloop_stop {
    shift->stop;
}
