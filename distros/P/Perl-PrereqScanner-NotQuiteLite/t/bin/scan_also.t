use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../";
use Test::More;
use t::Util;

test_bin('also scan extlib', sub {
  my $tmpdir = shift;

  test_file("$tmpdir/MyTest.pm", <<'END');
use strict;
use warnings;
use Foo;
END

  test_file("$tmpdir/extlib/MyTest2.pm", <<'END');
use strict;
use warnings;
use Bar;
END
}, [qw/--scan-also extlib/], <<'CPANFILE');
requires 'Bar';
requires 'Foo';
requires 'strict';
requires 'warnings';
CPANFILE

test_bin('also and local', sub {
  my $tmpdir = shift;

  test_file("$tmpdir/MyTest.pm", <<'END');
use strict;
use warnings;
use Foo; # --scan-also makes this a local module
END

  test_file("$tmpdir/extlib/Foo.pm", <<'END');
use strict;
use warnings;
use Bar;
END
}, [qw/--also extlib/], <<'CPANFILE');
requires 'Bar';
requires 'strict';
requires 'warnings';
CPANFILE

test_bin('also and test files', sub {
  my $tmpdir = shift;

  test_file("$tmpdir/MyTest.pm", <<'END');
use strict;
use warnings;
use Foo; # t/Foo.pm is not a local file
END

  test_file("$tmpdir/extlib/Foo/t/load.t", <<'END');
use strict;
use warnings;
use Test::More;
END

  # this is not used from .t files and thus ignored
  test_file("$tmpdir/extlib/Foo/t/Foo.pm", <<'END');
use strict;
use warnings;
use Bar;
END
}, [qw/--scan-also extlib/], <<'CPANFILE');
requires 'Foo';
requires 'strict';
requires 'warnings';

on test => sub {
    requires 'Test::More';
    requires 'strict';
    requires 'warnings';
};
CPANFILE

done_testing;
