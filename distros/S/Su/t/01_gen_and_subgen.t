use Test::More;

use lib qw( lib ./t/test01 ../t/test01 ../lib);

use Su::Process;

BEGIN {
  plan tests => 2;
}

$Su::Process::PROCESS_BASE_DIR = "./t";
$Su::Process::PROCESS_DIR      = "test01";

my $ret = gen("TestComp01");
is( $ret, "TestComp01" );

## Test for sub package.
$Su::Process::PROCESS_BASE_DIR = "./t";
$Su::Process::PROCESS_DIR      = "test01";

$ret = gen("subcomp/TestComp02");

is( $ret, "TestComp02" );

