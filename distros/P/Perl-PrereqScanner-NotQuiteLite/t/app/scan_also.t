use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../";
use Test::More;
use t::Util;

test_app('modules under unknown directories are ignored by default', sub {
  my $tmpdir = shift;

  test_file("$tmpdir/lib/MyTest.pm", <<'END');
use strict;
use warnings;
use Foo;
END

  test_file("$tmpdir/extlib/DistA/lib/MyTest/Bar.pm", <<'END');
use strict;
use warnings;
use Bar;
END

  test_file("$tmpdir/extlib/DistB/lib/MyTest/Baz.pm", <<'END');
use strict;
use warnings;
use Baz;
END
}, {}, { runtime => { requires => { Foo => 0, strict => 0, warnings => 0 }}});

test_app('scan_also', sub {
  my $tmpdir = shift;

  test_file("$tmpdir/lib/MyTest.pm", <<'END');
use strict;
use warnings;
use Foo;
END

  test_file("$tmpdir/extlib/DistA/lib/MyTest/Bar.pm", <<'END');
use strict;
use warnings;
use Bar;
END

  test_file("$tmpdir/extlib/DistB/lib/MyTest/Baz.pm", <<'END');
use strict;
use warnings;
use Baz;
END
}, {scan_also => [qw!extlib/DistA/lib!]}, { runtime => { requires => { Foo => 0, Bar => 0, strict => 0, warnings => 0 }}});

test_app('scan_also glob', sub {
  my $tmpdir = shift;

  test_file("$tmpdir/lib/MyTest.pm", <<'END');
use strict;
use warnings;
use Foo;
END

  test_file("$tmpdir/extlib/DistA/lib/MyTest/Bar.pm", <<'END');
use strict;
use warnings;
use Bar;
END

  test_file("$tmpdir/extlib/DistB/lib/MyTest/Baz.pm", <<'END');
use strict;
use warnings;
use Baz;
END
}, {scan_also => [qw!extlib/*/lib!]}, { runtime => { requires => { Foo => 0, Bar => 0, Baz => 0, strict => 0, warnings => 0 }}});

done_testing;
