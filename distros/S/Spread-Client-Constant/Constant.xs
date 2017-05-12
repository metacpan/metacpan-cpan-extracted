#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <sp.h>

#include "const-c.inc"

MODULE = Spread::Client::Constant		PACKAGE = Spread::Client::Constant		

INCLUDE: const-xs.inc
