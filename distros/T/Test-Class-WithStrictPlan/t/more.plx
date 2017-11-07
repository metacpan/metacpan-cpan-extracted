package MyTest;
use parent 'Test::Class::WithStrictPlan';

use Test::More;

sub my_test : Test(3) {
  pass('First test passed');
  pass('Second test passed');
}

__PACKAGE__->runtests;
