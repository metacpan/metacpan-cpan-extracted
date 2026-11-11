package Punk::Kit::Fakebroken;

# t/1316's fixture: a kit that is installed but does not load. `punk new`
# tells this apart from a kit that is missing, since one is a cpanm away and
# the other is a bug in something already on @INC.

use strict;
use warnings;

die "broken on purpose\n";

1;
