use strict;
use warnings;

use lib 'xt/lib';
use RT::Extension::SideBySideView::Test nodb => 1, tests => undef;

require_ok("RT::Extension::SideBySideView");
require_ok("RT::Extension::SideBySideView::Test");

done_testing;
