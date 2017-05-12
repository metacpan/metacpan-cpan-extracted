use strict;
use warnings;

use lib 'xt/lib';
use RT::Extension::Gravatar::Test nodb => 1, tests => undef;

require_ok("RT::Extension::Gravatar");
require_ok("RT::Extension::Gravatar::Test");

done_testing;
