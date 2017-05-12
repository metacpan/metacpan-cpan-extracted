
use Test::More tests => 2;
use lib qw(lib ../lib);

use Su::Process dir => './somedir';

is( $Su::Process::PROCESS_BASE_DIR, "./" );

is( $Su::Process::PROCESS_DIR, "./somedir" );

