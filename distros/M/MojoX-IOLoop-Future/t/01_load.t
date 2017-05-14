#!/usr/bin/env perl

use Test::More;

BEGIN {
  use_ok('MojoX::IOLoop::Future')
}

my $argv = MojoX::IOLoop::Future->new;
isa_ok($argv, 'MojoX::IOLoop::Future');

done_testing;
