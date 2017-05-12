package My::Test::Class::Child;

use Test::Class::Most
  parent      => 'My::Test::Class',
  is_abstract => 1,
  attributes  => 'child1';

sub startup : Tests(startup) {
    my $test = shift;
    $test->SUPER::startup;
    $test->child1('from child1');
}

sub parent {
    ['My::Test::Class'];
}

1;
