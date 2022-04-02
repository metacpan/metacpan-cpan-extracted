use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../";
use Test::More;
use t::Util;

test_app('optional file', sub {
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
}, {optional => [qw!lib/MyTest/Win32.pm!]}, { runtime => { requires => { Foo => 0, strict => 0, warnings => 0 }, suggests => { Win32 => 0 }}});

test_app('optional dir', sub {
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
}, {optional => [qw!lib/MyTest/!]}, { runtime => { requires => { Foo => 0, strict => 0, warnings => 0}, suggests => { Win32 => 0 }}});

test_app('optional_re', sub {
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
}, {optional_re => 'lib/MyTest/'}, { runtime => { requires => { Foo => 0, strict => 0, warnings => 0 }, suggests => { Win32 => 0 }}});

done_testing;
