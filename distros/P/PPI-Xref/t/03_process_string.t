use Test::More;

use strict;
use warnings;

use PPI::Xref;

use FindBin qw[$Bin];
require "$Bin/util.pl";
my ($xref, $lib) = get_xref();

local $SIG{__WARN__} = \&warner;

ok($xref->process(\'use B;'), "process string");

is_deeply([$xref->files],
          [
           "-",
           "$lib/A.pm",
           "$lib/B.pm",
           "$lib/E.pm",
           "$lib/F.pm",
           "$lib/f.pl",
           "$lib/g.pl",
          ],
         "files (including '-')");

ok($xref->process(\'package Xyzzy;'), "process string again");

is(scalar(grep { /Xyzzy/ } $xref->packages), 1, "got package");

{
  local $SIG{__WARN__} = \&warner;
  undef $@;
  ok(!$xref->process([]), "process bad arg");
  like($@, qr/Unexpected arg/);
}

done_testing();
