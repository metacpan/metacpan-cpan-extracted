package Where_Num;

use 5.022;
use warnings;

use Multi::Dispatch;

multi foo :where(1) () {}

1; # Magic true value required at end of module
