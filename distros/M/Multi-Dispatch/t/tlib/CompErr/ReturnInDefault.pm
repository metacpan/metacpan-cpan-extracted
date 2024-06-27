package CompErr::ReturnInDefault;

use 5.022;
use warnings;

use Multi::Dispatch;

multi foo($req, $opt = return) {}

BEGIN { foo(1) }


1; # Magic true value required at end of module
