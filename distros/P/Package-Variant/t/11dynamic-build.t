use strictures 2;
use Test::More;

BEGIN {
  package TestVariable;
  use Package::Variant;
  sub make_variant {
    my ($class, $target, @args) = @_;
    install variant_values => sub { [@args] };
  }
}

is_deeply(
  Package::Variant
    ->build_variant_of('TestVariable', 3..7)
    ->variant_values,
  [3..7],
  'build_variant_of with scalar values',
);

done_testing;
