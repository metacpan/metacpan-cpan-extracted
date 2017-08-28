use Test2::V0 -no_srand => 1;
use Test::Alien::CPP;
use Test::Alien::CanCompileCpp;

subtest 'xs' => sub {

  my $xs = do { local $/; <DATA> };

  my $subtest = sub {
    my($module,$expected_string) = @_;
    is($module->get_a_value(), 42);
    is($module->get_b_value(), $expected_string);
  };

  xs_ok {
    xs      => $xs,
    verbose => 1,
  }, 'C++', with_subtest { $subtest->(shift, 'baz') };

  xs_ok {
    xs               => $xs,
    verbose          => 1,
    cbuilder_compile => {
      extra_compiler_flags => '-DFOOBLE=1',
    },
  }, "with a define as a string", 'C++', with_subtest { $subtest->(shift,'fooble') };

  xs_ok {
    xs               => $xs,
    verbose          => 1,
    cbuilder_compile => {
      extra_compiler_flags => ['-DFOOBLE=1'],
    },
  }, "with a define as an array", 'C++', with_subtest { $subtest->(shift,'fooble') };

};

done_testing;

__DATA__
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

class Foo {
public:
  static int get_a_value();
  static const char *get_b_value();
};

int Foo::get_a_value()
{
  return 42;
}

const char *Foo::get_b_value()
{
#ifdef FOOBLE
  return "fooble";
#else
  return "baz";
#endif
}

MODULE = TA_MODULE PACKAGE = TA_MODULE

int get_a_value(klass);
    const char *klass
  CODE:
    RETVAL = Foo::get_a_value();
  OUTPUT:
    RETVAL

const char *get_b_value(klass);
    const char *klass
  CODE:
    RETVAL = Foo::get_b_value();
  OUTPUT:
    RETVAL
  
