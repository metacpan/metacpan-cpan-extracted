#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <lirc/lirc_client.h>

struct lirc_config *config;

MODULE = RCU::Lirc   PACKAGE = RCU::Lirc

PROTOTYPES: ENABLE

int
lirc_init(prog,verbose=0)
	char *	prog
        int	verbose

int
lirc_deinit()

int
lirc_readconfig(file=Nullch)
	char *	file
	CODE:
        RETVAL = lirc_readconfig (file, &config, NULL);
        if (RETVAL != 0)
          config = 0;
	OUTPUT:
        RETVAL

void
lirc_freeconfig()
	CODE:
        if (config)
          lirc_freeconfig (config);

void
_get_code()
        PPCODE:
        char *code;

        if (lirc_nextcode (&code) != 0)
          croak ("communication error with lircd");

        if (code)
          {
            char *text;
            
            if (!config || lirc_code2char (config, code, &text) != 0)
              text = 0;

            XPUSHs (sv_2mortal (newSVpvn (code, 16)));
            if (text)
              XPUSHs (sv_2mortal (newSVpv (text, 0)));
            else
              XPUSHs (sv_2mortal (newSVpvn (code + 20, strchr (code + 20, ' ') - code - 20)));

            free (code);
          }


