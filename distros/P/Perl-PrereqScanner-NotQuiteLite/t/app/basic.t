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

test_app('ignore Makefile.PL under t', sub {
  my $tmpdir = shift;

  test_file("$tmpdir/t/Makefile.PL", <<'END');
use strict;
use warnings;
use Foo;
END
}, {});

done_testing;
