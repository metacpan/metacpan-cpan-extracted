use Test::More;

use strict;
use warnings;

use PPI::Xref;

use FindBin qw[$Bin];
require "$Bin/util.pl";
my ($xref, $lib) = get_xref();

ok($xref->process("$lib/B.pm"), "process file");

is_deeply([$xref->files],
          [
           "$lib/A.pm",
           "$lib/B.pm",
           "$lib/E.pm",
           "$lib/F.pm",
           "$lib/f.pl",
           "$lib/g.pl",
          ],
         "files");

{
  local $SIG{__WARN__} = \&warner;
  undef $@;
  ok(!$xref->process("$lib/X.pm"), "process no such file");
  like($@, qr/PPI::Document creation failed .+X.pm/);
}

done_testing();
