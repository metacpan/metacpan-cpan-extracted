#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#ifdef I_NETINET_TCP
# include <netinet/tcp.h>
#endif

#include "const-c.inc"

MODULE = Socket::Linux		PACKAGE = Socket::Linux

INCLUDE: const-xs.inc

