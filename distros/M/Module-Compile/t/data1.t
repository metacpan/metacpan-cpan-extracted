my $t; use lib ($t = -e 't' ? 't' : 'test'), 'inc';
use TestModuleCompile tests => 4;
use Capture::Tiny qw(capture);
use App::Prove;

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

my ($out, $err, $exit) = capture {
  my $app = App::Prove->new;
  $app->process_args(qw(-l), "$t/data2.t.subrun");
  $app->run ? 0 : 1;
};
is $exit, 0, '.pmc load works same'
  or diag 'Output was: ', $out, 'Error was: ', $err;
