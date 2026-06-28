use strict;
use warnings;
use Test::More tests => 2;

use PDF::Make;

# --- XS version symbol round-trips through the C core -----------------
my $v = PDF::Make::version();
ok(defined $v,              'PDF::Make::version returned a value');
is($v, $PDF::Make::VERSION, 'C version matches $PDF::Make::VERSION');

