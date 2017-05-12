/*-*- Mode: C++ -*- */
extern "C" {
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
//#include "ppport.h"
};

#include <moot.h>
#include "MootPerl.h"

MODULE = Moot		PACKAGE = Moot

##=====================================================================
## Moot (Debug)
##=====================================================================

#ifdef MOOTDEBUG

##-- refcount = __refcnt($SV)
##   + also see Devel::Peek::Dump($SV), Devel::Peek::SvREFCNT($SV)
int __refcnt(SV *sv)
CODE:
 if (sv && SvOK(sv)) {
   RETVAL = SvREFCNT(sv);
 } else {
   XSRETURN_UNDEF;
 }
OUTPUT:
 RETVAL

#endif


##=====================================================================
## Moot: submodules
INCLUDE: Constants.xs
INCLUDE: Lexfreqs.xs
INCLUDE: Ngrams.xs
INCLUDE: HMM.xs
INCLUDE: DynHMM.xs
INCLUDE: TokenIO.xs
INCLUDE: TokenReader.xs
INCLUDE: TokenWriter.xs
INCLUDE: Waste.xs
