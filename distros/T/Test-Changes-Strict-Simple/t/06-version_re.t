use strict;
use warnings;

use Test::More;
use Test::Builder::Tester;

use Test::Changes::Strict::Simple -version_re => qr/\d+\.\d+\.\d+/;

use FindBin;
use lib "$FindBin::Bin/lib";

use Local::Test::Helper qw(write_changes set_test_out_all_ok);

{
  note("A single entry");
  my $valid_changes = write_changes(<<'EOF');
Revision history for distribution Foo-Bar-Baz

0.01.27 2024-02-29
  - Another release.

0.00.01 2024-02-23
  - First release.
EOF
  set_test_out_all_ok();
  changes_strict_ok(changes_file => $valid_changes);
  test_test("valid Changes file passes");
}


# -------------------------------------------------------------------------------------------------

done_testing;
