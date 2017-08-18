use Test2::V0 -no_srand => 1;
use Test::Alien::CPP;
use Test::Alien::CanCompileCpp;

subtest 'xs' => sub {

  my $xs = do { local $/; <DATA> };

  my $subtest = sub {
    my($module) = @_;
    is($module->get_value(), 42);
  };

  xs_ok {
    xs      => $xs,
    verbose => 1,
  }, 'C++', with_subtest { $subtest->(@_) };

};

done_testing;

__DATA__
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

class Foo {
public:
  static int get_a_value();
};

int Foo::get_a_value()
{
  return 42;
}

MODULE = TA_MODULE PACKAGE = TA_MODULE

int get_value(klass);
    const char *klass
  CODE:
    RETVAL = Foo::get_a_value();
  OUTPUT:
    RETVAL
  
