#!/usr/bin/env perl
use strict;
use warnings;
use 5.016;

use Test::More;
use FindBin;
require "$FindBin::Bin/test_setup.pl";

# Additional fetch()-based tests ported/adjusted from the upstream PHP
# unit_tests (Fetch #1/#2 and variable rendering coverage).

my $sluz = setup_sluz();

# -------------------------------------------------------------------
# Fetch #1-style variable rendering fetch
# -------------------------------------------------------------------
$sluz->assign('secret', 'SECR3T');

my $out = $sluz->fetch('tpls/extra.stpl');
like($out, qr/e1ab49cf - SECR3T/, 'Fetch #2 - File fetch renders assigned variables');

# -------------------------------------------------------------------
# Direct fetch of a template only reachable via {include} elsewhere
# -------------------------------------------------------------------
$out = $sluz->fetch('tpls/var_scope.stpl');
like($out, qr/SCOPE:15/, 'Fetch #3 - var_scope.stpl renders parent vars (15)');

# -------------------------------------------------------------------
# Upstream Fetch #2 - missing template via direct fetch()
# (also covered by t/11-errors.t #42280; kept here for upstream parity)
# -------------------------------------------------------------------
eval { $sluz->fetch('tpls/no_such_template.stpl') };
like($@, qr/#42280/, 'Fetch #4 - Missing template file');

$sluz->assign('secret', '');

done_testing();
