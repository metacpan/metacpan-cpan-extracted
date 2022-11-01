use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";

use TestUtil::Socket;

# Port
my $port = TestUtil::Socket::search_available_port();

warn "[Test Output]Port:$port";

ok($port >= 20000);

# start_echo_server again
{
  my $process_id = fork;

  # Child
  if ($process_id == 0) {
    TestUtil::Socket::start_echo_server($port);
  }
  else {
    TestUtil::Socket::wait_port_prepared($port);
    
    TestUtil::Socket::kill_term_and_wait($process_id);
  }
}

ok(1);

done_testing;
