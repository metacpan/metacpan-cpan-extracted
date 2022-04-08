use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../";
use Test::More;
use t::Util;

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

test_app('ignore core modules with undef version', sub {
  my $tmpdir = shift;

  test_file("$tmpdir/MyTest.pm", <<'END');
use strict;
use warnings;
use Foo;
END
}, {exclude_core => 1, perl_version => 5.006}, { runtime => { requires => { Foo => 0 }}});

done_testing;
