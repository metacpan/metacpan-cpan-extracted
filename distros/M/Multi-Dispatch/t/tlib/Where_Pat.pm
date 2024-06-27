package Where_Pat;

use 5.022;
use warnings;

use Multi::Dispatch;

multi foo :where(/regex/) () {}

1; # Magic true value required at end of module
