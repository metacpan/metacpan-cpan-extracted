package My::Test::Role::Nested::Piddle;

use Role::Tiny;
with 'My::Test::Role::Nested';

sub test_class { 'My::Class::Single::Piddle' }
sub nested_test_class { 'My::Class::Nested::Piddle' }

1;


