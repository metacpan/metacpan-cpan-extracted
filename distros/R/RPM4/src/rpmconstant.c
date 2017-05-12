/* Nanar <nanardon@zarb.org>
 * $Id$
 */

#include <string.h>
#include <ctype.h>
#define RPMCONSTANT_INTERNAL
#include "rpmconstant.h"

rpmconst rpmconstNew()
{
    rpmconst c = NULL;
    c = xcalloc(1, sizeof(*c));
    c->list = NULL;
    c->constant = NULL;
    return c;
}

rpmconst rpmconstFree(rpmconst c)
{
    free(c);
    return c = NULL;
}

void rpmconstInitC(rpmconst c)
{
    c->constant = NULL;
}

int rpmconstNextC(rpmconst c)
{
    if (c->list == NULL)
        return 0;
    c->constant = c->constant == NULL ?
        rpmConstantListC(c->list) :
        rpmConstantNext(c->constant);
    return c->constant == NULL ? 0 : 1;
}


void rpmconstInitL(rpmconst c)
{
    c->list = NULL;
    c->constant = NULL;
}

int rpmconstNextL(rpmconst c)
{
    c->list = c->list == NULL ?
        (void *) rpmconstanttype :
        rpmConstantListNext(c->list);
    c->constant = NULL;
    return c->list == NULL ? 0 : 1;
}

const char * rpmconstContext(rpmconst c)
{
    return rpmConstantListContext(c->list);
}

const char * rpmconstPrefix(rpmconst c)
{
    return rpmConstantListPrefix(c->list);
}

const char * rpmconstName(rpmconst c, int stripprefix)
{
    const char * name;
    int len;
    name = rpmConstantName(c->constant);
    if (stripprefix && name && rpmConstantListPrefix(c->list)) {
        len = strlen(rpmConstantListPrefix(c->list));
        name += len < strlen(name) ? len : 0;
    }
    return name;
}

int rpmconstValue(rpmconst c)
{
    return rpmConstantValue(c->constant);
}

int rpmconstInitToContext(rpmconst c, const char * context)
{
    char * lccontext = strdup(context);
    char * ptr;
    int rc = 0;
    for (ptr = lccontext; *ptr != 0; ptr++)
        *ptr = tolower(*ptr);
    if (!context) return 0; /* programmer error */
    rpmconstInitL(c);
    while (rpmconstNextL(c)) {
        if (!strcmp(lccontext, rpmconstContext(c))) {
            rc = 1;
            break;
        }
    }
    free(lccontext);
    return rc; /* not found */
}

int rpmconstNameMatch(rpmconst c, const char * name, int prefixed)
{
    char * uc;
    int rc = 0;
    char * ucname = strdup(name);
    
    for (uc = ucname; *uc != 0; uc++)
        *uc = toupper(*uc);
    
    if (!prefixed) prefixed = ALLCASE_PREFIX;
    if (prefixed & WITH_PREFIX)
        if (strcmp(ucname, rpmconstName(c, PREFIXED_YES)) == 0)
            rc = 1;
    if (!rc && (prefixed & WITHOUT_PREFIX))
        if (strcmp(ucname, rpmconstName(c, PREFIXED_NO)) == 0)
            rc = 1;
    free(ucname);
    return rc;
}

int rpmconstFindValue(rpmconst c, const int val)
{
    rpmconstInitC(c);
    while (rpmconstNextC(c)) {
        if (val == rpmconstValue(c))
            return 1;
    }
    return 0;
}

int rpmconstFindMask(rpmconst c, const int val)
{
    rpmconstInitC(c);
    while (rpmconstNextC(c)) {
        if (!rpmconstValue(c))
            continue;
        if (rpmconstValue(c) & val)
            return 1;
    }
    return 0;
}

int rpmconstFindName(rpmconst c, const char * name, int prefixed)
{
    rpmconstInitC(c);
    while (rpmconstNextC(c)) {
        if (rpmconstNameMatch(c, name, prefixed))
            return 1;
    }
    return 0;
}

int rpmconstantFindValue(char * context, const int val, const char **name, int prefixed)
{
    int rc = 0;
    rpmconst c = rpmconstNew();
    if (rpmconstInitToContext(c, context))
        if (rpmconstFindValue(c, val)) {
            *name = rpmconstName(c, prefixed);
            rc = 1;
        }
    c = rpmconstFree(c);
    return rc;
}
    
int rpmconstantFindMask(char * context, const int val, const char **name, int prefixed)
{
    int rc = 0;
    rpmconst c = rpmconstNew();
    if (rpmconstInitToContext(c, context))
        if (rpmconstFindMask(c, val)) {
            *name = rpmconstName(c, prefixed);
            rc = rpmconstValue(c);
        }
    c = rpmconstFree(c);
    return rc;
}

int rpmconstantFindName(char * context, const char * name, int *val, int prefixed)
{
    int rc = 0;
    rpmconst c = rpmconstNew();
    if (rpmconstInitToContext(c, context)) {
        if (rpmconstFindName(c, name, prefixed)) {
            *val |= rpmconstValue(c);
            rc = 1;
        }
    }
    c = rpmconstFree(c);
    return rc;
}
