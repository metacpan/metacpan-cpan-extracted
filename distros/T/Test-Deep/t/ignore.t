use strict;
use warnings;
use lib 't/lib';

use Std;

{
  check_test(
    sub {
      cmp_deeply([[{}, "argh"], ["b"]], [ignore(), ["b"]]);
    },
    {
      actual_ok => 1,
      diag => "",
    },
    "ignore"
  );
}
