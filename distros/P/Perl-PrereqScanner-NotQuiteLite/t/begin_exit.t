use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use Test::More;
use t::Util;

test('exit out of BEGIN', <<'END', {'strict' => 0}, {}, {});
exit; # evaluate after use

use strict;
END

test('exit out of BEGIN, conditional', <<'END', {'strict' => 0}, {}, {});
exit if $^O eq 'MSWin32';

use strict;
END

test('exit inside BEGIN', <<'END', {}, {}, {});
BEGIN {
  # comment to avoid shortcut
  exit;
}

use strict;
END

test('exit inside sub BEGIN', <<'END', {}, {}, {});
sub BEGIN {
  # comment to avoid shortcut
  exit;
}

use strict;
END

test('exit inside BEGIN if', <<'END', {}, {}, {'strict' => 0});
sub BEGIN {
  exit if $^O eq 'MSWin32';
}

use strict;
END

test('exit inside BEGIN if block', <<'END', {}, {}, {'strict' => 0});
BEGIN {
  if ($^O eq 'MSWin32') {
    # comment to avoid shortcut
    exit
  }
}

use strict;
END

done_testing;
