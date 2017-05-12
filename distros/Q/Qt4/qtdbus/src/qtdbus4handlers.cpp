/***************************************************************************
                          qtdbus4handlers.cpp  -  QtDBus specific marshallers
                             -------------------
    begin                : 07-26-2010
    copyright            : (C) 2010 Chris Burel
    email                : chrisburel@gmail.com
 ***************************************************************************/

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either vesion 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

#include <QtCore/QHash>

// Perl headers
extern "C" {
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
}

#include <smokeperl.h>
#include <marshall_macros.h>
#include <QtCore4.h>

#if QT_VERSION >= 0x40200
#include <QtDBus/qdbusreply.h>
#endif

void marshall_QDBusVariant(Marshall *m) {
    UNTESTED_HANDLER("marshall_QDBusVariant");
    switch(m->action()) {
        case Marshall::FromSV: {
            SV *v = m->var();
            if (!SvOK(v)) {
                m->item().s_voidp = 0;
                break;
            }

            smokeperl_object *o = sv_obj_info(v);
            if (!o || !o->ptr) {
                if (m->type().isRef()) {
                    m->unsupported();
                }
                m->item().s_class = 0;
                break;
            }
            m->item().s_class = o->ptr;
            break;
        }

        case Marshall::ToSV: {
            if (m->item().s_voidp == 0) {
                sv_setsv(m->var(), &PL_sv_undef);
                break;
            }

            void *p = m->item().s_voidp;
            SV *obj = getPointerObject(p);
            if(obj != &PL_sv_undef) {
                sv_setsv_mg( m->var(), obj );
                break;
            }
            smokeperl_object* o = alloc_smokeperl_object(false, m->smoke(), m->smoke()->findClass("QVariant").index, p);
		
            obj = set_obj_info(" Qt::DBusVariant", o);

            if (do_debug & qtdb_calls) {
                smokeperl_object *o = sv_obj_info( obj );
                printf("Allocating %s %p -> %p\n", "Qt::DBusVariant", o->ptr, (void*)obj);
            }

            if (m->type().isStack()) {
                o->allocated = true;
                // Keep a mapping of the pointer so that it is only wrapped once
                mapPointer(obj, o, pointer_map, o->classId, 0);
            }

            sv_setsv(m->var(), obj);
            break;
        }

        default:
            m->unsupported();
            break;
    }
}

#if QT_VERSION >= 0x40200
void marshall_QDBusReplyQStringList(Marshall *m) {
    switch(m->action()) {
        case Marshall::FromSV:
            m->unsupported();
        break;
        case Marshall::ToSV: {
            QDBusReply<QStringList>* reply = (QDBusReply<QStringList>*)m->item().s_voidp;
            HV* hv = newHV();
            SV* sv = newRV_noinc((SV*)hv);
            sv_bless(sv, gv_stashpv("Qt::DBusReply", TRUE));
            SvSetMagicSV(m->var(), sv);

            // Make the DBusError object
            QDBusError* error = new QDBusError(reply->error());
            smokeperl_object* o = alloc_smokeperl_object(
                true, m->smoke(), m->smoke()->findClass("QDBusError").index, error );
            const char* classname = perlqt_modules[o->smoke].resolve_classname(o);
            SV* errorsv = set_obj_info( classname, o );
            hv_store(hv, "error", 5, errorsv, 0);

            QVariant* variant;
            if (reply->isValid()) {
                QStringList replyValue = reply->value();
                variant = new QVariant(replyValue);
            }
            else {
                variant = new QVariant();
            }

            Smoke* returnSmoke =
                        Smoke::classMap["QVariant"].smoke;
            o = alloc_smokeperl_object(
                true, returnSmoke, returnSmoke->findClass("QVariant").index, variant );
            classname = perlqt_modules[o->smoke].resolve_classname(o);
            SV* variantsv = set_obj_info( classname, o );
            hv_store(hv, "data", 4, variantsv, 0);
        }
        break;
        default:
            m->unsupported();
        break;
    }
}
#endif

TypeHandler QtDBus4_handlers[] = {
    { "QDBusVariant", marshall_QDBusVariant },
    { "QDBusVariant&", marshall_QDBusVariant },
#if QT_VERSION >= 0x40200
    { "QDBusReply<QStringList>", marshall_QDBusReplyQStringList },
#endif
    { 0, 0 } //end of list
};
