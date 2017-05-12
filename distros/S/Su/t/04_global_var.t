
use Test::More tests => 4;
use lib qw(lib ../lib);

{
  require_ok('Su::Template');
  require_ok('Su::Process');
}

{

  no warnings qw(once);
  is( $Su::Process::PROCESS_BASE_DIR, "./" );

  is( $Su::Process::PROCESS_DIR, "Procs" );

}

