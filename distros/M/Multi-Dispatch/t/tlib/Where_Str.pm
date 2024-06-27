package Where_Str;

use 5.022;
use warnings;

use Multi::Dispatch;

multi foo :where('string') () {}

1; # Magic true value required at end of module
