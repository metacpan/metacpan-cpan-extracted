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

# We will evilly test internal APIs here.
# Users of the public APIs must close their eyes now. 

my $cachefile = $xref->__cache_filename("$lib/B.pm");

cachefile_sanity($xref, $cachefile, $cache_directory);

is($xref->__unparse_cache_filename($cachefile), "$lib/B.pm", "unparse");

done_testing();
