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

test('plan(skip_all => ...)', <<'END', {}, {}, {'strict' => 0, 'Test::More' => 0}); # INGY/perl5-0.21/t/release-pod-syntax.t
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}

use strict;
END

done_testing;
