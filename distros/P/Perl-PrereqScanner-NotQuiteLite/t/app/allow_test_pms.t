use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../";
use Test::More;
use t::Util;

test_app('ignore .pm files under t unless they are used in .t files', sub {
  my $tmpdir = shift;

  test_file("$tmpdir/t/test.t", <<'END');
use strict;
use warnings;
use t::lib::Util;
END

  test_file("$tmpdir/t/lib/Util.pm", <<'END');
use strict;
use warnings;
use Foo;
END

  test_file("$tmpdir/t/lib/Corpus.pm", <<'END');
use strict;
use warnings;
use Bar;
END
}, {}, { test => { requires => { strict => 0, warnings => 0, Foo => 0 }}});

test_app('respect .pm files under t if allow-test-pms is set', sub {
  my $tmpdir = shift;

  test_file("$tmpdir/t/test.t", <<'END');
use strict;
use warnings;
use t::lib::Util;
END

  test_file("$tmpdir/t/lib/Util.pm", <<'END');
use strict;
use warnings;
use Foo;
END

  test_file("$tmpdir/t/lib/Corpus.pm", <<'END');
use strict;
use warnings;
use Bar;
END
}, {allow_test_pms => 1}, { test => { requires => { strict => 0, warnings => 0, Foo => 0, Bar => 0}}});

test_app('respect .pm files under t if Test::Class is used', sub {
  my $tmpdir = shift;

  test_file("$tmpdir/t/test.t", <<'END');
use strict;
use warnings;
use Test::Class;
use t::lib::Util;
END

  test_file("$tmpdir/t/lib/Util.pm", <<'END');
use strict;
use warnings;
use Foo;
END

  test_file("$tmpdir/t/lib/Corpus.pm", <<'END');
use strict;
use warnings;
use Bar;
END
}, {}, { test => { requires => { strict => 0, warnings => 0, 'Test::Class' => 0, Foo => 0, Bar => 0 }}});

done_testing;
