use strict;
use warnings;

package t::Parent; {
    use Object::InsideOut;
}

sub parent_func {
    return 1;
}

1;

# EOF
