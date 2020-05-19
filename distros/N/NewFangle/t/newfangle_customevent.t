use Test2::V0 -no_srand => 1;
use NewFangle qw( newrelic_configure_log );

is(
  NewFangle::CustomEvent->new('foo'),
  object {
    call [ isa => 'NewFangle::CustomEvent' ] => T();
    call [ add_attribute_int    => 'foo_int',           20 ] => T();
    call [ add_attribute_long   => 'foo_long',          22 ] => T();
    call [ add_attribute_double => 'foo_double',      3.14 ] => T();
    call [ add_attribute_string => 'foo_string', 'yo perl' ] => T();
  },
);

done_testing;
