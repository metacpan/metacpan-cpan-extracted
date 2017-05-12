use strict;
use warnings;
use Test::More;
use t::Util;

test_app(sub {
  my $tmpdir = shift;
  my $tmpfile = "$tmpdir/MyTest.pm";

  test_file("$tmpdir/MyTest.pm", <<'END');
use strict;
use warnings;
END
}, { runtime => { requires => { strict => 0, warnings => 0 }}});

done_testing;
