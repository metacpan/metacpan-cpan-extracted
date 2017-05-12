use warnings;
use strict;
use Test::More tests => 1;

BEGIN { use_ok( 'Sub::Throttler' ) or BAIL_OUT('unable to load module') }

diag( "Testing Sub::Throttler $Sub::Throttler::VERSION, Perl $], $^X" );
