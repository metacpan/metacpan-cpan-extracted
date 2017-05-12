use Test::More;

use strict;
use warnings;

use PPI::Xref;

use FindBin qw[$Bin];
require "$Bin/util.pl";

use File::Temp qw[tempdir];
my $incdir   = [ @INC ];
my $cache_directory = tempdir(CLEANUP => 1);

my $code = 'use utf8;';  # Pulls in both pm and pl; but not too heavy.

local $SIG{__WARN__} = \&warner;

my ($xref1, $lib1) = get_xref({cache_directory => $cache_directory,
                               incdir   => $incdir});

ok($xref1->process(\$code), "process string with cache");

cmp_ok($xref1->docs_created, '>', 1, "docs created");
is($xref1->cache_reads, 0, "reads from cache");
is($xref1->cache_writes, $xref1->docs_created - 1, "writes to cache");

my ($xref2, $lib2) = get_xref({incdir => $incdir});  # No cache.

ok($xref2->process(\$code), "process string without cache");

is_deeply([$xref2->subs], [$xref1->subs], "subs");
is_deeply([$xref2->modules], [$xref1->modules], "modules");
is_deeply([$xref2->packages], [$xref1->packages], "packages");

is($xref2->docs_created, 1 + $xref1->cache_writes, "docs created");
is($xref2->cache_reads, 0, "no reads from cache");
is($xref2->cache_writes, 0, "writes to cache");

my ($xref3, $lib3) = get_xref({cache_directory     => $cache_directory,
                               # cache_verbose => 1,
                               incdir       => $incdir});

ok($xref3->process(\$code), "process string with cache");

is_deeply([$xref3->subs], [$xref1->subs], "subs");
is_deeply([$xref3->modules], [$xref1->modules], "modules");
is_deeply([$xref3->packages], [$xref1->packages], "packages");

is($xref3->docs_created, 1, "one doc created");
is($xref3->cache_reads, $xref1->cache_writes, "reads from cache");
is($xref3->cache_writes, 0, "writes to cache");

done_testing();
