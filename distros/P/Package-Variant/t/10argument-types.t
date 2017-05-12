use strictures 2;
use Test::More;

BEGIN {
  package TestVariable;
  use Package::Variant;
  sub make_variant {
    my ($class, $target, @args) = @_;
    install variant_values => sub { [@args] };
  }
  $INC{'TestVariable.pm'} = __FILE__;
}

use TestVariable;

is_deeply TestVariable(23)->variant_values, [23],
  'simple value argument';
is_deeply TestVariable(3..7)->variant_values, [3..7],
  'multiple value arguments';
is_deeply TestVariable({ foo => 23 })->variant_values, [{ foo => 23 }],
  'hash reference argument';

done_testing;
