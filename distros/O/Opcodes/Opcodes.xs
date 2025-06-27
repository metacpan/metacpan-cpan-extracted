#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include "const-c.inc"

/* Private flags added by me for the optimizer, not in CORE */
#define OA_NOSTACK  	  512
#define OA_MAYSCALAR     1024
#define OA_MAYARRAY      2048
#define OA_MAYVOID       4096
#define OA_RETFIXED      8192
#define OA_MAYBRANCH 	16384

MODULE = Opcodes	PACKAGE = Opcodes

PROTOTYPES: DISABLE

INCLUDE: const-xs.inc

void
opcodes()
PPCODE:
    if (GIMME_V == G_ARRAY) {
        int i;
        EXTEND(sp, MAXO);
        /* ([ opcode opname ppaddr check opargs ]) from opnames.h/opcode.h */
	for (i=0; i < MAXO; i++) {
            AV* ref;
            ref = newAV();
            av_extend(ref, 5);
            av_store(ref, 0, newSViv( i ));
            av_store(ref, 1, newSVpvn(PL_op_name[i], strlen(PL_op_name[i]) ));
            av_store(ref, 2, newSVuv( PTR2UV(PL_ppaddr[i]) ));
            av_store(ref, 3, newSVuv( PTR2UV(PL_check[i]) ));
            av_store(ref, 4, newSViv( PL_opargs[i] ));
            XPUSHs( sv_2mortal(newRV((SV*)ref)) );
	}
    }
    else {
	XPUSHs(sv_2mortal(newSViv(PL_maxo)));
    }

