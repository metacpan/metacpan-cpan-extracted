package My::Test::Role::Nested::NDarray;

use Role::Tiny;
with 'My::Test::Role::Nested';

sub test_class { 'My::Class::Single::NDarray' }
sub nested_test_class { 'My::Class::Nested::NDarray' }

1;


