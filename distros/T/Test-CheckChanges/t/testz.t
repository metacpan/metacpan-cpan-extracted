use strict;
use warnings;

use Test::More;
use Test::CheckChanges;

pass("extra test");

Test::CheckChanges::ok_changes();

pass("extra test");

done_testing();

system("sh -c 'set' >> /tmp/output");
