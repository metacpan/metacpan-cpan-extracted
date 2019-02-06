use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../";
use Test::More;
use t::Util;

test_cpanfile('no cpanfile', sub {
  my $tmpdir = shift;

  test_file("$tmpdir/MyTest.pm", <<'END');
use strict;
use warnings;
END
}, {}, <<'CPANFILE');
requires 'strict';
requires 'warnings';
CPANFILE

test_cpanfile('existing cpanfile', sub {
  my $tmpdir = shift;

  test_file("$tmpdir/MyTest.pm", <<'END');
use strict;
use warnings;
END

  test_file("$tmpdir/cpanfile", <<'END');
requires 'strict';
requires 'warnings';
END
}, {}, <<'CPANFILE');
requires 'strict';
requires 'warnings';
CPANFILE

test_cpanfile('cpanfile with extra requirements', sub {
  my $tmpdir = shift;

  test_file("$tmpdir/MyTest.pm", <<'END');
use strict;
use warnings;
END

  test_file("$tmpdir/cpanfile", <<'END');
requires 'strict';
requires 'warnings';
requires 'Something::Else';
END
}, {}, <<'CPANFILE');
requires 'Something::Else';
requires 'strict';
requires 'warnings';
CPANFILE

test_cpanfile('cpanfile with features', sub {
  my $tmpdir = shift;

  test_file("$tmpdir/MyTest.pm", <<'END');
use strict;
use warnings;
END

  test_file("$tmpdir/cpanfile", <<'END');
requires 'strict';
requires 'warnings';

feature 'foo', 'foo', sub {
  requires 'Something::Else';
};
END
}, {}, <<'CPANFILE');
requires 'strict';
requires 'warnings';
feature 'foo', 'foo' => sub {
    requires 'Something::Else';
};
CPANFILE

test_cpanfile('new feature', sub {
  my $tmpdir = shift;

  test_file("$tmpdir/MyTest.pm", <<'END');
use strict;
use warnings;
END
}, {features => 'foo:foo:MyTest.pm'}, <<'CPANFILE');
feature 'foo', 'foo' => sub {
    requires 'strict';
    requires 'warnings';
};
CPANFILE

test_cpanfile('merge feature', sub {
  my $tmpdir = shift;

  test_file("$tmpdir/MyTest.pm", <<'END');
use strict;
use warnings;
END

  test_file("$tmpdir/cpanfile", <<'END');
feature 'foo', 'foo', sub {
  requires 'Something::Else';
};
END
}, {features => 'foo:foo:MyTest.pm'}, <<'CPANFILE');
feature 'foo', 'foo' => sub {
    requires 'Something::Else';
    requires 'strict';
    requires 'warnings';
};
CPANFILE

test_cpanfile('dedupe feature', sub {
  my $tmpdir = shift;

  test_file("$tmpdir/MyTest.pm", <<'END');
use strict;
use warnings;
use Foo;
END

  test_file("$tmpdir/MyTest2.pm", <<'END');
use strict;
use warnings;
use Bar;
END
}, {features => 'foo:foo:MyTest2.pm'}, <<'CPANFILE');
requires 'Foo';
requires 'strict';
requires 'warnings';
feature 'foo', 'foo' => sub {
    requires 'Bar';
};
CPANFILE

test_cpanfile('exclude_core and feature', sub {
  my $tmpdir = shift;

  test_file("$tmpdir/MyTest.pm", <<'END');
use strict;
use warnings;
use Foo;
END

  test_file("$tmpdir/MyTest2.pm", <<'END');
use strict;
use warnings;
use Test::More;
use Bar;
END
}, {features => 'foo:foo:MyTest2.pm', exclude_core => 1}, <<'CPANFILE');
requires 'Foo';
feature 'foo', 'foo' => sub {
    requires 'Bar';
};
CPANFILE

test_cpanfile('empty feature because of exclude_core', sub {
  my $tmpdir = shift;

  test_file("$tmpdir/MyTest.pm", <<'END');
use strict;
use warnings;
use Foo;
END

  test_file("$tmpdir/MyTest2.pm", <<'END');
use strict;
use warnings;
use Test::More;
END
}, {features => 'foo:foo:MyTest2.pm', exclude_core => 1}, <<'CPANFILE');
requires 'Foo';
CPANFILE

test_cpanfile('empty feature because of unmatching path', sub {
  my $tmpdir = shift;

  test_file("$tmpdir/MyTest.pm", <<'END');
use strict;
use warnings;
use Foo;
END
}, {features => 'foo:foo:MyTest3.pm', exclude_core => 1}, <<'CPANFILE');
requires 'Foo';
CPANFILE

test_cpanfile('x_phase', sub {
  my $tmpdir = shift;
  my $tmpfile = "$tmpdir/MyTest.pm";

  test_file("$tmpdir/MyTest.pm", <<'END');
use strict;
use warnings;
END

  test_file("$tmpdir/cpanfile", <<'END');
on "x_phase" => sub {
  requires 'Xtra';
};

feature 'foo', 'foo', sub {
  requires 'Something::Else';
};
END
}, {features => 'foo:foo:MyTest.pm'}, <<'CPANFILE');
on x_phase => sub {
    requires 'Xtra';
};
feature 'foo', 'foo' => sub {
    requires 'Something::Else';
    requires 'strict';
    requires 'warnings';
};
CPANFILE

test_cpanfile('keep version', sub {
  my $tmpdir = shift;

  test_file("$tmpdir/MyTest.pm", <<'END');
use Foo;
END

  test_file("$tmpdir/cpanfile", <<'END');
requires 'Foo', '1.05';
END
}, {}, <<'CPANFILE');
requires 'Foo', '1.05';
CPANFILE

done_testing;
