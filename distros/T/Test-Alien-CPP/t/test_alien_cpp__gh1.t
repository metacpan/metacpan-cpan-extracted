use Test2::V0 -no_srand => 1;
use Test::Alien::CPP;

alien_ok synthetic { cflags => '-DD2=22' };

my $xs = do { local $/; <DATA> };

xs_ok { xs => $xs, cbuilder_compile => { extra_compiler_flags => '-DD1=20' }, verbose => 1 }, '', with_subtest {
  my($mod) = @_;
  is($mod->get_a_value, 42);
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

#ifdef D1
#ifdef D2
  return D1+D2;
#else
  return D1;
#endif
#else
#ifdef D2
  return D2;
#else
  return 0;
#endif
#endif

}

MODULE = TA_MODULE PACKAGE = TA_MODULE

int get_a_value(klass);
    const char *klass
  CODE:
    RETVAL = Foo::get_a_value();
  OUTPUT:
    RETVAL

