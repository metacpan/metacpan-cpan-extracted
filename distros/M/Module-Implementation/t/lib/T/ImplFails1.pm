package T::ImplFails1;

use strict;
use warnings;

sub return_42 {
    return 42;
}

sub return_package {
    return __PACKAGE__;
}

die 'Error loading something or other';

1;
