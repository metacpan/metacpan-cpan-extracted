use strict;
use warnings;

use lib 'xt/lib';
use RT::Extension::BriefHistory::Test nodb => 1, tests => undef;

require_ok("RT::Extension::BriefHistory");
require_ok("RT::Extension::BriefHistory::Test");

done_testing;
