use strict;
use warnings;
use lib 't/lib';

use Std;

use Test::Deep qw(true false);

{
  check_tests(
    sub {
      cmp_deeply(1, bool(1), "num 1");
      cmp_deeply(1, true, "num 1");
      cmp_deeply("abds", bool(1), "string");
      cmp_deeply("abds", true, "string");
      cmp_deeply(0, bool(0), "num 0");
      cmp_deeply(0, false, "num 0");
      cmp_deeply("", bool(0), "string");
      cmp_deeply("", false, "string");
      cmp_deeply(undef, bool(0), "undef");
      cmp_deeply(undef, false, "undef");
    },
    [
      ({
        actual_ok => 1,
        diag => "",
      }) x 10
    ],
    "ok"
  );

  check_tests(
    sub {
      cmp_deeply(1, bool(0), "num 1");
      cmp_deeply(1, false, "num 1");
      cmp_deeply("abds", bool(0), "string");
      cmp_deeply("abds", false, "string");
      cmp_deeply(0, bool(1), "num 0");
      cmp_deeply(0, true, "num 0");
      cmp_deeply("", bool(1), "string");
      cmp_deeply("", true, "string");
    },
    [
      ({
        actual_ok => 0,
        diag => <<EOM,
Comparing \$data as a boolean
   got : true ('1')
expect : false ('0')
EOM
      }) x 2,
      ({
        actual_ok => 0,
      }) x 6,
    ],
    "string not eq"
  );
}
