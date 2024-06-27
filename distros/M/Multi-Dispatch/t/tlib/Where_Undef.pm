package Where_Undef;

use 5.022;
use warnings;

use Multi::Dispatch;

multi foo :where(undef) () {}

1; # Magic true value required at end of module
