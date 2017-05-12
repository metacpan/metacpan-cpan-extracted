use Test::More tests => 2 + 2;
BEGIN { $^W = 1 }
use strict;

my $module = 'Regexp::Exhaustive';

require_ok($module);
ok(! defined &exhaustive);

use_ok($module, qw/ &exhaustive /);
ok(defined &exhaustive, '&exhaustive');
