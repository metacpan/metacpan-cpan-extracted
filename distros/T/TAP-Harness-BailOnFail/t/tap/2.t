use strict;
use warnings;
print <<'END_TAP';
1..5
ok 1
ok 2
not ok 3 # TODO
not ok 4
not ok 5
END_TAP
