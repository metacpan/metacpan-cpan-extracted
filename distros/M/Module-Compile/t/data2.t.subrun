my $t; use lib ($t = -e 't' ? 't' : 'test'), 'inc';
use TestModuleCompile tests => 3;

my $pmc;
BEGIN {
    $pmc = "$t/lib/DataTest.pmc";
    ok((-e $pmc), ".pmc exists");
}

use DataTest;

ok((-e $pmc), ".pmc still exists");

local $/;
my $data = <DataTest::DATA>;
is $data, "\none\ntwo\n\nthree\n\n",
    "DATA section is correct";

END { unlink "$t/lib/DataTest.pmc" }
