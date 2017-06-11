use strict;
use warnings;
print <<'END_TAP';
1..5
ok 1
ok 2
not ok 3 # TODO
ok 4
ok 5
END_TAP
