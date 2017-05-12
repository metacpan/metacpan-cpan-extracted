#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <nl_types.h>

typedef	int		SysRet;
typedef	nl_catd		*Locale__Msgcat;

MODULE = Locale::Msgcat		PACKAGE = Locale::Msgcat		

Locale::Msgcat
new(packname = "Locale::Msgcat")
   char *	packname
   CODE:
      {
         RETVAL = (nl_catd *)safemalloc(sizeof(nl_catd));
      }
   OUTPUT:
      RETVAL

void
DESTROY(catalog)
   Locale::Msgcat	catalog
   CODE:
      safefree((nl_catd *)catalog);


SysRet
catopen(catalog, name, option)
   Locale::Msgcat	catalog
   char			*name
   int			option
   CODE:
      {
         *catalog = catopen(name, option);
         if (*catalog == (nl_catd) -1)
            RETVAL = 0;
         else
            RETVAL = 1;
      }
   OUTPUT:
      RETVAL

SysRet
catclose(catalog)
   Locale::Msgcat	catalog
   CODE:
         RETVAL = (catclose(*catalog) == 0);
   OUTPUT:
      RETVAL

char *
catgets(catalog, set_number, message_number, string)
   Locale::Msgcat	catalog
   int			set_number
   int			message_number
   char *		string
   CODE:
      RETVAL = catgets(*catalog, set_number, message_number, string);
   OUTPUT:
      RETVAL

