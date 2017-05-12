use strict;
use warnings;
use Test::More;

BEGIN { $ENV{PERL_DL_NOLAZY} = 1 }

BEGIN { use_ok('Net::SSDP') }

done_testing;
