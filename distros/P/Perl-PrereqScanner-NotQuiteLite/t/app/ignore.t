use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../";
use Test::More;
use t::Util;

test_app('ignore a file', sub {
  my $tmpdir = shift;

  test_file("$tmpdir/lib/MyTest.pm", <<'END');
use strict;
use warnings;
use Foo;
END

  test_file("$tmpdir/lib/MyTest/Win32.pm", <<'END');
use strict;
use warnings;
use Win32;
END
END
}, {ignore => [qw!lib/MyTest/Win32.pm!]}, { runtime => { requires => { Foo => 0, strict => 0, warnings => 0 }}});

test_app('ignore a dir', sub {
  my $tmpdir = shift;

  test_file("$tmpdir/lib/MyTest.pm", <<'END');
use strict;
use warnings;
use Foo;
END

  test_file("$tmpdir/lib/MyTest/Win32.pm", <<'END');
use strict;
use warnings;
use Win32;
END
END
}, {ignore => [qw!lib/MyTest/!]}, { runtime => { requires => { Foo => 0, strict => 0, warnings => 0 }}});

test_app('ignore_re', sub {
  my $tmpdir = shift;

  test_file("$tmpdir/lib/MyTest.pm", <<'END');
use strict;
use warnings;
use Foo;
END

  test_file("$tmpdir/lib/MyTest/Win32.pm", <<'END');
use strict;
use warnings;
use Win32;
END
END
}, {ignore_re => 'lib/MyTest/'}, { runtime => { requires => { Foo => 0, strict => 0, warnings => 0 }}});

done_testing;
