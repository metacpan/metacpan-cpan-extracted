use strict;
use Test::More;

require Plack::Middleware::MemoryUsage;
note("new");
my $obj = new_ok("Plack::Middleware::MemoryUsage");

# diag explain $obj

done_testing;
