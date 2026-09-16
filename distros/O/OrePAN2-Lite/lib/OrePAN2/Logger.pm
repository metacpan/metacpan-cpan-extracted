package OrePAN2::Logger;

use strict;
use warnings;

use Role::Tiny;

our $VERSION = '2.0.0';

# trace
# debug
# info (inform)
sub info { return print {*STDERR} "[INFO] $_[1]\n"; }

# notice
# warning (warn)
sub warn { return print {*STDERR} "[WARN] $_[1]\n"; }

# error (err)
# critical (crit, fatal)
# alert
# emergency

1;
