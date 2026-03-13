use strict;
use warnings;

use Test::More;
use Test::Builder::Tester;

use Test::Changes::Strict::Simple -check_dots => 0;

use FindBin;
use lib "$FindBin::Bin/lib";

use Local::Test::Helper qw(write_changes set_test_out_all_ok);

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
  set_test_out_all_ok();
  changes_strict_ok(changes_file => $fname);
  test_test("valid Changes file passes");
}


# -------------------------------------------------------------------------------------------------

done_testing;
