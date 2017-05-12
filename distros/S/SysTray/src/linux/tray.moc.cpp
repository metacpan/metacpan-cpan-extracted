/****************************************************************************
** KTray meta object code from reading C++ file 'tray.h'
**
** Created: Fri Jan 30 12:03:46 2009
**      by: The Qt MOC ($Id: qt/moc_yacc.cpp   3.3.3   edited Aug 5 16:40 $)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#undef QT_NO_COMPAT
#include "tray.h"
#include <qmetaobject.h>
#include <qapplication.h>

#include <private/qucomextra_p.h>
#if !defined(Q_MOC_OUTPUT_REVISION) || (Q_MOC_OUTPUT_REVISION != 26)
#error "This file was generated using the moc from 3.3.3. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

const char *KTray::className() const
{
    return "KTray";
}

QMetaObject *KTray::metaObj = 0;
static QMetaObjectCleanUp cleanUp_KTray( "KTray", &KTray::staticMetaObject );

#ifndef QT_NO_TRANSLATION
QString KTray::tr( const char *s, const char *c )
{
    if ( qApp )
	return qApp->translate( "KTray", s, c, QApplication::DefaultCodec );
    else
	return QString::fromLatin1( s );
}
#ifndef QT_NO_TRANSLATION_UTF8
QString KTray::trUtf8( const char *s, const char *c )
{
    if ( qApp )
	return qApp->translate( "KTray", s, c, QApplication::UnicodeUTF8 );
    else
	return QString::fromUtf8( s );
}
#endif // QT_NO_TRANSLATION_UTF8

#endif // QT_NO_TRANSLATION

QMetaObject* KTray::staticMetaObject()
{
    if ( metaObj )
	return metaObj;
    QMetaObject* parentObject = KSystemTray::staticMetaObject();
    static const QUParameter param_slot_0[] = {
	{ 0, &static_QUType_int, 0, QUParameter::In }
    };
    static const QUMethod slot_0 = {"slotContextMenuActivated", 1, param_slot_0 };
    static const QUMethod slot_1 = {"slotContextMenuAboutToShow", 0, 0 };
    static const QMetaData slot_tbl[] = {
	{ "slotContextMenuActivated(int)", &slot_0, QMetaData::Protected },
	{ "slotContextMenuAboutToShow()", &slot_1, QMetaData::Protected }
    };
    metaObj = QMetaObject::new_metaobject(
	"KTray", parentObject,
	slot_tbl, 2,
	0, 0,
#ifndef QT_NO_PROPERTIES
	0, 0,
	0, 0,
#endif // QT_NO_PROPERTIES
	0, 0 );
    cleanUp_KTray.setMetaObject( metaObj );
    return metaObj;
}

void* KTray::qt_cast( const char* clname )
{
    if ( !qstrcmp( clname, "KTray" ) )
	return this;
    return KSystemTray::qt_cast( clname );
}

bool KTray::qt_invoke( int _id, QUObject* _o )
{
    switch ( _id - staticMetaObject()->slotOffset() ) {
    case 0: slotContextMenuActivated((int)static_QUType_int.get(_o+1)); break;
    case 1: slotContextMenuAboutToShow(); break;
    default:
	return KSystemTray::qt_invoke( _id, _o );
    }
    return TRUE;
}

bool KTray::qt_emit( int _id, QUObject* _o )
{
    return KSystemTray::qt_emit(_id,_o);
}
#ifndef QT_NO_PROPERTIES

bool KTray::qt_property( int id, int f, QVariant* v)
{
    return KSystemTray::qt_property( id, f, v);
}

bool KTray::qt_static_property( QObject* , int , int , QVariant* ){ return FALSE; }
#endif // QT_NO_PROPERTIES
