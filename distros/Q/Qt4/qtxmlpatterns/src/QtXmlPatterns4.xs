/***************************************************************************
                          QtXmlPatterns4.xs  -  QtXmlPatterns perl extension
                             -------------------
    begin                : 06-19-2010
    copyright            : (C) 2010 by Chris Burel
    email                : chrisburel@gmail.com
 ***************************************************************************/

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

#include <QHash>
#include <QList>
#include <QXmlNodeModelIndex>
#include <QPalette>
#include <QMetaObject>
#include <QMetaMethod>
#include <QLinkedList>

// Perl headers
extern "C" {
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
}

#include <qtxmlpatterns_smoke.h>

#include <smokeperl.h>
#include <handlers.h>
#include "util.h"

extern QList<Smoke*> smokeList;

extern Q_DECL_EXPORT Smoke* qtcore_Smoke;
extern Q_DECL_EXPORT Smoke* qtxmlpatterns_Smoke;

const char*
resolve_classname_qtxmlpatterns(smokeperl_object * o)
{
    return perlqt_modules[o->smoke].binding->className(o->classId);
}

extern TypeHandler QtXmlPatterns4_handlers[];

static PerlQt4::Binding bindingqtxmlpatterns;

XS(XS_qabstractxmlnodemodel_createindex) {
    dXSARGS;
    if (items == 1 || items == 2) {
        smokeperl_object* o = sv_obj_info(sv_this);
        if (!o) {
            COP* callercop = caller(0);
            croak( "%s at %s line %lu\n",
                "Qt::AbstractXmlNodeModel::createIndex must be called as a "
                    "method on a Qt::AbstractXmlNodeModel object, eg. "
                    "$model->createIndex",
                GvNAME(CopFILEGV(callercop))+2,
                CopLINE(callercop)
            );
        }

        Smoke::ModuleIndex nameId;

        if ( items == 1 )
            nameId = qtxmlpatterns_Smoke->idMethodName("createIndex$");
        else
            nameId = qtxmlpatterns_Smoke->idMethodName("createIndex$$");

        char argType[2][10];
        for ( int i = 0; i < items; ++i ) {
            if ( SvTYPE( ST(i) ) == SVt_IV || SvTYPE( ST(i) ) == SVt_NV )
                strcpy( argType[i], "long long\0");
            else
                strcpy( argType[i], "void*\0");
        }

        Smoke::ModuleIndex meth = qtxmlpatterns_Smoke->findMethod(qtxmlpatterns_Smoke->findClass("QAbstractXmlNodeModel"), nameId);
        Smoke::Index index = meth.smoke->methodMaps[meth.index].method;

        Smoke::Method *m = 0;
        index = -index;    // turn into ambiguousMethodList index
        while (meth.smoke->ambiguousMethodList[index] != 0) {
            bool match = true;
            for ( int i = 0; i < items; ++i ) {
                const char* typeName = meth.smoke->types[meth.smoke->argumentList[meth.smoke->methods[meth.smoke->ambiguousMethodList[index]].args + i]].name;
                if ( strcmp( typeName, argType[i] ) != 0 ) {
                    match = false;
                    break;
                }
            }
            if ( match ) {
                m = &meth.smoke->methods[meth.smoke->ambiguousMethodList[index]];
                break;
            }

            ++index;
        }

        if ( m ) {
            Smoke::ClassFn fn = meth.smoke->classes[m->classId].classFn;
            Smoke::StackItem stack[3];
            bool cleanup = false;
            if ( strcmp( argType[0], "long long" ) == 0 ) {
                stack[1].s_voidp = new long long;
                *(long long *)stack[1].s_voidp = SvIV(ST(0));
                cleanup = true;
            }
            else {
                if ( !SvROK( ST(0) ) ) {
                    COP* callercop = caller(0);
                    croak( "%s at %s line %lu\n",
                        "Must provide a reference as 1st argument to "
                            "Qt::AbstractXmlNodeModel::createIndex",
                        GvNAME(CopFILEGV(callercop))+2,
                        CopLINE(callercop)
                    );
                }
                SV* refval = SvRV( ST(0) );

                //TODO: figure out a way to decrement the refcount when the
                //modelindex is deleted
                SvREFCNT_inc(refval);
                stack[1].s_voidp = (void*)refval;
            }
            if (items == 2) {
                stack[2].s_voidp = new long long;
                *(long long *)stack[2].s_voidp = SvIV(ST(1));
            }
            (*fn)(m->method, o->ptr, stack);
            smokeperl_object* result = alloc_smokeperl_object(
                true, 
                qtxmlpatterns_Smoke,
                qtxmlpatterns_Smoke->idClass("QXmlNodeModelIndex").index, 
                stack[0].s_voidp
            );

            ST(0) = set_obj_info(" Qt::XmlNodeModelIndex", result);

            if ( cleanup ) {
                delete (long long int *) stack[1].s_voidp;
            }
            if ( items == 2 ) {
                delete (long long int *) stack[2].s_voidp;
            }

            XSRETURN(1);
        }
        XSRETURN_UNDEF;
    }
    XSRETURN_UNDEF;
}

XS(XS_qxmlnodemodelindex_internalpointer) {
    dXSARGS;
    smokeperl_object *o = sv_obj_info(ST(0));
	QXmlNodeModelIndex * index = (QXmlNodeModelIndex *) o->ptr;
	void * ptr = index->internalPointer();
    if(ptr) {
        SV* svptr = (SV*)ptr;
        if ( svptr != &PL_sv_undef ) {
            svptr = newRV_inc( svptr );
        }
        ST(0) = (SV*)svptr;
    }
    else {
        ST(0) = &PL_sv_undef;
    }
    XSRETURN(1);
}

MODULE = QtXmlPatterns4            PACKAGE = QtXmlPatterns4::_internal

PROTOTYPES: DISABLE

SV*
getClassList()
    CODE:
        AV* classList = newAV();
        for (int i = 1; i <= qtxmlpatterns_Smoke->numClasses; i++) {
            if (qtxmlpatterns_Smoke->classes[i].className && !qtxmlpatterns_Smoke->classes[i].external)
                av_push(classList, newSVpv(qtxmlpatterns_Smoke->classes[i].className, 0));
        }
        RETVAL = newRV_noinc((SV*)classList);
    OUTPUT:
        RETVAL

SV*
getEnumList()
    CODE:
        AV *av = newAV();
        for(int i = 1; i < qtxmlpatterns_Smoke->numTypes; i++) {
            Smoke::Type curType = qtxmlpatterns_Smoke->types[i];
            if( (curType.flags & Smoke::tf_elem) == Smoke::t_enum )
                av_push(av, newSVpv(curType.name, 0));
        }
        RETVAL = newRV_noinc((SV*)av);
    OUTPUT:
        RETVAL

#// The build system with cmake and mingw relies on the visibility being set for
#// a dll to export that symbol.  So we need to redefine XSPROTO so that we can
#// export the boot method.
#ifdef WIN32
#undef XSPROTO
#define XSPROTO(name) void Q_DECL_EXPORT name(pTHX_ CV* cv)
#define boot_QtXmlPatterns4 boot_PerlQtXmlPatterns4
#endif

MODULE = QtXmlPatterns4            PACKAGE = QtXmlPatterns4

PROTOTYPES: ENABLE

BOOT:
    init_qtxmlpatterns_Smoke();
    smokeList << qtxmlpatterns_Smoke;

    bindingqtxmlpatterns = PerlQt4::Binding(qtxmlpatterns_Smoke);

    PerlQt4Module module = { "PerlQtXmlPatterns4", resolve_classname_qtxmlpatterns, 0, &bindingqtxmlpatterns  };
    perlqt_modules[qtxmlpatterns_Smoke] = module;

    install_handlers(QtXmlPatterns4_handlers);

    newXS("Qt::AbstractXmlNodeModel::createIndex", XS_qabstractxmlnodemodel_createindex, __FILE__);
    newXS(" Qt::AbstractXmlNodeModel::createIndex", XS_qabstractxmlnodemodel_createindex, __FILE__);
    newXS(" Qt::XmlNodeModelIndex::internalPointer", XS_qxmlnodemodelindex_internalpointer, __FILE__);
