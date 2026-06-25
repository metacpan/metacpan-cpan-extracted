#!/usr/bin/env perl
use strict;
use warnings;
use 5.016;

use Test::More;

use FindBin;
require "$FindBin::Bin/test_setup.pl";

my $sluz = setup_sluz();

# -------------------------------------------------------------------
# Include tests
# -------------------------------------------------------------------
sluz_test($sluz, "{include file='tpls/extra.stpl'}", '/e1ab49cf/', 'Include #1 - file=extra.stpl');
sluz_test($sluz, "{include 'tpls/extra.stpl'}"     , '/e1ab49cf/', "Include #2 - 'extra.stpl'");

eval { $sluz->parse_string('{include}') };
like($@, qr/73467/, 'Include #3 - No payload');

sluz_test($sluz, "{include file='tpls/extra.stpl' secret='eca4906'}", '/eca4906/' , 'Include #4 - With variable');
sluz_test($sluz, "{include file=\"\$inc_file\"}"                    , '/e1ab49cf/', 'Include #5 - With variable file path');
sluz_test($sluz, "{include file='tpls/nested_inc.stpl'}"            , '/e1ab49cf/', 'Include #6 - Nested include');
sluz_test($sluz, "{include file='tpls/var_scope.stpl'}"             , '/SCOPE:15/', 'Include #7 - Variable scope (parent vars visible)');

done_testing();
