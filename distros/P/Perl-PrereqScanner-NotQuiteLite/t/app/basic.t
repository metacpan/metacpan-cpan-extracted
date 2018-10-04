use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../";
use Test::More;
use t::Util;

test_app('.pm file in the root', sub {
  my $tmpdir = shift;

  test_file("$tmpdir/MyTest.pm", <<'END');
use strict;
use warnings;
END
}, {}, { runtime => { requires => { strict => 0, warnings => 0 }}});

test_app('.pm file under lib', sub {
  my $tmpdir = shift;

  test_file("$tmpdir/lib/MyTest.pm", <<'END');
use strict;
use warnings;
END
}, {}, { runtime => { requires => { strict => 0, warnings => 0 }}});

test_app('inc', sub {
  my $tmpdir = shift;

  test_file("$tmpdir/MyTest.pm", <<'END');
use strict;
use warnings;
use Foo::Bar;
END

  test_file("$tmpdir/inc/Foo/Bar.pm", <<'END');
package Foo::Bar;
1;
END
}, {}, { runtime => { requires => { strict => 0, warnings => 0 }}});

test_app('ignore local file', sub {
  my $tmpdir = shift;

  test_file("$tmpdir/MyTest.pm", <<'END');
use strict;
use warnings;
END

  test_file("$tmpdir/MyTest2.pm", <<'END');
use MyTest;
END
}, {}, { runtime => { requires => { strict => 0, warnings => 0 }}});

test_app('ignore core modules', sub {
  my $tmpdir = shift;

  test_file("$tmpdir/MyTest.pm", <<'END');
use strict;
use warnings;
use Foo;
END
}, {exclude_core => 1}, { runtime => { requires => { Foo => 0 }}});

test_app('do not ignore better core modules', sub {
  my $tmpdir = shift;

  test_file("$tmpdir/MyTest.pm", <<'END');
use strict;
use warnings;
use Exporter 5.57;
END
}, {exclude_core => 1}, { runtime => { requires => { Exporter => '5.57' }}});

test_app('ignore core modules for higher perl version', sub {
  my $tmpdir = shift;

  test_file("$tmpdir/MyTest.pm", <<'END');
use 5.020;
use strict;
use warnings;
use experimental qw/signatures/;
use Foo;
END
}, {exclude_core => 1}, { runtime => { requires => { Foo => 0, perl => '5.020' }}});

test_app('ignore Makefile.PL under t', sub {
  my $tmpdir = shift;

  test_file("$tmpdir/t/Makefile.PL", <<'END');
use strict;
use warnings;
use Foo;
END
}, {});

test_app('ignore .pm files under t unless they are used in .t files', sub {
  my $tmpdir = shift;

  test_file("$tmpdir/t/test.t", <<'END');
use strict;
use warnings;
use t::lib::Util;
END

  test_file("$tmpdir/t/lib/Util.pm", <<'END');
use strict;
use warnings;
use Foo;
END

  test_file("$tmpdir/t/lib/Corpus.pm", <<'END');
use strict;
use warnings;
use Bar;
END
}, {}, { test => { requires => { strict => 0, warnings => 0, Foo => 0 }}});

test_app('dedupe requires from recommends/suggests', sub {
  my $tmpdir = shift;

  test_file("$tmpdir/MyTest.pm", <<'END');
use strict;
use warnings;
END

  test_file("$tmpdir/MyTest2.pm", <<'END');
if (eval { require warnings }) {
  require strict;
}
END
}, {}, { runtime => { requires => { strict => 0, warnings => 0 }}});

test_app('dedupe requires from feature requires/recommends/suggests', sub {
  my $tmpdir = shift;

  test_file("$tmpdir/MyTest.pm", <<'END');
use strict;
use warnings;
END

  test_file("$tmpdir/MyTest2.pm", <<'END');
if (eval { require warnings }) {
  require strict;
}
END
}, {features => 'foo:foo:MyTest2.pm'}, { runtime => { requires => { strict => 0, warnings => 0 }}});

test_app('dedupe recommends from recommends/suggests', sub {
  my $tmpdir = shift;

  test_file("$tmpdir/MyTest.pm", <<'END');
{
  require strict;
  require warnings;
}
END

  test_file("$tmpdir/MyTest2.pm", <<'END');
if (eval { require warnings }) {
  require strict;
}
END
}, {}, { runtime => { recommends => { strict => 0, warnings => 0 }}});

test_app('dedupe recommends from feature recommends/suggests', sub {
  my $tmpdir = shift;

  test_file("$tmpdir/MyTest.pm", <<'END');
{
  require strict;
  require warnings;
}
END

  test_file("$tmpdir/MyTest2.pm", <<'END');
if (eval { require warnings }) {
  require strict;
}
END
}, {features => 'foo:foo:MyTest2.pm'}, { runtime => { recommends => { strict => 0, warnings => 0 }}});

test_app('dedupe suggests from feature suggests', sub {
  my $tmpdir = shift;

  test_file("$tmpdir/MyTest.pm", <<'END');
use strict;
eval { use warnings };
END

  test_file("$tmpdir/MyTest2.pm", <<'END');
if (eval { require warnings }) {
  require strict;
}
END
}, {features => 'foo:foo:MyTest2.pm'}, { runtime => { requires => { strict => 0}, suggests => { warnings => 0 }}});

done_testing;
