#ifndef PERLQT_UTIL_H
#define PERLQT_UTIL_H
// Include Qt4 headers first, to avoid weirdness that the perl headers cause
#include <QtCore/QHash>
#include <QtCore/QList>
#include <QtCore/QMetaMethod>
#include <QtCore/QMetaObject>
#include <QtCore/QRegExp>
#include <QtGui/QPainter>
#include <QtGui/QPaintEngine>
#include <QtGui/QPalette>
#include <QtGui/QIcon>
#include <QtGui/QBitmap>
#include <QtGui/QCursor>
#include <QtGui/QSizePolicy>
#include <QtGui/QKeySequence>
#include <QtGui/QTextLength>
#include <QtGui/QTextFormat>

// Perl headers
extern "C" {
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
}

// Now my own headers
#include "smoke.h"
#include "QtCore4.h"
#include "binding.h"
#include "smokeperl.h"
#include "marshall_types.h" // Method call classes
#include "handlers.h" // for install_handlers function

Q_DECL_EXPORT COP* caller(I32 count);

Q_DECL_EXPORT smokeperl_object * alloc_smokeperl_object(bool allocated, Smoke * smoke, int classId, void * ptr);
SV* alloc_perl_moduleindex( int smokeIndex, Smoke::Index classOrMethIndex );

#ifdef PERLQTDEBUG
void catRV( SV *r, SV *sv );
void catSV( SV *r, SV *sv );
void catAV( SV *r, AV *av );
SV* catArguments(SV** sp, int n);

SV* prettyPrintMethod(Smoke::ModuleIndex id);
#endif

const char* get_SVt(SV* sv);

QList<MocArgument*> getMocArguments(Smoke* smoke, const char * typeName,
  QList<QByteArray> methodTypes);
Q_DECL_EXPORT SV* getPointerObject(void* ptr);

int isDerivedFromByName(const char *className, const char *baseClassName, int count);
int isDerivedFrom(smokeperl_object *o, const char *baseClassName);
int isDerivedFrom(Smoke *smoke, const char *className, const char *baseClassName, int cnt);
int isDerivedFrom(Smoke *smoke, Smoke::Index classId, Smoke *baseSmoke, Smoke::Index baseId, int count);
int isDerivedFrom(Smoke *smoke, Smoke::Index classId, Smoke::Index baseId, int cnt);

void mapPointer(SV *obj, smokeperl_object *o, HV *hv, Smoke::Index classId,
  void *lastptr);

SV* package_classId( const char *package );

const char* resolve_classname_qt( smokeperl_object* o );

void* sv_to_ptr(SV* sv);

Q_DECL_EXPORT SV* set_obj_info(const char * className, smokeperl_object * o);

void unmapPointer(smokeperl_object* o, Smoke::Index classId, void* lastptr);

XS(XS_qobject_qt_metacast);
XS(XS_find_qobject_children);

XS(XS_q_register_resource_data);
XS(XS_q_unregister_resource_data);

XS(XS_qabstract_item_model_rowcount);
XS(XS_qabstract_item_model_columncount);
XS(XS_qabstract_item_model_data);
XS(XS_qabstract_item_model_setdata);
XS(XS_qabstract_item_model_insertrows);
XS(XS_qabstract_item_model_insertcolumns);
XS(XS_qabstract_item_model_removerows);
XS(XS_qabstract_item_model_removecolumns);

XS(XS_qabstractitemmodel_createindex);
XS(XS_qmodelindex_internalpointer);

XS(XS_qbytearray_data);

XS(XS_qiodevice_read);
XS(XS_qdatastream_readrawdata);

XS(XS_qvariant_value);
XS(XS_qvariant_from_value);

XS(XS_AUTOLOAD);
XS(XS_qt_metacall);
XS(XS_signal);
XS(XS_super);
XS(XS_this);

#endif
