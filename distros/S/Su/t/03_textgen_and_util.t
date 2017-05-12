use Test::More;

use lib qw(lib ../lib);

use Su::Process;

BEGIN {
  plan tests => 7;
}

$Su::Process::PROCESS_BASE_DIR = "./t";
$Su::Process::PROCESS_DIR      = "test03";

# test for internal utility functions.

ok( Su::Process::_has_suffix('aaa.txt') );

ok( !Su::Process::_has_suffix('aaa') );

ok( Su::Process::_has_suffix('xxx/aaa.txt') );

ok( !Su::Process::_has_suffix('xxx/aaa') );

ok( Su::Process::_has_suffix('xxx/y/aaa.txt') );

ok( !Su::Process::_has_suffix('xxx/y/aaa') );

my $ret = gen('test.txt');

my $expecred_result = << '__HERE__';
line 1
line 2
line 3
__HERE__

is( $ret, $expecred_result );

