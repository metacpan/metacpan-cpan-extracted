use strict;
use Test::More tests => 1;


# Check that the module loads ok
BEGIN { use_ok( 'Net::DVBStreamer::Client' ); }



## Can't really test much more than this without a working DVBStreamer server
