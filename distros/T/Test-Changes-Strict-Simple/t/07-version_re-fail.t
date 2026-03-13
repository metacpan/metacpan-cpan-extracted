use strict;
use warnings;

use Test::More;
use Test::Builder::Tester;

use Test::Changes::Strict::Simple -version_re => qr/\d+\.\d+\.\d+/;

use FindBin;
use lib "$FindBin::Bin/lib";

use Local::Test::Helper qw(write_changes);

{
  note("initial version has wrong format");
  my $fname = write_changes(<<'EOF');
Revision history for distribution Foo-Bar-Baz

0.02.01 2024-03-01
  - Bugfix.
  - Donec quam felis.

0.01 2024-02-28
  - Initial release.

EOF
  test_out("not ok 1 - Changes file passed strict checks");
  test_fail(+2);
  test_diag("Line 7: version check: 0.01: invalid version");
  changes_strict_ok(changes_file => $fname);
  test_test("fail works");
}


# -------------------------------------------------------------------------------------------------

done_testing;


