#pragma once
#define NO_XSLOCKS          // dont hook libc calls
#define PERLIO_NOT_STDIO 0  // dont hook IO
#define PERL_NO_GET_CONTEXT // we want efficiency for threaded perls
extern "C" {
#  include "EXTERN.h"
#  include "perl.h"
#  include "XSUB.h"
#  undef do_open
#  undef do_close
}

namespace xs {

namespace next {
    CV* method        (pTHX_ HV* target_class);
    CV* method_strict (pTHX_ HV* target_class);
    CV* method        (pTHX_ HV* target_class, GV* current_sub);
    CV* method_strict (pTHX_ HV* target_class, GV* current_sub);

    inline CV* method        (pTHX_ HV* target_class, CV* current_sub) { return method       (aTHX_ target_class, CvGV(current_sub)); }
    inline CV* method_strict (pTHX_ HV* target_class, CV* current_sub) { return method_strict(aTHX_ target_class, CvGV(current_sub)); }

}

namespace super {
    CV* method        (pTHX_ HV* target_class, GV* current_sub);
    CV* method_strict (pTHX_ HV* target_class, GV* current_sub);

    inline CV* method        (pTHX_ HV* target_class, CV* current_sub) { return method       (aTHX_ target_class, CvGV(current_sub)); }
    inline CV* method_strict (pTHX_ HV* target_class, CV* current_sub) { return method_strict(aTHX_ target_class, CvGV(current_sub)); }
}

}
