use Test::More;

use strict;
use warnings;

use PPI::Xref;

use FindBin qw[$Bin];
require "$Bin/util.pl";

use File::Temp qw[tempdir];
my $cache_directory = tempdir(CLEANUP => 1);

my ($xref0, $lib0) = get_xref({cache_verbose => 1,
   abslib => 1});  # No caching.

ok($xref0->process("$lib0/B.pm"), "process file");

my $N = 6;  # There are six *.{pm,pl} files.

is($xref0->docs_created, $N, "docs created");
is($xref0->cache_reads, 0, "no reads from cache");
is($xref0->cache_writes, 0, "no writes to cache");
is($xref0->cache_writes, 0, "no writes to cache");
is($xref0->cache_updates, 0, "no updates to cache");
is($xref0->cache_creates, 0, "no creates to cache");

my ($xref1, $lib1) = get_xref({cache_directory => $cache_directory,
                               abslib => 1});

is($lib1, $lib0, "the same lib");

ok($xref1->process("$lib1/B.pm"), "process file");

cachefile_sanity($xref1,
                 $xref1->__cache_filename("$lib1/B.pm"),
                 $cache_directory);

is_deeply([$xref1->subs], [$xref0->subs], "subs");
is_deeply([$xref1->files], [$xref0->files], "files");
is_deeply([$xref1->modules], [$xref0->modules], "modules");
is_deeply([$xref1->packages], [$xref0->packages], "packages");

is($xref1->docs_created, $N, "docs created");
is($xref1->cache_reads, 0, "no reads from cache");
is($xref1->cache_writes, $N, "writes to cache");
is($xref1->cache_updates, 0, "no update to cache");
is($xref1->cache_creates, $N, "creates to cache");

ok($xref1->process("$lib1/B.pm"), "process file");

done_testing();
