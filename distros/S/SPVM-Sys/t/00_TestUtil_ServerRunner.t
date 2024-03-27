use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";

use TestUtil::ServerRunner;

# Port
my $port = TestUtil::ServerRunner->empty_port;

warn "[Test Output]Port:$port";

ok($port >= 20000);

{
  my $server = TestUtil::ServerRunner->new(
    code => sub {
      my ($port) = @_;
      
      TestUtil::ServerRunner->run_echo_server($port);
    },
  );
}

ok(1);

done_testing;
