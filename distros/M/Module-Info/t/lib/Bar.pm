package Bar;

use Cwd;
use Cwd 1;
use Cwd 1.00102;
use Cwd 1.1.2;

BEGIN {
    cwd();
}

BEGIN {
    $x = 1;
    $x = 2;
    require strict;
}

sub my_croak {
    require Carp;
    Carp::croak(cwd, @_);
}

1;
