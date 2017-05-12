use Test::More;

use strict;
use warnings;

use PPI::Xref;

use FindBin qw[$Bin];
require "$Bin/util.pl";
my ($xref, $lib) = get_xref();

ok($xref->process("$lib/B.pm"), "process file");

my @fc;
for my $f ($xref->files) {
  push @fc, "$f\t" . $xref->file_count($f);
}

is_deeply(\@fc,
          [
           "$lib/A.pm\t2",
           "$lib/B.pm\t1",
           "$lib/E.pm\t2",
           "$lib/F.pm\t1",
           "$lib/f.pl\t1",
           "$lib/g.pl\t1",
          ],
         "files_counts");

done_testing();
