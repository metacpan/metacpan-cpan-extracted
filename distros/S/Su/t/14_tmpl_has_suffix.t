use Test::More tests => 4;

use lib qw(lib ../lib);
use Su::Process;

ok( !Su::Process::_has_suffix('/foo/bar/aa') );

ok( Su::Process::_has_suffix('/foo/bar/aa.pm') );

ok( Su::Process::_has_suffix('/foo/bar/aa.pm') );

is( Su::Process::_has_suffix('/foo/bar/aa.pm'), '.pm' );

