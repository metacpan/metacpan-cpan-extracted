use strict;
use warnings;
use lib 't/lib';

use Std;

{
  check_test(
    sub {
      cmp_deeply("wine", none("beer", "wine"))
    },
    {
      actual_ok => 0,
      diag => <<EOM,
Comparing \$data with None
got      : 'wine'
expected : None of ( 'beer', 'wine' )
EOM
    },
    "none eq fail"
  );

  check_test(
    sub {
      cmp_deeply("whisky", none("beer", "wine"))
    },
    {
      actual_ok => 1,
      diag => "",
    },
    "none eq ok"
  );

  check_test(
    sub {
      cmp_deeply("whisky", none("beer") | "wine")
    },
    {
      actual_ok => 1,
      diag => "",
    },
    "none with | match none"
  );

  check_test(
    sub {
      cmp_deeply("wine", none("beer") | "wine")
    },
    {
      actual_ok => 1,
      diag => "",
    },
    "none with | match alternative"
  );

  check_test(
    sub {
      cmp_deeply("beer", none("beer") | "wine")
    },
    {
      actual_ok => 0,
      diag => <<EOM,
Comparing \$data with Any
got      : 'beer'
expected : Any of ( None of ( 'beer' ), 'wine' )
EOM
    },
    "none with | fail"
  );
}
