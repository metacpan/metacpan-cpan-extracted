#!perl

use Test::More;
use Test::Exception;

use Prometheus::Tiny::Shared;

dies_ok { Prometheus::Tiny::Shared->new(cache_args => {}) } 'constructor dies when cache_args supplied';

done_testing;
