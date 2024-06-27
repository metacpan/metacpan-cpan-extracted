package Where_ClassName;

use 5.022;
use warnings;

use Multi::Dispatch;

multi foo :where(ClassName) () {}

1; # Magic true value required at end of module

