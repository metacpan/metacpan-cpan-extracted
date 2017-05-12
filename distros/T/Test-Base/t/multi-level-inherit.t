use strict;
use lib -e 't' ? 't' : 'test';

use TestBaseTestC tests => 2;

no_diff;
pass 'It works';

run_is();

sub upper { uc }

__DATA__
=== First
--- x upper
foo
--- y
FOO
