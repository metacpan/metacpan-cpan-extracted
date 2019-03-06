package Module::Lazy::_::test::mro::base;

use strict;
use warnings;
our $VERSION = 1;

sub frobnicate {
    return "should be unreachable";
};
sub frob {
    return "old-";
};
sub nicate {
    return "-old";
};

1;
