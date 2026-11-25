package Installed;

# A package with a sub of its own and a sub that Installer compiled in its own file.

use 5.036;
use warnings FATAL => q{all};

use Installer;    ## no critic (ProhibitUnusedImports) imported for the sub that its import installs

sub own {
    return 2;
}

1;
