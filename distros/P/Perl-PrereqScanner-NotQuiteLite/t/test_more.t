use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use Test::More;
use t::Util;

test('skip_all out of BEGIN', <<'END', {'Test::More' => 0, 'strict' => 0});
use Test::More;

plan skip_all => 'foo';

use strict;
END

test('skip_all inside BEGIN', <<'END', {'Test::More' => 0}, {}, {'strict' => 0});
use Test::More;

BEGIN {
  plan skip_all => 'foo';
}

use strict;
END

test('skip_all inside sub BEGIN', <<'END', {'Test::More' => 0}, {}, {'strict' => 0});
use Test::More;

sub BEGIN {
  plan skip_all => 'foo';
}

use strict;
END

test('skip_all inside BEGIN if', <<'END', {'Test::More' => 0}, {}, {'strict' => 0});
use Test::More;

sub BEGIN {
  plan skip_all => 'foo' if $^O eq 'MSWin32';
}

use strict;
END

test('"skip_all"', <<'END', {'Test::More' => 0}, {}, {'strict' => 0});
use Test::More;

sub BEGIN {
  plan 'skip_all' => 'foo' if $^O eq 'MSWin32';
}

use strict;
END

done_testing;
