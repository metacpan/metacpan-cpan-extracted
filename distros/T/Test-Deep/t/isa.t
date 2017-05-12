use strict;
use warnings;
use lib 't/lib';

use Std;

{
  my $a = {};

  check_test(
    sub {
      cmp_deeply($a, isa("HASH"));
    },
    {
      actual_ok => 1,
      diag => "",
    },
    "isa eq"
  );

  check_test(
    sub {
      cmp_deeply($a, obj_isa("HASH"));
    },
    {
      actual_ok => 0,
      diag => <<EOM,
Checking class of \$data with isa()
   got : $a
expect : blessed into 'HASH' or subclass of 'HASH'
EOM
    },
    "obj_isa eq"
  );
}

{
  my $b = bless {}, "B";

  check_test(
    sub {
      cmp_deeply($b, isa("B"));
    },
    {
      actual_ok => 1,
      diag => "",
    },
    "isa eq"
  );

  check_test(
    sub {
      cmp_deeply($b, obj_isa("B"));
    },
    {
      actual_ok => 1,
      diag => "",
    },
    "isa eq"
  );


  check_test(
    sub {
      cmp_deeply($b, isa("A"));
    },
    {
      actual_ok => 0,
      diag => <<EOM,
Checking class of \$data with isa()
   got : $b
expect : blessed into or ref of type 'A'
EOM
    },
    "isa eq"
  );

  check_test(
    sub {
      cmp_deeply($b, obj_isa("A"));
    },
    {
      actual_ok => 0,
      diag => <<EOM,
Checking class of \$data with isa()
   got : $b
expect : blessed into 'A' or subclass of 'A'
EOM
    },
    "isa eq"
  );


  @A::ISA = ();
  @B::ISA = ("A");

  check_test(
    sub {
      cmp_deeply($b, isa("A"));
    },
    {
      actual_ok => 1,
      diag => "",
    },
    "isa eq"
  );

  check_test(
    sub {
      cmp_deeply($b, obj_isa("A"));
    },
    {
      actual_ok => 1,
      diag => "",
    },
    "isa eq"
  );
}

package A;

use Test::Deep;
@A::ISA = qw( Test::Deep );

{
  ::ok(A->isa("Test::Deep"), "U::isa says yes");
  ::ok(! A->isa("Test"), "U::isa says yes");
}


{
  package C;
  use base 'A';
}
package main;
{
  my $c = bless {}, "C";
  check_test(
    sub {
      cmp_deeply($c, isa("A"));
    },
    {
      actual_ok => 1,
      diag => "",
    },
    "isa eq"
  );
}

