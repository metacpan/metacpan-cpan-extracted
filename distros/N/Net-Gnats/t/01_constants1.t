use strictures;
use Test::More;

# load a subset

use Net::Gnats::Constants qw(CODE_GREETING CODE_CLOSING CODE_OK);

is CODE_GREETING, 200;
is CODE_CLOSING, 201;
is CODE_OK, 210;

done_testing();
