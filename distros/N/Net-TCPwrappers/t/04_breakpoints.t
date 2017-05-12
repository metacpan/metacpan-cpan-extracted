#
# $Id: 04_breakpoints.t 151 2004-12-26 22:35:29Z james $
#

use strict;
use warnings;

use Test::More;
eval "use Test::NoBreakpoints 0.10";
plan skip_all => "Test::NoBreakpoints 0.10 required for testing" if $@;
plan 'no_plan';
all_files_no_brkpts_ok();

#
# EOF
