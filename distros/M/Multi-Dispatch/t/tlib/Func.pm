package Func;

use 5.022;
use warnings;

use Multi::Dispatch;

multi func ('L') { return 'import local' }
multi func ('I') { return 'import' }
multi func ('O') { return 'import override' }

multi other ('N') { return 'rename' }

1; # Magic true value required at end of module
