#!perl
#
# Lightweight mock implementation of File::HomeDir for testing

package File::HomeDir;

use FindBin;

sub my_home { return $FindBin::Bin; }

1;
