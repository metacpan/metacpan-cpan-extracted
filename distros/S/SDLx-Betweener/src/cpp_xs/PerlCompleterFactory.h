
#ifndef PERLCOMPLETERFACTORY_H
#define PERLCOMPLETERFACTORY_H

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ICompleter.h"
#include "PerlCallbackCompleter.h"
#include "PerlMethodCompleter.h"

ICompleter *Build_Completer(SV *args) {
    ICompleter *completer;
    if (SvTYPE(SvRV(args)) == SVt_PVAV) {
        completer = new PerlMethodCompleter(args);
    } else {
        completer = new PerlCallbackCompleter(args);
    }
    return completer;
}

#endif
