use strict;
use Test::More;

require Parse::Daemontools::Service;
Parse::Daemontools::Service->import;
note("new");
my $obj = new_ok("Parse::Daemontools::Service");

# diag explain $obj

done_testing;
