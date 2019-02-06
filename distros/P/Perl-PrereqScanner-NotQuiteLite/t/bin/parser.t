use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../";
use Test::More;
use t::Util;

test_bin(':bundled', sub {
  my $tmpdir = shift;

  test_file("$tmpdir/MyTest.pm", <<'END');
use strict;
use warnings;
use base 'Foo';
use Moo;

with 'Bar';
END
}, [qw/--parser :bundled/], <<'CPANFILE');
requires 'Bar';
requires 'Foo';
requires 'Moo';
requires 'base';
requires 'strict';
requires 'warnings';
CPANFILE

test_bin('Core only', sub {
  my $tmpdir = shift;

  test_file("$tmpdir/MyTest.pm", <<'END');
use strict;
use warnings;
use base 'Foo';
use Moo;

with 'Bar';
END
}, [qw/--parser Core/], <<'CPANFILE');
requires 'Foo';
requires 'Moo';
requires 'base';
requires 'strict';
requires 'warnings';
CPANFILE

test_bin('multiple parsers', sub {
  my $tmpdir = shift;

  test_file("$tmpdir/MyTest.pm", <<'END');
use strict;
use warnings;
use base 'Foo';
use Moo;

with 'Bar';
END
}, [qw/--parser Core --parser Moose/], <<'CPANFILE');
requires 'Bar';
requires 'Foo';
requires 'Moo';
requires 'base';
requires 'strict';
requires 'warnings';
CPANFILE

done_testing;
