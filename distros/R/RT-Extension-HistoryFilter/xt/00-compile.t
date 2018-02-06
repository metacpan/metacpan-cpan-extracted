use strict;
use warnings;

use lib 'xt/lib';
use RT::Extension::HistoryFilter::Test nodb => 1, tests => undef;

require_ok("RT::Extension::HistoryFilter");
require_ok("RT::Extension::HistoryFilter::Test");

done_testing;
