use strict;
use warnings;

use Test::More;
use Test::Builder::Tester;

use Test::Changes::Strict::Simple -check_dots => 1;

use FindBin;
use lib "$FindBin::Bin/lib";

use Local::Test::Helper qw(write_changes);

{
  note("missing dot at end of line");
  my $fname = write_changes(<<'EOF');
Revision history for distribution Foo-Bar-Baz

0.02 2024-03-01
  - Bugfix.
  - Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo
    ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis
    dis parturient montes, nascetur ridiculus mus
  - Donec quam felis.

0.01 2024-02-28
  - Initial release

EOF
  test_out("not ok 1 - Changes file passed strict checks");
  test_fail(+3);
  test_diag("Line 7: missing dot at end of line");
  test_diag("Line 11: missing dot at end of line");
  changes_strict_ok(changes_file => $fname);
  test_test("fail works");
}


# -------------------------------------------------------------------------------------------------

done_testing;
