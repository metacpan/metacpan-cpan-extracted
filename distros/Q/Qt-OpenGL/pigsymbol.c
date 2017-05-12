/*
 * Critical support file for Pig symbol import and export in Perl.
 * Authors of add-on modules will need to include this file in their
 * library.
 *
 * Copyright (C) 1999, 2000, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README.LICENSE file which should be included with this library.
 *
 */

// Get definitions of SV* and qsort()
#include "pigperl.h"
#include <stdlib.h>

long pig_symbol_count(pig_symboltable *pig_table) {
    long pigcount = 0;
    if(!pig_table) return 0;
    for(;;) {
	if(pig_table->pigname)
	    pigcount++;
	else if(pig_table->pigptr)
	    pigcount += pig_symbol_count((pig_symboltable *)pig_table->pigptr);
	else
	    break;

	pig_table++;
    }

    return pigcount;
}

pig_symboltable **pig_symbol_copy(pig_symboltable **pigp,
				  pig_symboltable *pigtable) {
    for(;;) {
	if(pigtable->pigname) {
	    *pigp = pigtable;
	    pigp++;
	}
	else if(pigtable->pigptr)
	    pigp = pig_symbol_copy(pigp, (pig_symboltable *)pigtable->pigptr);
	else
	    break;

	pigtable++;
    }

    return pigp;
}

void pig_symbol_add(SV *pigsv, pig_symboltable *pigtable) {
    long pigsize = 0;
    long pigoffset = 0;
    long pigsymcount = 0;
    struct pig_symboltable **pigp;

    if(!SvOK(pigsv)) sv_setpv(pigsv, "");
    pigoffset = SvCUR(pigsv);
    if(pigoffset) pigsize = SvLEN(pigsv);

    pigsymcount = pig_symbol_count(pigtable);
    pigsize += pigsymcount * sizeof(struct pig_symboltable *);
    SvGROW(pigsv, pigsize);
    SvCUR_set(pigsv, pigoffset + pigsymcount);

    pigp = (struct pig_symboltable **)SvPVX(pigsv);
    pigp += pigoffset;
    pig_symbol_copy(pigp, pigtable);
}

static int pig_comparesymbol(const void *pig0, const void *pig1) {
    struct pig_symboltable **pigsym0, **pigsym1;
    pigsym0 = (struct pig_symboltable **)pig0;
    pigsym1 = (struct pig_symboltable **)pig1;
    return strcmp((*pigsym0)->pigname, (*pigsym1)->pigname);
}

void pig_symbol_import(SV *pigimport, SV *pigexport) {
    struct pig_symboltable **pig_import, **pig_export;
    long pigimpcnt = 0, pigexpcnt = 0;

    pig_import = (struct pig_symboltable **)SvPVX(pigimport);
    pig_export = (struct pig_symboltable **)SvPVX(pigexport);

    for(pigimpcnt = 0; pigimpcnt < SvCUR(pigimport); pigimpcnt++) {
	while(pigexpcnt < SvCUR(pigexport) &&
	      strcmp(pig_export[pigexpcnt]->pigname,
		     pig_import[pigimpcnt]->pigname) < 0)
	    pigexpcnt++;

	if(pigexpcnt >= SvCUR(pigexport)) break;

        if(!strcmp(pig_export[pigexpcnt]->pigname,
		   pig_import[pigimpcnt]->pigname)) {
            PIG_DEBUG_SYMBOL(("import %s %p => %p\n", 
			      pig_export[pigexpcnt]->pigname,
                              pig_import[pigimpcnt]->pigptr,
			      pig_export[pigexpcnt]->pigptr));
            *((void **)pig_import[pigimpcnt]->pigptr) =
		pig_export[pigexpcnt]->pigptr;
        }
        else {
            PIG_DEBUG_SYMBOL(("import %s to nowhere\n",
			     pig_import[pigimpcnt]->pigname));
            *((void **)pig_import[pigimpcnt]->pigptr) = 0;
        }
    }
}

void pig_symbol_exchange(pig_symboltable *pig_export,
			 pig_symboltable *pig_import,
                         const char *pig_class,
			 const char *pig_super) {
    SV *pigexport = 0, *pigimport = 0;
    long pigoffset = 0;
    char *pigs = new char [strlen(pig_super) + strlen(pig_class) + 7];

    if(pig_super) {
	SV *pigsupersv;
	sprintf(pigs, "%s::.pig", pig_super);
	pigsupersv = perl_get_sv(pigs, FALSE);

	if(pigsupersv) {
	    long pigsize = SvCUR(pigsupersv);
	    SvCUR_set(pigsupersv, SvLEN(pigsupersv));
	    pigexport = sv_mortalcopy(pigsupersv);
	    SvCUR_set(pigsupersv, pigsize);
	    SvCUR_set(pigexport, pigsize);
	}
    }
    if(!pigexport)
	pigexport = sv_newmortal();


    sprintf(pigs, "%s::.pig", pig_class);
    pig_symbol_add(perl_get_sv(pigs, TRUE), pig_export);

    pigimport = sv_newmortal();

    pig_symbol_add(pigexport, pig_export);
    pig_symbol_add(pigimport, pig_import);
    qsort(SvPVX(pigexport), SvCUR(pigexport),
	  sizeof(struct pig_symboltable *), pig_comparesymbol);
    qsort(SvPVX(pigimport), SvCUR(pigimport),
	  sizeof(struct pig_symboltable *), pig_comparesymbol);

    pig_symbol_import(pigimport, pigexport);
    delete [] pigs;
}

