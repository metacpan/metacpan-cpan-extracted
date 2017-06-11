use strict;
use warnings;
print <<'END_TAP';
1..5
not ok 1
ok 2
... junk
not ok 3 # TODO
not ok 4
ok 5
END_TAP
