/* Nanar <nanardon@zarb.org>
 * $Id$
 */

#ifndef H_RPMCONSTANT
#define H_RPMCONSTANT

#ifndef xcalloc
#define xcalloc(n,s) calloc((n),(s))
#endif

#define PREFIXED_YES 0
#define PREFIXED_NO  1

#define WITH_PREFIX (1 << 0)
#define WITHOUT_PREFIX (1 << 1)
#define ALLCASE_PREFIX (WITH_PREFIX | WITHOUT_PREFIX)

/**
 * \ingroup rpmconstant
 * \file rpmconstant.h
 *
 */

#include <stdio.h>
#include <rpm/header.h>
#include <rpm/rpmbuild.h>
#include <rpm/rpmdb.h>
#include <rpm/rpmds.h>
#include <rpm/rpmfi.h>
#include <rpm/rpmio.h>
#include <rpm/rpmlib.h>
#include <rpm/rpmlog.h>
#include <rpm/rpmpgp.h>
#include <rpm/rpmps.h>
#include <rpm/rpmtag.h>
#include <rpm/rpmte.h>
#include <rpm/rpmts.h>
#include <rpm/rpmvf.h>

/**
 * A constant pair name/value
 */
typedef /*@abstract@*/ struct rpmconstant_s *rpmconstant;


/**
 * A constant list set
 */
typedef /*@abstract@*/ struct rpmconstantlist_s * rpmconstantlist;

typedef struct rpmconst_s * rpmconst;

#ifdef RPMCONSTANT_INTERNAL

/**
 * A constant pair name/value
 */
struct rpmconstant_s {
    const char * name; /*!< Constant name. */
/*@null@*/
    int value; /*!< Constant value. */
};

/**
 * A contantlist entry
 */
struct rpmconstantlist_s {
    const rpmconstant constant; /*<! Constant pointer */
/*@null@*/
    char *context; /*<! Name of the list */
    char *prefix; /*<! Common prefix of constant name */
/*@null@*/
};

struct rpmconst_s {
    rpmconstantlist list;
    rpmconstant constant;
};

/**
 * Pointer to first element of rpmconstantlist.
 */
/*@-redecl@*/
/*@observer@*/ /*@unchecked@*/
extern const struct rpmconstantlist_s * rpmconstanttype;
/*@=redecl@*/

/**
 * Return name from contant item.
 *
 * @param c     constant item
 * @return      pointer to name from item
 */
const char * rpmConstantName(rpmconstant c)
    /*@*/;

/**
 * Return value from constant item.
 *
 * @param c     constant item
 * @return      value from current item
 */
int rpmConstantValue(rpmconstant c)
    /*@*/;

/**
 * Return next constant item from constant list (or NULL at end of list).
 *
 * @param c     current constant item
 * @return      next constant item
 */
/*@null@*/
rpmconstant rpmConstantNext(rpmconstant c)
    /*@*/;


/**
 * Get a pointer to first rpmconstantlist item
 *
 * @return      first constantlist item
 */
rpmconstantlist rpmGetConstantList()
    /*@*/;

/**
 * Return next constantlist item from list (or NULL at the end of list).
 *
 * @param cl    current constantlist item
 * @return      next constantlist item
 */
/*@null@*/
rpmconstantlist rpmConstantListNext(rpmconstantlist cl)
    /*@*/;

/**
 * Return constantlist item corresponding to context
 *
 * @param context   ptr to constext
 * @return          constant list item matching context
 */
rpmconstantlist rpmGetConstantListFromContext(const char * context)
    /*@*/;

/**
 * Return a pointer to first constant item from constantlist.
 *
 * @param cl    constantlist item
 * @retval      first constant item from list
 */
rpmconstant rpmConstantListC(rpmconstantlist cl)
    /*@*/;

/**
 * Return the common prefix of constant name.
 *
 * @param cl    constantlist item
 * @return      pointer to prefix string (or NULL is not availlable)
 */
/*@null@*/
const char * rpmConstantListPrefix (rpmconstantlist cl)
    /*@*/;

/**
 * Return context name from constantlist item
 *
 * @param cl    constantlist item
 * @return      pointer to context name
 */
const char * rpmConstantListContext (rpmconstantlist cl)
    /*@*/;

#endif

rpmconst rpmconstNew();

rpmconst rpmconstFree(rpmconst c);

void rpmconstInitC(rpmconst c);

int rpmconstNextC(rpmconst c);

void rpmconstInitL(rpmconst c);

int rpmconstNextL(rpmconst c);

const char * rpmconstContext(rpmconst c);

const char * rpmconstPrefix(rpmconst c);

const char * rpmconstName(rpmconst c, int stripprefix);

int rpmconstValue(rpmconst c);

int rpmconstInitToContext(rpmconst c, const char * context);

int rpmconstNameMatch(rpmconst c, const char * name, int prefixed);

int rpmconstFindValue(rpmconst c, const int val);

int rpmconstFindMask(rpmconst c, const int val);

int rpmconstFindName(rpmconst c, const char * name, int prefixed);

int rpmconstantFindValue(char * context, const int val, const char **name, int prefixed);

int rpmconstantFindMask(char * context, const int val, const char **name, int prefixed);

int rpmconstantFindName(char * context, const char * name, int *val, int prefixed);
    
#endif /* H_RPMCONSTANT */
