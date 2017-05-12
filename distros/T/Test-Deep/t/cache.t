use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

use Test::Deep::Cache;

{
  local $Test::Deep::Expects = 0;
  my $cache = Test::Deep::Cache->new;

  my $a = \"a";
  my $b = \"b";
  my $c = [];

  ok(! $cache->cmp($a, $b), "empty cache");

  $cache->add($a, $b);

  ok($cache->cmp($a, $b), "added");
  ok($cache->cmp($b, $a), "reverse");

  $cache->local;

  ok($cache->cmp($a, $b), "after local");

  $cache->add($b, $c);
  ok($cache->cmp($b, $c), "local added");
  $cache->finish(0);
  ok(! $cache->cmp($b, $c), "gone");

  $cache->local;

  $cache->add($b, $c);
  ok($cache->cmp($b, $c), "local added again");
  $cache->finish(1);
  ok($cache->cmp($b, $c), "still there");
}

done_testing;
