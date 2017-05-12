use Test::More;

use strict;
use warnings;

use PPI::Xref;

use FindBin qw[$Bin];
require "$Bin/util.pl";

use File::Temp qw[tempdir];
my $incdir   = tempdir(CLEANUP => 1);
my $cache_directory = tempdir(CLEANUP => 1);

my ($xref1, $lib1) = get_xref({cache_directory     => $cache_directory,
                               incdir       => $incdir,
                               # cache_verbose   => 1,
                               # processverbose => 1,
                               abslib       => 1});

my $pm = "$lib1/X.pm";
my $fh;

open($fh, '>', $pm) or die "$pm: $!\n";
print { $fh } "package X; sub foo {}\n";
close($fh);

ok($xref1->process("$pm"), "process file");

cachefile_sanity($xref1, $xref1->__cache_filename($pm), $cache_directory);

is($xref1->docs_created, 1, "docs created");
is($xref1->cache_reads, 0, "no reads from cache");
is($xref1->cache_writes, 1, "writes to cache");
is($xref1->cache_updates, 0, "updates to cache");
is($xref1->cache_creates, 1, "creates to cache");

is_deeply([$xref1->subs], [ qw/X::foo/ ], "subs");

# Update the module, should cause reprocessing.
print "# updating $pm\n";
open($fh, '>>', $pm) or die "$pm: $!\n";
print { $fh } "sub bar {}\n";
close($fh);

ok($xref1->process("$pm"), "process file after module update");

is_deeply([$xref1->subs], [ qw/X::bar X::foo/ ], "updated subs");

is($xref1->docs_created, 2, "docs created"); # +1 from previous
is($xref1->cache_reads, 0, "no reads from cache");
is($xref1->cache_writes, 2, "no writes to cache"); # +1 from previous
is($xref1->cache_updates, 1, "updates to cache"); # +1 from previous
is($xref1->cache_creates, 1, "creates to cache");

ok($xref1->process("$pm"), "process file again");

is($xref1->docs_created, 2, "docs created");
is($xref1->cache_reads, 1, "no reads from cache");
is($xref1->cache_writes, 2, "no writes to cache");
is($xref1->cache_updates, 1, "no updates to cache"); # +1 from previous
is($xref1->cache_creates, 1, "creates to cache");

my ($xref2, $lib2) = get_xref({cache_directory     => $cache_directory,
                               cache_verbose => 1,
                               incdir       => $incdir,
                               abslib       => 1});

ok($xref2->process("$pm"), "process file with cache");

is($xref2->docs_created, 0, "no docs created");
is($xref2->cache_reads, 1, "reads from cache");
is($xref2->cache_writes, 0, "no writes to cache");
is($xref2->cache_updates, 0, "no updates to cache");
is($xref2->cache_creates, 0, "no creates to cache");

is_deeply([$xref2->subs], [ qw/X::bar X::foo/ ], "subs");

done_testing();
