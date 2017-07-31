use warnings;
use strict;

use Test::More tests => 4;

BEGIN { use_ok "Scope::Cleanup", qw(establish_cleanup); }

establish_cleanup sub { sub { pass }->((42) x 100_000); };
pass;

END { pass; }

1;
