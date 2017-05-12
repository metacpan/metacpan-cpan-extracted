#ifdef __cplusplus
extern "C" {
#endif

#define PERL_NO_GET_CONTEXT /* we want efficiency */
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
#include <sys/socket.h>
#include <errno.h>

#ifdef __cplusplus
} /* extern "C" */
#endif

#define NEED_newSVpvn_flags
#include "ppport.h"

MODULE = POSIX::getpeername    PACKAGE = POSIX::getpeername

PROTOTYPES: DISABLE

IV
_getpeername(fd, sv_sock_addr)
    IV fd;
    SV * sv_sock_addr;

    PREINIT:
    int count = sizeof(struct sockaddr);
    char * sock_addr;

    PROTOTYPE: DISABLE

    CODE:
    if (!SvOK(sv_sock_addr)) {
         sv_setpvn(sv_sock_addr, "", 0);
    }
    SvUPGRADE((SV*)ST(1), SVt_PV);
    sv_sock_addr = (SV*)SvGROW((SV*)ST(1), count);
    RETVAL = getpeername(fd, (struct sockaddr*)sv_sock_addr, &count);
    if (count >= 0)
    {
        SvCUR_set((SV*)ST(1), count);
        SvTAINT(ST(1));
        SvSETMAGIC(ST(1));
    }

    OUTPUT:
    RETVAL


