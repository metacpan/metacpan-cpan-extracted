use strict;
use warnings;

use Test::More tests => 2;

BEGIN {
    use_ok ('RT::Client::REST');
    use_ok ('RT::Client::REST', 0.06);
}

# vim:ft=perl:
