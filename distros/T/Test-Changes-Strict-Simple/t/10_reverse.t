use strict;
use warnings;

use Test::More;
use Test::Builder::Tester;

use Test::Changes::Strict::Simple -reverse_version_order => 1;

use FindBin;
use lib "$FindBin::Bin/lib";

use Local::Test::Helper qw(write_changes set_test_out_all_ok);



{
  note("good case: multiple entries, some with line continuation, 2 versions same day");
  my $valid_changes = write_changes(<<'EOF');
Revision history for distribution Foo-Bar-Baz

0.01 2024-02-28
  - Initial release. This will hopefully work
    fine.

0.02 2024-03-01
  - Bugfix.
  - Added a very fancy feature that alllows this
    and that.
  - Another bugfix.

0.03 2024-03-01
  - Another version, same day.

0.04 2025-03-01
  - Best version ever.

EOF
  set_test_out_all_ok();
  changes_strict_ok(changes_file => $valid_changes);
  test_test("valid Changes file passes");
}

{
  note("bad case: wrong order of versions");
  my $fname = write_changes(<<"EOF");
Revision history for distribution Foo-Bar-Baz

0.01 2024-02-28
  - Initial release.

0.03 2024-04-03
  - Donec quam felis.
  - Etiam ultricies nisi vel augue. Curabitur ullamcorper ultricies nisi.
    Donec sodales sagittis magna.

0.02 2024-10-12
  - Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo
    ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis
    dis parturient montes, nascetur ridiculus mus.

1.00 2025-01-21
  - Bugfix.
EOF
  test_out("not ok 1 - Changes file passed strict checks");
  test_fail(+2);
  test_diag("0.02 vs. 0.03: wrong order of versions");
  changes_strict_ok(changes_file => $fname);
  test_test("fail works");
}
{
  note("bad case: version dates chronologically inconsistent");
  my $fname = write_changes(<<"EOF");
Revision history for distribution Foo-Bar-Baz

0.01 2024-02-28
  - Initial release.

0.02 2024-10-12
  - Donec quam felis.
  - Etiam ultricies nisi vel augue. Curabitur ullamcorper ultricies nisi.
    Donec sodales sagittis magna.

0.03 2024-04-03
  - Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo
    ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis
    dis parturient montes, nascetur ridiculus mus.

1.00 2025-01-21
  - Bugfix.
EOF
  test_out("not ok 1 - Changes file passed strict checks");
  test_fail(+2);
  test_diag("date 2024-04-03 < 2024-10-12: chronologically inconsistent");
  changes_strict_ok(changes_file => $fname);
  test_test("fail works");
}


# -------------------------------------------------------------------------------------------------

done_testing;

