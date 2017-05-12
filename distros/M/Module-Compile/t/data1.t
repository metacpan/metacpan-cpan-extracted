my $t; use lib ($t = -e 't' ? 't' : 'test'), 'inc';
use TestModuleCompile tests => 3;

no_diff;

my $pmc;
BEGIN {
    $pmc = "$t/lib/DataTest.pmc";
    unlink($pmc);
    ok((not -e $pmc), ".pmc doesn't exist yet");
}

use DataTest;

ok((-e $pmc), ".pmc exists");

local $/;
my $data = <DataTest::DATA>;
is $data, "\none\ntwo\n\nthree\n\n",
    "DATA section is correct";
