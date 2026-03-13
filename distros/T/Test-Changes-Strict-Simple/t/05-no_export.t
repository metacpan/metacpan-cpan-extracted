use strict;
use warnings;

use Test::More tests => 1;

use Test::Changes::Strict::Simple -empty_line_after_version => 1, -no_export => 1;

ok(!main->can('changes_strict_ok'), "changes_strict_ok not exported");

