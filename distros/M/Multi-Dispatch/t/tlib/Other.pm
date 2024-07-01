package Other 0.000001;

use 5.022;
use warnings;

use Multi::Dispatch;

sub import {
    multi other :export;
}

multi other ($x)     { 'one arg' }
multi other ($x, $y) { 'two args' }

1;
