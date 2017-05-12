use Test::More;

use strict;
use warnings;

use PPI::Xref;

use FindBin qw[$Bin];
require "$Bin/util.pl";
my ($xref, $lib) = get_xref();

ok($xref->process("$lib/B.pm"), "process file");

my $id = $xref->incs_deps;
ok($id, "incs_deps");
my @id;
for my $f ($id->files) {
  push @id, "$f\t" . $id->file_kind($f);
}

is_deeply(\@id,
          [
           "$lib/A.pm\tleaf",
           "$lib/B.pm\troot",
           "$lib/E.pm\tbranch",
           "$lib/F.pm\tleaf",
           "$lib/f.pl\tbranch",
           "$lib/g.pl\tleaf",
          ],
         "incs_deps");

is($id->file_kind("$lib/x.pl"), undef, "unknown file");

($xref, $lib) = get_xref();
ok($xref->process("$lib/g.pl"), "process file");
$id = $xref->incs_deps;
is($id->file_kind("$lib/g.pl"), "singleton", "singleton file");

done_testing();
