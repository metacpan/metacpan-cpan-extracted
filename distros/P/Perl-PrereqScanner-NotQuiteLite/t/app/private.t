use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../";
use Test::More;
use t::Util;

test_app('ignore a private module', sub {
  my $tmpdir = shift;

  test_file("$tmpdir/lib/MyTest.pm", <<'END');
use strict;
use warnings;
use Foo;
END

  test_file("$tmpdir/lib/MyTest/Win32.pm", <<'END');
use strict;
use warnings;
use Bar;
use My::Win32;
END
}, {private => [qw!My::Win32!]}, { runtime => { requires => { Foo => 0, Bar => 0, strict => 0, warnings => 0 }}});


test_app('private_re', sub {
  my $tmpdir = shift;

  test_file("$tmpdir/lib/MyTest.pm", <<'END');
use strict;
use warnings;
use Foo;
END

  test_file("$tmpdir/lib/MyTest/Win32.pm", <<'END');
use strict;
use warnings;
use Bar;
use My::Win32;
use My::Unix;
END
}, {private_re => '^My::'}, { runtime => { requires => { Foo => 0, Bar => 0, strict => 0, warnings => 0 }}});

done_testing;
