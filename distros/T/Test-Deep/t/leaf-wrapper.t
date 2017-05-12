use strict;
use warnings;
use lib 't/lib';

use Std;

{
  check_test(
    sub {
      cmp_deeply( Test::Deep::EqOverloaded->new, 5);
    },
    {
      actual_ok => 0,
    },
    "comparing a plain scalar leaf against obj without eq"
  );

  {
    local $Test::Deep::LeafWrapper = \&str;
    check_tests(
      sub {
        cmp_deeply( Test::Deep::EqOverloaded->new, 5);
        cmp_deeply( Test::Deep::EqOverloaded->new, 6);
      },
      [
        {
          actual_ok => 1,
        },
        {
          actual_ok => 0,
        },
      ],
      "comparing a plain scalar leaf against obj with eq"
    );
  }

  {
    check_tests(
      sub {
        my $t1 = 5;
        my $t2 = any(5);
        my $t3 = all(5);
        local $Test::Deep::LeafWrapper = \&str;
        cmp_deeply(Test::Deep::EqOverloaded->new, $t1);
        cmp_deeply(Test::Deep::EqOverloaded->new, $t2);
        cmp_deeply(Test::Deep::EqOverloaded->new, $t3);
      },
      [
        {
          actual_ok => 1,
        },
        {
          actual_ok => 1,
        },
        {
          actual_ok => 1,
        },
      ],
      "comparing a plain scalar leaf against obj with eq via any() and all()"
    );
  }
}

{
  package Test::Deep::EqOverloaded;
  use overload q{""} => sub { "5" }, fallback => 1;
  sub new { my $self = {}; bless $self; }
}
