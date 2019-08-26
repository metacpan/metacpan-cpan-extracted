use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../";
use Test::More;
use t::Util;

test_cpanfile('no features', sub {
  my $tmpdir = shift;

  test_file("$tmpdir/lib/MyTest.pm", <<'END');
use strict;
use warnings;
use Foo;
END

  test_file("$tmpdir/lib/MyTest/FeatureA/Bar.pm", <<'END');
use strict;
use warnings;
use Bar;
END

  test_file("$tmpdir/lib/MyTest/FeatureB/Baz.pm", <<'END');
use strict;
use warnings;
use Baz;
END
}, {}, <<'CPANFILE');
requires 'Bar';
requires 'Baz';
requires 'Foo';
requires 'strict';
requires 'warnings';
CPANFILE

test_cpanfile('feature', sub {
  my $tmpdir = shift;

  test_file("$tmpdir/lib/MyTest.pm", <<'END');
use strict;
use warnings;
use Foo;
END

  test_file("$tmpdir/lib/MyTest/FeatureA/Bar.pm", <<'END');
use strict;
use warnings;
use Bar;
END

  test_file("$tmpdir/lib/MyTest/FeatureB/Baz.pm", <<'END');
use strict;
use warnings;
use Baz;
END
}, {features => [qw!A:A:lib/MyTest/FeatureA!]}, <<'CPANFILE');
requires 'Baz';
requires 'Foo';
requires 'strict';
requires 'warnings';
feature 'A', 'A' => sub {
    requires 'Bar';
};
CPANFILE

test_cpanfile('features glob', sub {
  my $tmpdir = shift;

  test_file("$tmpdir/lib/MyTest.pm", <<'END');
use strict;
use warnings;
use Foo;
END

  test_file("$tmpdir/lib/MyTest/FeatureA/Bar.pm", <<'END');
use strict;
use warnings;
use Bar;
END

  test_file("$tmpdir/lib/MyTest/FeatureB/Baz.pm", <<'END');
use strict;
use warnings;
use Baz;
END
}, {features => [qw!features:features:lib/MyTest/Feature*!]}, <<'CPANFILE');
requires 'Foo';
requires 'strict';
requires 'warnings';
feature 'features', 'features' => sub {
    requires 'Bar';
    requires 'Baz';
};
CPANFILE

done_testing;
