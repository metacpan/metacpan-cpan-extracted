#ifndef PIGVIRTUAL_H
#define PIGVIRTUAL_H

/*
 * Pig support classes for virtual functions
 *
 * Copyright (C) 1999, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README.LICENSE file which should be included with this library.
 *
 */

#undef bool

#include "pigfunc.h"

PIG_DECLARE_VOID_FUNC_2(pig_virtual_dereference, const class pig_virtual *, void *)
PIG_DECLARE_VOID_FUNC_2(pig_virtual_setobject, const class pig_virtual *, void *)

class pig_extra_data {
public:
    class pig_extra_data *pignext, *pigprev;
    pig_extra_data(pig_extra_data *pigp, pig_extra_data *pign) :
        pignext(pign), pigprev(pigp) {}
    virtual ~pig_extra_data() {
        if(pigprev) pigprev->pignext = pignext;
	if(pignext) pignext->pigprev = pigprev;
    }
    virtual int pigtype() = 0;
};

struct pig_virtual {
    void *pig_rv, *pig_this;
    pig_extra_data *pigdata;

    pig_virtual() : pig_rv(0), pig_this(0), pigdata(0) {}
    pig_virtual(void *pig1) : pig_rv(0), pig_this(pig1), pigdata(0) {}
    virtual ~pig_virtual() {
        pig_virtual_dereference(this, pig_rv);
	if(pigdata) {
	    while(pigdata->pignext)
	        pigdata = pigdata->pignext;
	    while(pigdata->pigprev) {          // I don't want to use auto variables here
	        pigdata = pigdata->pigprev;
	        delete pigdata->pignext;
	        pigdata->pignext = 0;
	    }
	    delete pigdata;
	}
    }
    void pig_add_data(pig_extra_data *pigd) {
        if(pigd) {
	    pigd->pigprev = 0;
	    pigd->pignext = pigdata;
	    if(pigdata) pigdata->pigprev = pigd;
	    pigdata = pigd;
        }
    }
};

PIG_IMPORT_TABLE(pigvirtual)
    PIG_IMPORT_FUNC(pig_virtual_dereference)
    PIG_IMPORT_FUNC(pig_virtual_setobject)
PIG_IMPORT_ENDTABLE

#endif  // PIGVIRTUAL_H
