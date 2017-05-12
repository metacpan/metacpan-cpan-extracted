/* Nanar <nanardon@zarb.org>
 * $Id$
 */

#include <string.h>
#define RPMCONSTANT_INTERNAL
#include "rpmconstant.h"

const char * rpmConstantName(rpmconstant c)
{
    return c->name;
}

int rpmConstantValue(rpmconstant c)
{
    return c->value;
}

rpmconstant rpmConstantNext(rpmconstant c)
{
    return (c + 1)->name ? c + 1 : NULL;
}

/**/

rpmconstantlist rpmGetConstantList()
{
    return (void *) rpmconstanttype;
}

rpmconstantlist rpmConstantListNext(rpmconstantlist cl)
{
    return (cl + 1)->constant ? cl + 1 : NULL;
}

rpmconstantlist rpmGetConstantListFromContext(const char * context)
{
    rpmconstantlist cl;
    for (cl = rpmGetConstantList(); cl; cl=rpmConstantListNext(cl)) {
        if (context && strcmp(context, rpmConstantListContext(cl)) == 0)
            return cl;
    }
    return NULL;
}

const char * rpmConstantListPrefix (rpmconstantlist cl)
{
    return cl->prefix;
}

const char * rpmConstantListContext (rpmconstantlist cl)
{
    return cl->context;
}

rpmconstant rpmConstantListC(rpmconstantlist cl)
{
    return cl->constant;
}

