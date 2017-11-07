# Copyright (C) 2017 Koha-Suomi
#
# This file is part of Pootle-Client.

use Modern::Perl '2015';
use utf8;
binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';
use FindBin;
use lib "$FindBin::Bin/../";
use feature 'signatures'; no warnings "experimental::signatures";
use Carp::Always;
use Try::Tiny;
use Scalar::Util qw(blessed);
use Data::Dumper;

use File::Slurp;

use Test::More;
use Test::MockModule;

use Pootle::Cache;


subtest "Scenario: Pootle::Cache persists after destruction", \&persist;
sub persist {
  my ($c, $cacheFile, $cachedVal, $cacheFileContents, $cachedDataStructure);
  my $obscureDataStructure = {obscure => ['data', 'structure']};
  eval {

  ok($c = new Pootle::Cache(),
    "Given a Pootle::Cache");
  $cacheFile = $c->cacheFile;

  ok(-e $c->cacheFile,
    "Then a cache file is created");

  ok($c->pSet('cache-key', $obscureDataStructure),
    "When a cache entry is created");

  ok($cachedVal = $c->pGet('cache-key'),
    "And the cache entry is fetched");

  is_deeply($cachedVal, $obscureDataStructure,
    "Then the cached entry is the same as we put in");

  is($c = undef, undef,
    "When the cache loses all references to it");

  ok(sleep(1),
    "And we wait for the garbage collection");

  ok($cacheFileContents = File::Slurp::read_file($cacheFile, { binmode => ':encoding(UTF-8)' }),
    "Then the cache was persisted to file");

  ok($cachedDataStructure = Pootle::Cache::_evalCacheContents($cacheFileContents),
    "When the cache contents are parsed to a Perl data structure");

  is_deeply($cachedDataStructure, {'cache-key' => $obscureDataStructure},
    "Then the cache contents match what we put in");

  };
  if ($@) {
    ok(0, $@);
  }
  unlink $cacheFile; #Finally cleanup
};

done_testing();
