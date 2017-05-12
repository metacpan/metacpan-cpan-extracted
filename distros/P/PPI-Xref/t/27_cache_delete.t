use Test::More;

use strict;
use warnings;

use PPI::Xref;

use FindBin qw[$Bin];
require "$Bin/util.pl";

use File::Temp qw[tempdir];
my $cache_directory = tempdir(CLEANUP => 1);

my ($xref, $lib) = get_xref({cache_directory => $cache_directory,
                             cache_verbose => 1,
                             process_verbose => 1,
                             abslib => 1});

ok($xref->process("$lib/B.pm"), "process file");

my $cache_B = $xref->__cache_filename("$lib/B.pm");
my $cache_A = $xref->__cache_filename("$lib/A.pm");

cachefile_sanity($xref, $cache_A, $cache_directory);
cachefile_sanity($xref, $cache_B, $cache_directory);

is($xref->cache_delete($cache_B), 1, "cache_delete cachefile for B");
ok(!-e $cache_B, "the cachefile for B is gone");

is($xref->cache_delete("$lib/A.pm"), 1, "cache_delete origfile for A");
ok(!-e $cache_A, "the cachefile for A is gone");

my $cache_X = "$cache_directory$lib/X.pm";
is($xref->cache_delete($cache_X), 0, "cache_delete nonesuch");

ok($xref->process("$lib/B.pm"), "reprocess file");

ok(-s $cache_B, "the cachefile for B is back");
ok(-s $cache_A, "the cachefile for A is back");

done_testing();
