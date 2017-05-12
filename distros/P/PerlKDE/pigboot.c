/*
 * Bootstrap for PerlKDE
 *
 * Copyright (C) 2000, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README.LICENSE file which should be included with this library.
 *
 */

#include "pig_KApplication.h"
#include "pigperl.h"
#include "pigsymbol.h"
#include "pigclassinfo.h"
#include "pigconstant.h"

PIG_DECLARE_IMPORT_TABLE(pig)
PIG_DECLARE_EXPORT_TABLE(PIG_KDE)
PIG_DECLARE_EXPORT_TABLE(pigtype_kde)

PIG_GLOBAL_EXPORT_TABLE(pig)
    PIG_EXPORT_SUBTABLE(PIG_KDE)
    PIG_EXPORT_SUBTABLE(pigtype_kde)
PIG_EXPORT_ENDTABLE

extern struct pig_constant PIG_constant_KDE[];
extern struct pig_classinfo PIG_module[];

void __pig_module_used(const char *pig0) {
    char *pigpm, *pigs;
    pigpm = new char [strlen(pig0) + 4];
    pigs = pigpm;
    while(*pig0) {
        if(*pig0 == ':' && *(pig0 + 1) == ':') {
            *pigs = '/';
            pig0++;
        } else {
            *pigs = *pig0;
        }

        pigs++;
        pig0++;
    }
    strcpy(pigs, ".pm");

//warn("$INC{\"%s\"} = \"%s\";\n", pigpm, __FILE__);

    HV *pighv_inc = perl_get_hv("main::INC", TRUE);
    hv_store(pighv_inc, pigpm, strlen(pigpm), newSVpv(__FILE__, 0), 0);
}

SV *gv_store(const char *name, SV *value) {    // kludge
    GV *gv = gv_fetchpv((char *)name, TRUE | GV_ADDMULTI, SVt_PVGV);
    SvREFCNT_inc(value);
    if(GvSV(gv)) SvREFCNT_dec(GvSV(gv));
    GvSV(gv) = value;
    GvIMPORTED_SV_on(gv);
    return value;
}

extern "C" XS(PIG_app_import) {
    dXSARGS;
    const char *pigclass = HvNAME(PIGcurcop->cop_stash);
    char *pigvar;
    SV *pigsv;
    SV *pigapp;

    pigapp = perl_get_sv("KDE::app", FALSE);
    if(!pigapp || !SvOK(pigapp)) {
        AV *pigargv;
        int pigcount;
        pigargv = perl_get_av("ARGV", TRUE);

        ENTER;
        SAVETMPS;
        PUSHMARK(sp);
        XPUSHs(sv_2mortal(newSVpv((char *)pig_map_class("KApplication"), 0)));
        XPUSHs(sv_2mortal(newRV((SV *)pigargv)));
        PUTBACK;

        pigcount = perl_call_method("new", G_SCALAR);

        SPAGAIN;

        if(pigcount != 1)
            croak("Cannot call %s::new\n", pig_map_class("KApplication"));

        pigapp = perl_get_sv("KDE::app", TRUE | GV_ADDMULTI);
        sv_setsv(pigapp, POPs);

        PUTBACK;
        FREETMPS;
        LEAVE;
    }

    pigvar = new char [strlen(pigclass) + 7];
    sprintf(pigvar, "%s::app", pigclass);
    gv_store(pigvar, pigapp);
    SvREFCNT_dec(pigapp);
    delete [] pigvar;

    XSRETURN_EMPTY;
}

extern "C" XS(PIG_KDE_import) {
    dXSARGS;
    const char *pigclass = HvNAME(PIGcurcop->cop_stash);
    char *pigvar;

    pigvar = new char [strlen(pigclass) + 7];
    sprintf(pigvar, "%s::app", pigclass);
    perl_get_sv(pigvar, TRUE | GV_ADDMULTI);	// No warnings
    delete [] pigvar;
}

extern "C" XS(boot_KDE) {
    dXSARGS;

    pig_symbol_exchange(PIG_EXPORTTABLE(pig), PIG_IMPORTTABLE(pig),
			"KDE", "Qt");

    pig_load_classinfo(PIG_module);

    pig_load_constants("KDE", PIG_constant_KDE);

    __pig_module_used("KDE::app");
//    newXS("KDE::Application::new", PIG_KApplication_new, __FILE__);
    newXS("KDE::app::import", PIG_app_import, __FILE__);
    newXS("KDE::import", PIG_KDE_import, __FILE__);

    XSRETURN_UNDEF;
}
