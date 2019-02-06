use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../";
use Test::More;
use t::Util;

test_bin('no options', sub {
  my $tmpdir = shift;

  test_file("$tmpdir/MyTest.pm", <<'END');
use strict;
use warnings;
END
}, [], <<'CPANFILE');
requires 'strict';
requires 'warnings';
CPANFILE

done_testing;
