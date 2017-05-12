package Seis::Order;
use strict;
use warnings;
use utf8;
use 5.010_001;

package # Hide from PAUSE
    Order;

use constant {
    Increase => -1,
    Same => 0,
    Decrease => 1,
};

1;

