use strict;
use warnings;

use Test::More tests => 2;

BEGIN {
    use_ok ('Net::TrackUPS');
    use_ok ('Net::TrackUPS', 0.01);
}
