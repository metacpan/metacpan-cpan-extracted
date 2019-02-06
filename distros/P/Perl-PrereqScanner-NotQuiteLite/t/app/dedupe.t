use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../";
use Test::More;
use t::Util;

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
