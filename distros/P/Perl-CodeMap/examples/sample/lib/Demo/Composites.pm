package Demo::First;
use strict;
# First namespace inside one source file.
sub first { return 1 }

package Demo::Second;
# Another namespace from the same source file.
sub second { return 2 }
1;
