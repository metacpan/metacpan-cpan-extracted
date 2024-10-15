use strict;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/..";

use t::Util;

require Net::SSL::ExpireDate;
Net::SSL::ExpireDate->import;
note("new");
my $obj = new_ok("Net::SSL::ExpireDate" => [ https => 'badssl.com' ]);

# diag explain $obj

done_testing;
