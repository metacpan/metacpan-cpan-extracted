#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

char *
dummy(SV *class_name) {
  return "George";
}

MODULE = PITA::Test::Dummy::Perl5::XS   PACKAGE = PITA::Test::Dummy::Perl5::XS

PROTOTYPES: DISABLE

char *
dummy(class_name)
  SV * class_name
