// Include Qt4 headers first, to avoid weirdness that the perl headers cause
#include <QtCore/QAbstractItemModel>
#include <QtCore/QEvent>
#include <QtCore/QHash>
#include <QtCore/qglobal.h>
#include <QtCore/QList>
#include <QtCore/QMetaMethod>
#include <QtCore/QMetaObject>
#include <QtCore/QModelIndex>
#include <QtCore/QRegExp>
#include <QtGui/QPainter>
#include <QtGui/QPaintEngine>
#include <QtGui/QPalette>
#include <QtGui/QIcon>
#include <QtGui/QBitmap>
#include <QtGui/QCursor>
#include <QtGui/QGraphicsItem>
#include <QtGui/QLayoutItem>
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
#include "util.h"
#include "marshall_types.h" // Method call classes
#include "handlers.h" // for install_handlers function

extern bool qRegisterResourceData(int, const unsigned char *, const unsigned char *, const unsigned char *);
extern bool qUnregisterResourceData(int, const unsigned char *, const unsigned char *, const unsigned char *);

// Standard smoke variables
extern Q_DECL_EXPORT Smoke* qtcore_Smoke;
extern Q_DECL_EXPORT QList<Smoke*> smokeList;
extern Q_DECL_EXPORT QList<QString> arrayTypes;

PerlQt4::Binding binding;
QHash<Smoke*, PerlQt4Module> perlqt_modules;

// Global variables
Q_DECL_EXPORT SV* sv_this = 0;
SV* sv_qapp = 0;
Q_DECL_EXPORT HV* pointer_map = 0;
Q_DECL_EXPORT int do_debug = 0;

// There's a comment in QtRuby about possible memory leaks with these.
// Method caches, to avoid expensive lookups
QHash<QByteArray, Smoke::ModuleIndex *> methcache;

// These 2 functions, S_dopoptosub_at and caller() were copied from pp_ctl.c in
// Perl 5.10.1.  They may not work with all perl versions.  It makes
// determining the caller much easier. caller() is PP(pp_caller).
#define dopoptosub_at		S_dopoptosub_at
STATIC I32
S_dopoptosub_at(const PERL_CONTEXT *cxstk, I32 startingblock)
{
    dVAR;
    I32 i;

    for (i = startingblock; i >= 0; i--) {
        register const PERL_CONTEXT * const cx = &cxstk[i];
        switch (CxTYPE(cx)) {
            default:
                continue;
            case CXt_EVAL:
            case CXt_SUB:
            case CXt_FORMAT:
                DEBUG_l( Perl_deb(aTHX_ "(Found sub #%ld)\n", (long)i));
                return i;
        }
    }
    return i;
}

Q_DECL_EXPORT COP* caller(I32 count)
{
    register I32 cxix = dopoptosub_at(cxstack, cxstack_ix);
    register const PERL_CONTEXT *cx;
    register const PERL_CONTEXT *ccstack = cxstack;
    const PERL_SI *top_si = PL_curstackinfo;

    for (;;) {
        /* we may be in a higher stacklevel, so dig down deeper */
        while (cxix < 0 && top_si->si_type != PERLSI_MAIN) {
            top_si = top_si->si_prev;
            ccstack = top_si->si_cxstack;
            cxix = dopoptosub_at(ccstack, top_si->si_cxix);
        }
        if (cxix < 0) {
            return 0;
        }
        /* caller() should not report the automatic calls to &DB::sub */
        if (PL_DBsub && GvCV(PL_DBsub) && cxix >= 0 &&
                ccstack[cxix].blk_sub.cv == GvCV(PL_DBsub))
            count++;
        if (!count--)
            break;
        cxix = dopoptosub_at(ccstack, cxix - 1);
    }

    cx = &ccstack[cxix];
    if (CxTYPE(cx) == CXt_SUB || CxTYPE(cx) == CXt_FORMAT) {
        const I32 dbcxix = dopoptosub_at(ccstack, cxix - 1);
	/* We expect that ccstack[dbcxix] is CXt_SUB, anyway, the
	   field below is defined for any cx. */
	/* caller() should not report the automatic calls to &DB::sub */
	if (PL_DBsub && GvCV(PL_DBsub) && dbcxix >= 0 && ccstack[dbcxix].blk_sub.cv == GvCV(PL_DBsub))
	    cx = &ccstack[dbcxix];
    }

    return cx->blk_oldcop;
}

Q_DECL_EXPORT smokeperl_object * 
alloc_smokeperl_object(bool allocated, Smoke * smoke, int classId, void * ptr) {
    smokeperl_object * o = new smokeperl_object;
    o->classId = classId;
    o->smoke = smoke;
    o->ptr = ptr;
    o->allocated = allocated;
    return o;
}

SV* alloc_perl_moduleindex( int smokeIndex, Smoke::Index classOrMethIndex ) {
    AV* av = newAV();
    SV* sv = newRV_noinc( (SV*)av );
    av_push( av, newSViv((IV)smokeIndex) );
    av_push( av, newSViv((IV)classOrMethIndex) );
    return sv;
}

#ifdef PERLQTDEBUG
void catRV( SV *r, SV *sv );
void catSV( SV *r, SV *sv );
void catAV( SV *r, AV *av );

void catRV( SV *r, SV *sv ) {
    smokeperl_object *o = sv_obj_info(sv);
    if(o)
        // Got a cxx type.
        sv_catpvf(r, "(%s*)0x%p",o->smoke->className(o->classId), o->ptr);
    else if (SvTYPE(SvRV(sv)) == SVt_PVMG)
        // Got a blessed hash
        sv_catpvf(r, "%s(%s)", HvNAME(SvSTASH(SvRV(sv))), SvPV_nolen(SvRV(sv)));
    else if (SvTYPE(SvRV(sv)) == SVt_PVAV) {
        // got an array ref
        catAV( r, (AV*)SvRV(sv) );
    }
    else
        sv_catsv(r, sv);
}

void catAV( SV *r, AV *av ) {
    long count = av_len( av ) + 1;
    sv_catpv(r, "[");
    for( long i = 0; i < count; ++i ) {
        if(i) sv_catpv(r, ", ");
        SV** item = av_fetch( av, i, 0 );
        if( !item )
            continue;
        else if(SvROK(*item))
            catRV(r, *item);
        else
            catSV(r, *item);
    }
    sv_catpv(r, "]");
}

void catSV( SV *r, SV *sv ) {
    bool isString = SvPOK(sv);
    STRLEN len;
    char *s = SvPV(sv, len);
    if(isString) sv_catpv(r, "'");
    sv_catpvn(r, s, len > 10 ? 10 : len);
    if(len > 10) sv_catpv(r, "...");
    if(isString) sv_catpv(r, "'");
}

// Args: SV** sp: the stack pointer containing the args to display
//       int n: the number of args
// Returns: An SV* containing a formatted string describing the arguments on
//          the stack
SV* catArguments(SV** sp, int n) {
    SV* r = newSVpv("", 0);
    for(int i = 0; i < n; i++) {
        if(i) sv_catpv(r, ", ");
        if(!SvOK(sp[i])) {
            // Not a valid sv, print undef
            sv_catpv(r, "undef");
        }
        else if(SvROK(sp[i])) {
            catRV(r, sp[i]);
        }
        else {
            catSV(r, sp[i]);
        }
    }
    return r;
}

#endif

const char* get_SVt(SV* sv) {
    const char* r;
    if(!SvOK(sv))
        r = "u";
    else if(SvIOK(sv))
        r = "i";
    else if(SvNOK(sv))
        r = "n";
    else if(SvPOK(sv))
        r = "s";
    else if(SvROK(sv)) {
        smokeperl_object *o = sv_obj_info(sv);
        if(!o) {
            switch (SvTYPE(SvRV(sv))) {
                case SVt_PVAV:
                    r = "a";
                    break;
                case SVt_PVHV:
                    r = "h";
                    break;
                case SVt_PVMG: {
                    const char * classname = HvNAME(SvSTASH(SvRV(sv)));
                    if ( !strcmp( classname, "Qt::String" ) ||
                         !strcmp( classname, "Qt::CString" ) ||
                         !strcmp( classname, "Qt::Int" ) ||
                         !strcmp( classname, "Qt::Uint" ) ||
                         !strcmp( classname, "Qt::Short" ) ||
                         !strcmp( classname, "Qt::Ushort" ) ||
                         !strcmp( classname, "Qt::Uchar" ) ||
                         !strcmp( classname, "Qt::Bool" ) ) {
                        r = classname;
                    }
                    else {
                        // All enums are blessed scalars.
                        r = "e";
                    }
                    break;
                }
                default:
                    r = "r";
            }
        }
        else
            r = o->smoke->classes[o->classId].className;
    }
    else
        r = "U";
    return r;
}

// The length of the QList returned from this will always be one more than the
// number of arguments that the signal call takes.  The first spot is the type
// of the return value of the signal.
// For custom signals, the first value will always be xmoc_void, because we
// don't populate a return type for custom signals.
QList<MocArgument*> getMocArguments(Smoke* smoke, const char * typeName, QList<QByteArray> methodTypes) {
    static QRegExp * rx = 0;
    if (rx == 0) {
        rx = new QRegExp("^(bool|int|uint|long|ulong|double|char\\*|QString)&?$");
    }
    methodTypes.prepend(QByteArray(typeName));
    QList<MocArgument*> result;

    foreach (QByteArray name, methodTypes) {
        MocArgument *arg = new MocArgument;
        Smoke::Index typeId = 0;

        if (name.isEmpty()) {
            arg->argType = xmoc_void;
            result.append(arg);
        } else {
            name.replace("const ", "");
            QString staticType = (rx->indexIn(name) != -1 ? rx->cap(1) : "ptr");
            if (staticType == "ptr") {
                arg->argType = xmoc_ptr;
                QByteArray targetType = name;
                typeId = smoke->idType(targetType.constData());
                if (typeId == 0 && !name.contains('*')) {
                    if (!name.contains("&")) {
                        targetType += "&";
                    }
                    typeId = smoke->idType(targetType.constData());
                }

                // This shouldn't be necessary because the type of the slot arg
                // should always be in the smoke module of the slot being
                // invoked. However, that isn't true for a dataUpdated() slot
                // in a PlasmaScripting::Applet
                if (typeId == 0) {
                    QHash<Smoke*, PerlQt4Module>::const_iterator it;
                    for (it = perlqt_modules.constBegin(); it != perlqt_modules.constEnd(); ++it) {
                        smoke = it.key();
                        targetType = name;
                        typeId = smoke->idType(targetType.constData());
                        if (typeId != 0) {
                            break;
                        }

                        if (typeId == 0 && !name.contains('*')) {
                            if (!name.contains("&")) {
                                targetType += "&";
                            }
                            typeId = smoke->idType(targetType.constData());	
                            if (typeId != 0) {
                                break;
                            }

                            targetType.prepend( "const " );
                            typeId = smoke->idType(targetType.constData());
                            if (typeId != 0) {
                                break;
                            }
                        }
                    }
                }	
            } else if (staticType == "bool") {
                arg->argType = xmoc_bool;
                smoke = qtcore_Smoke;
                typeId = smoke->idType(name.constData());
            } else if (staticType == "int") {
                arg->argType = xmoc_int;
                smoke = qtcore_Smoke;
                typeId = smoke->idType(name.constData());
            } else if (staticType == "uint") {
                arg->argType = xmoc_uint;
                smoke = qtcore_Smoke;
                typeId = smoke->idType(name.constData());
            } else if (staticType == "long") {
                arg->argType = xmoc_long;
                smoke = qtcore_Smoke;
                typeId = smoke->idType(name.constData());
            } else if (staticType == "ulong") {
                arg->argType = xmoc_ulong;
                smoke = qtcore_Smoke;
                typeId = smoke->idType(name.constData());
            } else if (staticType == "double") {
                arg->argType = xmoc_double;
                smoke = qtcore_Smoke;
                typeId = smoke->idType(name.constData());
            } else if (staticType == "char*") {
                arg->argType = xmoc_charstar;
                smoke = qtcore_Smoke;
                typeId = smoke->idType(name.constData());
            } else if (staticType == "QString") {
                arg->argType = xmoc_QString;
                name += "*";
                smoke = qtcore_Smoke;
                typeId = smoke->idType(name.constData());
            }

            if (typeId == 0) {
                croak("Cannot handle '%s' as slot argument\n", name.constData());
                return result;
            }

            arg->st.set(smoke, typeId);
            result.append(arg);
        }
    }

    return result;
}

// The pointer map gives us the relationship between an arbitrary c++ pointer
// and a perl SV.  If you have a virtual function call, you only start with a
// c++ pointer.  This reference allows you to trace back to a perl package, and
// find a subroutine in that package to call.
Q_DECL_EXPORT SV* getPointerObject(void* ptr) {
    if (PL_dirty) return 0;
    HV *hv = pointer_map;
    SV *keysv = newSViv((IV)ptr);
    STRLEN len;
    char *key = SvPV(keysv, len);
    // Look to see in the pointer_map for a ptr->perlSV reference
    SV **svp = hv_fetch(hv, key, len, 0);
    // Nothing found, exit out
    if(!svp){
        SvREFCNT_dec(keysv);
        return 0;
    }
    // Corrupt entry, not sure how this would happen
    if(!SvOK(*svp)){
        if(SvREFCNT(*svp) != 0)
            hv_delete(hv, key, len, G_DISCARD);
        SvREFCNT_dec(keysv);
        return 0;
    }
    SvREFCNT_dec(keysv);
    return *svp;
}

int isDerivedFrom(Smoke *smoke, Smoke::Index classId, Smoke *baseSmoke, Smoke::Index baseId, int count) {
    if (!classId || !baseId || !smoke || !baseSmoke)
        return -1;
    if (smoke == baseSmoke && classId == baseId)
        return count;
    ++count;

    for(Smoke::Index p = smoke->classes[classId].parents; smoke->inheritanceList[p]; p++) {
        Smoke::Class& cur = smoke->classes[smoke->inheritanceList[p]];
        if (cur.external) {
            Smoke::ModuleIndex mi = smoke->findClass(cur.className);
            if (isDerivedFrom(mi.smoke, mi.index, baseSmoke, baseId, count) != -1)
                return count;
        }
        if (isDerivedFrom(smoke, smoke->inheritanceList[p], baseSmoke, baseId, count) != -1)
            return count;
    }
    return -1;
}

int isDerivedFromByName(const char *className, const char *baseClassName, int count) {
    Smoke::ModuleIndex classId = qtcore_Smoke->findClass(className);
    Smoke::ModuleIndex baseId = qtcore_Smoke->findClass(baseClassName);
    return isDerivedFrom(classId.smoke, classId.index, baseId.smoke, baseId.index, count);
}

int isDerivedFrom(Smoke *smoke, Smoke::Index classId, Smoke::Index baseId, int cnt) {
    if(classId == baseId)
        return cnt;
    cnt++;
    for(Smoke::Index *p = smoke->inheritanceList + smoke->classes[classId].parents;
        *p;
        p++)
    {
        if(isDerivedFrom(smoke, *p, baseId, cnt) != -1)
            return cnt;
    }
    return -1;
}

int isDerivedFrom(Smoke *smoke, const char *className, const char *baseClassName, int cnt) {
    if(!smoke || !className || !baseClassName)
        return -1;
    Smoke::Index idClass = smoke->idClass(className).index;
    Smoke::Index idBase = smoke->idClass(baseClassName).index;
    return isDerivedFrom(smoke, idClass, idBase, cnt);
}

Q_DECL_EXPORT int isDerivedFrom( smokeperl_object *o, const char *baseClassName ) {
    Smoke::Index idClass = o->classId;
    Smoke::Index idBase = o->smoke->idClass(baseClassName).index;
    return isDerivedFrom(o->smoke, idClass, idBase, 0);
}

// Enter keys: integer memory address of a cxxptr, values: associated perl sv
// into pointer_map hash
// Recurse to store it also as casted to its parent classes, which could (and
// does) have different memory addresses
Q_DECL_EXPORT void mapPointer(SV *obj, smokeperl_object *o, HV *hv, Smoke::Index classId, void *lastptr) {
    void *ptr = o->smoke->cast(o->ptr, o->classId, classId);
    // This ends the recursion
    if(ptr != lastptr) {
        lastptr = ptr;
        SV *keysv = newSViv((IV)ptr);
        STRLEN len;
        char *key = SvPV(keysv, len);
        SV *rv = newSVsv(obj);
        sv_rvweaken(rv); // weak reference! See weaken docs in Scalar::Util
        hv_store(hv, key, len, rv, 0);
        SvREFCNT_dec(keysv);
    }
    for(Smoke::Index *i = o->smoke->inheritanceList + o->smoke->classes[classId].parents; *i; i++) {
        mapPointer(obj, o, hv, *i, lastptr);
    }
}

// Given the perl package, look up the smoke classid
// Depends on the classcache_ext hash being defined, which gets set in the
// init_class function in Qt::_internal
SV* package_classId( const char *package ) {
    // Get the cache hash
    HV* classcache_ext = get_hv( "Qt::_internal::package2classId", false );
    U32 klen = strlen( package );
    SV** classcache = hv_fetch( classcache_ext, package, klen, 0 );
    SV* item = 0;
    if( classcache ) {
        item = *classcache;
    }
    if( item ){
        return item;
    }

    // Get the ISA array, nisa is a temp string to build package::ISA
    char *nisa = new char[strlen(package)+6];
    sprintf( nisa, "%s::ISA", package );
    AV* isa = get_av( nisa, true );
    delete[] nisa;

    // Loop over the ISA array
    for( int i = 0; i <= av_len( isa ); i++ ) {
        // Get the value of the current index into @isa
        SV** parentPackage = av_fetch( isa, i, 0 );
        if( parentPackage ) {
            // Recurse until we find a match
            SV* ix = package_classId( SvPV_nolen( *parentPackage ) );
            if( ix ) {
                ;// Cache the result - TODO
                return ix;
            }
        }
    }
    // Found nothing, so
    return (Smoke::Index) 0;
}

#ifdef PERLQTDEBUG
// Args: Smoke::Index id: a smoke method id to print
// Returns: an SV* containing a formatted method signature string
SV* prettyPrintMethod(Smoke::ModuleIndex id) {
    SV* r = newSVpv("", 0);
    Smoke::Method& meth = id.smoke->methods[id.index];
    const char* tname = id.smoke->types[meth.ret].name;
    if(meth.flags & Smoke::mf_static) sv_catpv(r, "static ");
    sv_catpvf(r, "%s ", (tname ? tname:"void"));
    sv_catpvf(r, "%s::%s(", id.smoke->classes[meth.classId].className, id.smoke->methodNames[meth.name]);
    for(int i = 0; i < meth.numArgs; i++) {
        if(i) sv_catpv(r, ", ");
        tname = id.smoke->types[id.smoke->argumentList[meth.args+i]].name;
        sv_catpv(r, (tname ? tname:"void"));
    }
    sv_catpv(r, ")");
    if(meth.flags & Smoke::mf_const) sv_catpv(r, " const");
    return r;
}
#endif

const char* resolve_classname_qt( smokeperl_object* o ) {
    if (o->smoke->isDerivedFrom(o->smoke->classes[o->classId].className, "QEvent")) {
        QEvent * qevent = (QEvent *) o->smoke->cast(o->ptr, o->classId, o->smoke->idClass("QEvent").index);
        switch (qevent->type()) {
            case QEvent::Timer:
                o->smoke = Smoke::classMap["QTimerEvent"].smoke;
                o->classId = o->smoke->idClass("QTimerEvent").index;
                break;
            case QEvent::MouseButtonPress:
            case QEvent::MouseButtonRelease:
            case QEvent::MouseButtonDblClick:
            case QEvent::MouseMove:
                o->smoke = Smoke::classMap["QMouseEvent"].smoke;
                o->classId = o->smoke->idClass("QMouseEvent").index;
                break;
            case QEvent::KeyPress:
            case QEvent::KeyRelease:
            case QEvent::ShortcutOverride:
                o->smoke = Smoke::classMap["QKeyEvent"].smoke;
                o->classId = o->smoke->idClass("QKeyEvent").index;
                break;
            case QEvent::FocusIn:
            case QEvent::FocusOut:
                o->smoke = Smoke::classMap["QFocusEvent"].smoke;
                o->classId = o->smoke->idClass("QFocusEvent").index;
                break;
            case QEvent::Enter:
            case QEvent::Leave:
                o->smoke = Smoke::classMap["QEvent"].smoke;
                o->classId = o->smoke->idClass("QEvent").index;
                break;
            case QEvent::Paint:
                o->smoke = Smoke::classMap["QPaintEvent"].smoke;
                o->classId = o->smoke->idClass("QPaintEvent").index;
                break;
            case QEvent::Move:
                o->smoke = Smoke::classMap["QMoveEvent"].smoke;
                o->classId = o->smoke->idClass("QMoveEvent").index;
                break;
            case QEvent::Resize:
                o->smoke = Smoke::classMap["QResizeEvent"].smoke;
                o->classId = o->smoke->idClass("QResizeEvent").index;
                break;
            case QEvent::Create:
            case QEvent::Destroy:
                o->smoke = Smoke::classMap["QEvent"].smoke;
                o->classId = o->smoke->idClass("QEvent").index;
                break;
            case QEvent::Show:
                o->smoke = Smoke::classMap["QShowEvent"].smoke;
                o->classId = o->smoke->idClass("QShowEvent").index;
                break;
            case QEvent::Hide:
                o->smoke = Smoke::classMap["QHideEvent"].smoke;
                o->classId = o->smoke->idClass("QHideEvent").index;
            case QEvent::Close:
                o->smoke = Smoke::classMap["QCloseEvent"].smoke;
                o->classId = o->smoke->idClass("QCloseEvent").index;
                break;
            case QEvent::Quit:
            case QEvent::ParentChange:
            case QEvent::ParentAboutToChange:
            case QEvent::ThreadChange:
            case QEvent::WindowActivate:
            case QEvent::WindowDeactivate:
            case QEvent::ShowToParent:
            case QEvent::HideToParent:
                o->smoke = Smoke::classMap["QEvent"].smoke;
                o->classId = o->smoke->idClass("QEvent").index;
                break;
            case QEvent::Wheel:
                o->smoke = Smoke::classMap["QWheelEvent"].smoke;
                o->classId = o->smoke->idClass("QWheelEvent").index;
                break;
            case QEvent::WindowTitleChange:
            case QEvent::WindowIconChange:
            case QEvent::ApplicationWindowIconChange:
            case QEvent::ApplicationFontChange:
            case QEvent::ApplicationLayoutDirectionChange:
            case QEvent::ApplicationPaletteChange:
            case QEvent::PaletteChange:
                o->smoke = Smoke::classMap["QEvent"].smoke;
                o->classId = o->smoke->idClass("QEvent").index;
                break;
            case QEvent::Clipboard:
                o->smoke = Smoke::classMap["QClipboardEvent"].smoke;
                o->classId = o->smoke->idClass("QClipboardEvent").index;
                break;
            case QEvent::Speech:
            case QEvent::MetaCall:
            case QEvent::SockAct:
            case QEvent::WinEventAct:
            case QEvent::DeferredDelete:
                o->smoke = Smoke::classMap["QEvent"].smoke;
                o->classId = o->smoke->idClass("QEvent").index;
                break;
            case QEvent::DragEnter:
                o->smoke = Smoke::classMap["QDragEnterEvent"].smoke;
                o->classId = o->smoke->idClass("QDragEnterEvent").index;
                break;
            case QEvent::DragLeave:
                o->smoke = Smoke::classMap["QDragLeaveEvent"].smoke;
                o->classId = o->smoke->idClass("QDragLeaveEvent").index;
                break;
            case QEvent::DragMove:
                o->smoke = Smoke::classMap["QDragMoveEvent"].smoke;
                o->classId = o->smoke->idClass("QDragMoveEvent").index;
            case QEvent::Drop:
                o->smoke = Smoke::classMap["QDropEvent"].smoke;
                o->classId = o->smoke->idClass("QDropEvent").index;
                break;
            case QEvent::DragResponse:
                o->smoke = Smoke::classMap["QDragResponseEvent"].smoke;
                o->classId = o->smoke->idClass("QDragResponseEvent").index;
                break;
            case QEvent::ChildAdded:
            case QEvent::ChildRemoved:
            case QEvent::ChildPolished:
                o->smoke = Smoke::classMap["QChildEvent"].smoke;
                o->classId = o->smoke->idClass("QChildEvent").index;
                break;
            case QEvent::ShowWindowRequest:
            case QEvent::PolishRequest:
            case QEvent::Polish:
            case QEvent::LayoutRequest:
            case QEvent::UpdateRequest:
            case QEvent::EmbeddingControl:
            case QEvent::ActivateControl:
            case QEvent::DeactivateControl:
                o->smoke = Smoke::classMap["QEvent"].smoke;
                o->classId = o->smoke->idClass("QEvent").index;
                break;
            case QEvent::ContextMenu:
                o->smoke = Smoke::classMap["QContextMenuEvent"].smoke;
                o->classId = o->smoke->idClass("QContextMenuEvent").index;
                break;
            case QEvent::InputMethod:
                o->smoke = Smoke::classMap["QInputMethodEvent"].smoke;
                o->classId = o->smoke->idClass("QInputMethodEvent").index;
                break;
            case QEvent::AccessibilityPrepare:
                o->smoke = Smoke::classMap["QEvent"].smoke;
                o->classId = o->smoke->idClass("QEvent").index;
                break;
            case QEvent::TabletMove:
            case QEvent::TabletPress:
            case QEvent::TabletRelease:
                o->smoke = Smoke::classMap["QTabletEvent"].smoke;
                o->classId = o->smoke->idClass("QTabletEvent").index;
                break;
            case QEvent::LocaleChange:
            case QEvent::LanguageChange:
            case QEvent::LayoutDirectionChange:
            case QEvent::Style:
            case QEvent::OkRequest:
            case QEvent::HelpRequest:
                o->smoke = Smoke::classMap["QEvent"].smoke;
                o->classId = o->smoke->idClass("QEvent").index;
                break;
            case QEvent::IconDrag:
                o->smoke = Smoke::classMap["QIconDragEvent"].smoke;
                o->classId = o->smoke->idClass("QIconDragEvent").index;
                break;
            case QEvent::FontChange:
            case QEvent::EnabledChange:
            case QEvent::ActivationChange:
            case QEvent::StyleChange:
            case QEvent::IconTextChange:
            case QEvent::ModifiedChange:
            case QEvent::MouseTrackingChange:
                o->smoke = Smoke::classMap["QEvent"].smoke;
                o->classId = o->smoke->idClass("QEvent").index;
                break;
            case QEvent::WindowBlocked:
            case QEvent::WindowUnblocked:
            case QEvent::WindowStateChange:
                o->smoke = Smoke::classMap["QWindowStateChangeEvent"].smoke;
                o->classId = o->smoke->idClass("QWindowStateChangeEvent").index;
                break;
            case QEvent::ToolTip:
            case QEvent::WhatsThis:
                o->smoke = Smoke::classMap["QHelpEvent"].smoke;
                o->classId = o->smoke->idClass("QHelpEvent").index;
                break;
            case QEvent::StatusTip:
                o->smoke = Smoke::classMap["QEvent"].smoke;
                o->classId = o->smoke->idClass("QEvent").index;
                break;
            case QEvent::ActionChanged:
            case QEvent::ActionAdded:
            case QEvent::ActionRemoved:
                o->smoke = Smoke::classMap["QActionEvent"].smoke;
                o->classId = o->smoke->idClass("QActionEvent").index;
                break;
            case QEvent::FileOpen:
                o->smoke = Smoke::classMap["QFileOpenEvent"].smoke;
                o->classId = o->smoke->idClass("QFileOpenEvent").index;
                break;
            case QEvent::Shortcut:
                o->smoke = Smoke::classMap["QShortcutEvent"].smoke;
                o->classId = o->smoke->idClass("QShortcutEvent").index;
                break;
            case QEvent::WhatsThisClicked:
                o->smoke = Smoke::classMap["QWhatsThisClickedEvent"].smoke;
                o->classId = o->smoke->idClass("QWhatsThisClickedEvent").index;
                break;
            case QEvent::ToolBarChange:
                o->smoke = Smoke::classMap["QToolBarChangeEvent"].smoke;
                o->classId = o->smoke->idClass("QToolBarChangeEvent").index;
                break;
            case QEvent::ApplicationActivated:
            case QEvent::ApplicationDeactivated:
            case QEvent::QueryWhatsThis:
            case QEvent::EnterWhatsThisMode:
            case QEvent::LeaveWhatsThisMode:
            case QEvent::ZOrderChange:
                o->smoke = Smoke::classMap["QEvent"].smoke;
                o->classId = o->smoke->idClass("QEvent").index;
                break;
            case QEvent::HoverEnter:
            case QEvent::HoverLeave:
            case QEvent::HoverMove:
                o->smoke = Smoke::classMap["QHoverEvent"].smoke;
                o->classId = o->smoke->idClass("QHoverEvent").index;
                break;
            case QEvent::AccessibilityHelp:
            case QEvent::AccessibilityDescription:
                o->smoke = Smoke::classMap["QEvent"].smoke;
                o->classId = o->smoke->idClass("QEvent").index;
#if QT_VERSION >= 0x40200
            case QEvent::GraphicsSceneMouseMove:
            case QEvent::GraphicsSceneMousePress:
            case QEvent::GraphicsSceneMouseRelease:
            case QEvent::GraphicsSceneMouseDoubleClick:
                o->smoke = Smoke::classMap["QGraphicsSceneMouseEvent"].smoke;
                o->classId = o->smoke->idClass("QGraphicsSceneMouseEvent").index;
                break;
            case QEvent::GraphicsSceneContextMenu:
                o->smoke = Smoke::classMap["QGraphicsSceneContextMenuEvent"].smoke;
                o->classId = o->smoke->idClass("QGraphicsSceneContextMenuEvent").index;
                break;
            case QEvent::GraphicsSceneHoverEnter:
            case QEvent::GraphicsSceneHoverMove:
            case QEvent::GraphicsSceneHoverLeave:
                o->smoke = Smoke::classMap["QGraphicsSceneHoverEvent"].smoke;
                o->classId = o->smoke->idClass("QGraphicsSceneHoverEvent").index;
                break;
            case QEvent::GraphicsSceneHelp:
                o->smoke = Smoke::classMap["QGraphicsSceneHelpEvent"].smoke;
                o->classId = o->smoke->idClass("QGraphicsSceneHelpEvent").index;
                break;
            case QEvent::GraphicsSceneDragEnter:
            case QEvent::GraphicsSceneDragMove:
            case QEvent::GraphicsSceneDragLeave:
            case QEvent::GraphicsSceneDrop:
                o->smoke = Smoke::classMap["QGraphicsSceneDragDropEvent"].smoke;
                o->classId = o->smoke->idClass("QGraphicsSceneDragDropEvent").index;
                break;
            case QEvent::GraphicsSceneWheel:
                o->smoke = Smoke::classMap["QGraphicsSceneWheelEvent"].smoke;
                o->classId = o->smoke->idClass("QGraphicsSceneWheelEvent").index;
                break;
            case QEvent::KeyboardLayoutChange:
                o->smoke = Smoke::classMap["QEvent"].smoke;
                o->classId = o->smoke->idClass("QEvent").index;
                break;
#endif
            default:
                break;
        }
    } else if (o->smoke->isDerivedFrom(o->smoke->classes[o->classId].className, "QObject")) {
        QObject * qobject = (QObject *) o->smoke->cast(o->ptr, o->classId, o->smoke->idClass("QObject").index);
        const QMetaObject * meta = qobject->metaObject();

        while (meta != 0) {
            o->smoke = Smoke::classMap[meta->className()].smoke;
            if (o->smoke != 0) {
                o->classId = o->smoke->idClass(meta->className()).index;
                if (o->classId != 0) {
                    return perlqt_modules[o->smoke].binding->className(o->classId);
                }
            }

            meta = meta->superClass();
        }
    } else if (o->smoke->isDerivedFrom(o->smoke->classes[o->classId].className, "QGraphicsItem")) {
        QGraphicsItem * item = (QGraphicsItem *) o->smoke->cast(o->ptr, o->classId, o->smoke->idClass("QGraphicsItem").index);
        switch (item->type()) {
            case 1:
                o->smoke = Smoke::classMap["QGraphicsItem"].smoke;
                o->classId = o->smoke->idClass("QGraphicsItem").index;
                break;
            case 2:
                o->smoke = Smoke::classMap["QGraphicsPathItem"].smoke;
                o->classId = o->smoke->idClass("QGraphicsPathItem").index;
                break;
            case 3:
                o->smoke = Smoke::classMap["QGraphicsRectItem"].smoke;
                o->classId = o->smoke->idClass("QGraphicsRectItem").index;
            case 4:
                o->smoke = Smoke::classMap["QGraphicsEllipseItem"].smoke;
                o->classId = o->smoke->idClass("QGraphicsEllipseItem").index;
                break;
            case 5:
                o->smoke = Smoke::classMap["QGraphicsPolygonItem"].smoke;
                o->classId = o->smoke->idClass("QGraphicsPolygonItem").index;
                break;
            case 6:
                o->smoke = Smoke::classMap["QGraphicsLineItem"].smoke;
                o->classId = o->smoke->idClass("QGraphicsLineItem").index;
                break;
            case 7:
                o->smoke = Smoke::classMap["QGraphicsItem"].smoke;
                o->classId = o->smoke->idClass("QGraphicsItem").index;
                break;
            case 8:
                o->smoke = Smoke::classMap["QGraphicsTextItem"].smoke;
                o->classId = o->smoke->idClass("QGraphicsTextItem").index;
                break;
            case 9:
                o->smoke = Smoke::classMap["QGraphicsSimpleTextItem"].smoke;
                o->classId = o->smoke->idClass("QGraphicsSimpleTextItem").index;
                break;
            case 10:
                o->smoke = Smoke::classMap["QGraphicsItemGroup"].smoke;
                o->classId = o->smoke->idClass("QGraphicsItemGroup").index;
                break;
        }
    } else if (o->smoke->isDerivedFrom(o->smoke->classes[o->classId].className, "QLayoutItem")) {
        QLayoutItem * item = (QLayoutItem *) o->smoke->cast(o->ptr, o->classId, o->smoke->idClass("QLayoutItem").index);
        if (item->widget() != 0) {
            o->smoke = Smoke::classMap["QWidgetItem"].smoke;
            o->classId = o->smoke->idClass("QWidgetItem").index;
        } else if (item->spacerItem() != 0) {
            o->smoke = Smoke::classMap["QSpacerItem"].smoke;
            o->classId = o->smoke->idClass("QSpacerItem").index;
        }
    }

    return perlqt_modules[o->smoke].binding->className(o->classId);
}

Q_DECL_EXPORT SV* set_obj_info(const char * className, smokeperl_object * o) {
    // The hash
    SV* obj;
    SV* var;
    if( arrayTypes.contains( className ) ) {
        obj = (SV*)newAV();
        var = newRV_noinc((SV*)obj);
        hv_magic((AV*)obj, var, PERL_MAGIC_tied);
    }
    else {
        obj = (SV*)newHV();
        var = newRV_noinc((SV*)obj);
    }

    // The hash reference to return

    // Bless the sv to that package.
    sv_bless( var, gv_stashpv(className, TRUE) );

    // For this, we need a magic wand.  This is what actually
    // stores 'o' into our hash.
    sv_magicext((SV*)obj, 0, '~', &vtbl_smoke, (char*)o, sizeof(*o));

    // We're done with our local var
    return var;
}

// Returns the memory address of the cxxptr stored within a given sv.
void* sv_to_ptr(SV* sv) {
    smokeperl_object* o = sv_obj_info(sv);
    return o ? o->ptr : 0;
}

// Remove the values entered in pointer_map hash, called from
// PerlQt4::Binding::deleted when the destructor of a smoke object is called
void unmapPointer( smokeperl_object* o, Smoke::Index classId, void* lastptr) {
    HV* hv = pointer_map;
    void* ptr = o->smoke->cast( o->ptr, o->classId, classId );
    if( ptr != lastptr) { //recurse
        lastptr = ptr;
        SV* keysv = newSViv((IV)ptr);
        STRLEN len;
        char* key = SvPV(keysv, len);
        if(hv_exists(hv, key, len))
            hv_delete(hv, key, len, G_DISCARD);
        SvREFCNT_dec(keysv);
    }
    // Do the same for all parent classes
    for(Smoke::Index *i = o->smoke->inheritanceList + o->smoke->classes[classId].parents; *i; i++) {
        unmapPointer(o, *i, lastptr);
    }
}

/* Adapted from the internal function qt_qFindChildren() in qobject.cpp */
static void 
pl_qFindChildren_helper(SV* parent, const QString &objectName, SV* re,
                         const QMetaObject &mo, AV* list)
{
    char* classname = HvNAME((HV*)SvSTASH(SvRV(parent)));
    char* methodname = new char[ strlen(classname) + 11 ];
    strcpy( methodname, classname );
    strcat( methodname, "::children" );

    dSP; ENTER; SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(parent);
    PUTBACK;
    int count = call_pv( methodname, G_SCALAR );
    delete[] methodname;
    SPAGAIN;
    SV* childrenref = POPs;
    AV* children = (AV*)SvRV(childrenref);
    PUTBACK; FREETMPS; LEAVE;

    SV* rv = &PL_sv_undef;
    for (int i = 0; i < av_len(children)+1; ++i) {
        rv = *(av_fetch(children, i, 0));
        smokeperl_object *o = sv_obj_info(rv);
        QObject * obj = (QObject *) o->smoke->cast(o->ptr, o->classId, o->smoke->idClass("QObject").index);

        // The original code had 'if (mo.cast(obj))' as a test, but it doesn't work here
        if (obj->qt_metacast(mo.className()) != 0) {
            if (re != &PL_sv_undef) {
                //VALUE re_test = rb_funcall(re, rb_intern("=~"), 1, rb_funcall(rv, rb_intern("objectName"), 0));
                //if (re_test != Qnil && re_test != Qfalse) {
                //rb_ary_push(list, rv);
                //}
            } else {
                if (objectName.isNull() || obj->objectName() == objectName) {
                    av_push(list, rv);
                }
            }
        }
        pl_qFindChildren_helper(rv, objectName, re, mo, list);
    }
    return;
}

XS(XS_qobject_qt_metacast) {
    dXSARGS;
    SV* mythis=0;
    SV* klass=0;
    if( items == 1 ) {
        mythis = sv_this;
        klass = ST(0);
    }
    else if ( items == 2 ) {
        mythis = ST(0);
        klass = ST(1);
    }
    else {
        croak( "%s", "Invalid arguments to qobject_cast\n" );
    }

    smokeperl_object *o = sv_obj_info(mythis);
	if (o == 0 || o->ptr == 0) {
		XSRETURN_UNDEF;
	}

	const char * classname = SvPV_nolen(klass); //HvNAME(SvSTASH(SvRV(mythis)));
    SV* moduleIdRef = package_classId(classname);
	Smoke::Index classId = SvIV(*(SV**)av_fetch((AV*)SvRV(moduleIdRef), 1, 0));
	if (classId == 0) {
		XSRETURN_UNDEF;
	}

	QObject* qobj = (QObject*) o->smoke->cast(o->ptr, o->classId, o->smoke->idClass("QObject").index);
	if (qobj == 0) {
		XSRETURN_UNDEF;
	}

	void* ret = qobj->qt_metacast(qtcore_Smoke->classes[classId].className);

	if (ret == 0) {
		XSRETURN_UNDEF;
	}

    SV* obj = getPointerObject(ret);
    if ( !obj ) {
        smokeperl_object * o_cast = alloc_smokeperl_object(
            o->allocated, qtcore_Smoke, classId, ret );

        classname = perlqt_modules[o->smoke].resolve_classname(o);

        obj = sv_2mortal( set_obj_info( classname, o_cast ) );
        mapPointer(obj, o_cast, pointer_map, o_cast->classId, 0);
    }
    ST(0) = obj;
    XSRETURN(1);
}

/* Should mimic Qt4's QObject::findChildren method with this syntax:
     obj.findChildren("Object Type", "Optional Widget Name")
*/
XS(XS_find_qobject_children) {
    dXSARGS;
    if (items > 2 && items < 1) {
        croak("Qt::Object::findChildren takes 1 or 2 arguments, got %d", items);
        XSRETURN_UNDEF;
    }

    QString objectName;
    SV* re = &PL_sv_undef;
    if (items > 1) {
        // If the second arg isn't a String, assume it's a Qt::RegExp
        if (SvTYPE(ST(1)) == SVt_PV) {
            objectName = QString::fromLatin1(SvPV_nolen(ST(1)));
        } else {
            re = ST(1);
        }
    }

    SV* metaobjectSV;
    if (SvOK(ST(0)) && SvTYPE(ST(0)) == SVt_PV) {
        dSP; ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(ST(0));
        PUTBACK;
        int count = call_pv( "Qt::_internal::getMetaObject", G_SCALAR );
        SPAGAIN;
        metaobjectSV = POPs;
        PUTBACK;
        LEAVE;
        // metaobjectSV is now mortal.  Don't FREETMPS.
    }
    else {
        croak("First argument to Qt::Object::findChildren should be a string specifying a type");
    }

    smokeperl_object* metao = sv_obj_info(metaobjectSV);
    if(!metao) 
        croak("Call to get metaObject failed.");
    const QMetaObject* metaobject = (QMetaObject*)metao->ptr;
    AV* list = newAV();
    pl_qFindChildren_helper(sv_this, objectName, re, *metaobject, list);
    SV* result = newRV_noinc((SV*)list);
    ST(0) = result;
    XSRETURN(1);
}

XS(XS_q_register_resource_data)
{
    dXSARGS;
    if ( items != 4 ) {
        croak( "Usage: Qt::qRegisterResourceData( $version, $tree_value, $name_value, $data_value" );
    }

    SV* tree_value = ST(1);
    SV* name_value = ST(2);
    SV* data_value = ST(3);
	const unsigned char * tree = (const unsigned char *) malloc(SvLEN(tree_value));
	memcpy((void *) tree, (const void *) SvPV_nolen(tree_value), SvLEN(tree_value));

	const unsigned char * name = (const unsigned char *) malloc(SvLEN(name_value));
	memcpy((void *) name, (const void *) SvPV_nolen(name_value), SvLEN(name_value));

	const unsigned char * data = (const unsigned char *) malloc(SvLEN(data_value));
	memcpy((void *) data, (const void *) SvPV_nolen(data_value), SvLEN(data_value));

	if ( qRegisterResourceData(SvIV(ST(0)), tree, name, data) )
        XSRETURN_YES;
    else
        XSRETURN_NO;
}

XS(XS_q_unregister_resource_data)
{
    dXSARGS;
    if ( items != 4 ) {
        croak( "Usage: Qt::qUnregisterResourceData( $version, $tree_value, $name_value, $data_value" );
    }

    SV* tree_value = ST(1);
    SV* name_value = ST(2);
    SV* data_value = ST(3);
	const unsigned char * tree = (const unsigned char *) malloc(SvLEN(tree_value));
	memcpy((void *) tree, (const void *) SvPV_nolen(tree_value), SvLEN(tree_value));

	const unsigned char * name = (const unsigned char *) malloc(SvLEN(name_value));
	memcpy((void *) name, (const void *) SvPV_nolen(name_value), SvLEN(name_value));

	const unsigned char * data = (const unsigned char *) malloc(SvLEN(data_value));
	memcpy((void *) data, (const void *) SvPV_nolen(data_value), SvLEN(data_value));

	if ( qUnregisterResourceData(SvIV(ST(0)), tree, name, data) )
        XSRETURN_YES;
    else
        XSRETURN_NO;
}

XS(XS_qabstract_item_model_rowcount) {
    dXSARGS;
    smokeperl_object *o = sv_obj_info(ST(0));
    if(!o)
        croak( "%s", "Qt::AbstractItemModel::rowCount called on a non-Qt4"
            " object");
    if(isDerivedFrom(o, "QAbstractItemModel") == -1)
        croak( "%s", "Qt::AbstractItemModel::rowCount called on a"
            " non-AbstractItemModel object");

    QAbstractItemModel * model = (QAbstractItemModel *) o->ptr;

    if (items == 1) {
		XSRETURN_IV(model->rowCount());
	}
	else if (items == 2) {
		smokeperl_object * mi = sv_obj_info(ST(1));
        if(!mi)
            croak( "%s", "1st argument to Qt::AbstractItemModel::rowCount is"
                " not a Qt object");
        if(isDerivedFrom(mi, "QModelIndex") == -1)
            croak( "%s", "1st argument to Qt::AbstractItemModel::rowCount is"
                " not a Qt::ModelIndex" );

		QModelIndex * modelIndex = (QModelIndex *) mi->ptr;

		XSRETURN_IV(model->rowCount(*modelIndex));
	}
    else {
        croak("%s", "Invalid argument list to Qt::AbstractItemModel::rowCount");
    }
}

XS(XS_qabstract_item_model_columncount) {
    dXSARGS;
    smokeperl_object *o = sv_obj_info(ST(0));

    if(!o)
        croak( "%s", "Qt::AbstractItemModel::columnCount called on a non-Qt4"
            " object");
    if(isDerivedFrom(o, "QAbstractItemModel") == -1)
        croak( "%s", "Qt::AbstractItemModel::columnCount called on a"
            " non-AbstractItemModel object");

    QAbstractItemModel * model = (QAbstractItemModel *) o->ptr;

    if (items == 1) {
		XSRETURN_IV(model->columnCount());
	}
	else if (items == 2) {
		smokeperl_object * mi = sv_obj_info(ST(1));

        if(!mi)
            croak( "%s", "1st argument to Qt::AbstractItemModel::columnCount is"
                " not a Qt4 object");
        if(isDerivedFrom(mi, "QModelIndex") == -1)
            croak( "%s", "1st argument to Qt::AbstractItemModel::columnCount is"
                " not a Qt::ModelIndex" );

		QModelIndex * modelIndex = (QModelIndex *) mi->ptr;
		XSRETURN_IV(model->columnCount(*modelIndex));
	}
    else {
        croak("%s", "Invalid argument list to Qt::AbstractItemModel::columnCount");
    }
}

XS(XS_qabstract_item_model_data) {
    dXSARGS;
    smokeperl_object * o = sv_obj_info(ST(0));
    if(!o)
        croak( "%s", "Qt::AbstractItemModel::data called on a non-Qt4"
            " object");
    if(isDerivedFrom(o, "QAbstractItemModel") == -1)
        croak( "%s", "Qt::AbstractItemModel::data called on a"
            " non-AbstractItemModel object");
	QAbstractItemModel * model = (QAbstractItemModel *) o->ptr;

    smokeperl_object * mi = sv_obj_info(ST(1));
    if(!mi)
        croak( "%s", "1st argument to Qt::AbstractItemModel::data is"
            " not a Qt4 object");
    if(isDerivedFrom(mi, "QModelIndex") == -1)
        croak( "%s", "1st argument to Qt::AbstractItemModel::data is"
            " not a Qt::ModelIndex" );
	QModelIndex * modelIndex = (QModelIndex *) mi->ptr;

	QVariant value;
	if (items == 2) {
		value = model->data(*modelIndex);
	} else if (items == 3) {
        SV* dataRole = ST(2);
        if(SvROK(dataRole))
            dataRole = SvRV(dataRole);
		value = model->data(*modelIndex, SvIV(dataRole));
	} else {
		croak("%s", "Invalid argument list to Qt::AbstractItemModel::data");
	}

    smokeperl_object* obj = alloc_smokeperl_object(
        true,
        o->smoke,
        o->smoke->idClass("QVariant").index,
        new QVariant(value) );

    SV* retval = set_obj_info( " Qt::Variant", obj );

    ST(0) = sv_2mortal( retval );
    XSRETURN(1);
}

XS(XS_qabstract_item_model_setdata) {
    dXSARGS;
    if ( items < 1 || items > 4 ) {
        croak("%s\n", "Invalid argument list to Qt::AbstractItemModel::setData");
    }
    smokeperl_object * o = sv_obj_info(ST(0));
    if(!o)
        croak( "%s", "Qt::AbstractItemModel::setData called on a non-Qt4"
            " object");
    if(isDerivedFrom(o, "QAbstractItemModel") == -1)
        croak( "%s", "Qt::AbstractItemModel::setData called on a"
            " non-AbstractItemModel object");
	QAbstractItemModel * model = (QAbstractItemModel *) o->ptr;

    smokeperl_object * mi = sv_obj_info(ST(1));
    if(!mi)
        croak( "%s", "1st argument to Qt::AbstractItemModel::setData is"
            " not a Qt4 object");
    if(isDerivedFrom(mi, "QModelIndex") == -1)
        croak( "%s", "1st argument to Qt::AbstractItemModel::setData is"
            " not a Qt4::ModelIndex" );
	QModelIndex * modelIndex = (QModelIndex *) mi->ptr;

    smokeperl_object * v = sv_obj_info(ST(2));
    if(!v)
        croak( "%s", "2nd argument to Qt::AbstractItemModel::setData is"
            " not a Qt4 object");
    if(isDerivedFrom(v, "QVariant") == -1)
        croak( "%s", "2nd argument to Qt::AbstractItemModel::setData is"
            " not a Qt::Variant" );
	QVariant * variant = (QVariant *) v->ptr;

	if ( items == 3 ) {
		if ( model->setData(*modelIndex, *variant) ) {
            XSRETURN_YES;
        }
        else {
            XSRETURN_NO;
        }
	}
    else if ( items == 4 ) {
        SV* dataRole = ST(3);
        if(SvROK(dataRole))
            dataRole = SvRV(dataRole);
        if ( model->setData( *modelIndex, *variant, SvIV(dataRole) ) ) {
            XSRETURN_YES;
        }
        else {
            XSRETURN_NO;
        }
    }
}

XS(XS_qabstract_item_model_insertrows) {
    dXSARGS;
    smokeperl_object *o = sv_obj_info(ST(0));
    if(!o)
        croak( "%s", "Qt::AbstractItemModel::insertRows called on a non-Qt4"
            " object");
    if(isDerivedFrom(o, "QAbstractItemModel") == -1)
        croak( "%s", "Qt::AbstractItemModel::insertRows called on a"
            " non-AbstractItemModel object");
	QAbstractItemModel * model = (QAbstractItemModel *) o->ptr;

	if (items == 3) {
        //bool insertRows( int row, int count )
		if (model->insertRows(SvIV(ST(1)), SvIV(ST(2)))) {
            XSRETURN_YES;
        }
        else {
            XSRETURN_NO;
        }
	}
	else if (items == 4) {
        //bool insertRows( int row, int count, const QModelIndex & parent = QModelIndex() )
    	smokeperl_object * mi = sv_obj_info(ST(3));
        if(!mi)
            croak( "%s", "1st argument to Qt::AbstractItemModel::insertRows is"
                " not a Qt4 object");
        if(isDerivedFrom(mi, "QModelIndex") == -1)
            croak( "%s", "1st argument to Qt::AbstractItemModel::insertRows is"
                " not a Qt::ModelIndex" );
		const QModelIndex * modelIndex = (const QModelIndex *) mi->ptr;

		if (model->insertRows(SvIV(ST(1)), SvIV(ST(2)), *modelIndex)) {
            XSRETURN_YES;
        }
        else {
            XSRETURN_NO;
        }
	}

	croak("%s", "Invalid argument list to Qt::AbstractItemModel::insertRows");
}

XS(XS_qabstract_item_model_insertcolumns) {
    dXSARGS;
    smokeperl_object *o = sv_obj_info(ST(0));
    if(!o)
        croak( "%s", "Qt::AbstractItemModel::insertColumns called on a non-Qt4"
            " object");
    if(isDerivedFrom(o, "QAbstractItemModel") == -1)
        croak( "%s", "Qt::AbstractItemModel::insertColumns called on a"
            " non-AbstractItemModel object");
	QAbstractItemModel * model = (QAbstractItemModel *) o->ptr;

	if (items == 3) {
        //bool insertColumns( int column, int count )
		if (model->insertColumns(SvIV(ST(1)), SvIV(ST(2)))) {
            XSRETURN_YES;
        }
        else {
            XSRETURN_NO;
        }
	}
	else if (items == 4) {
        //bool insertColumns( int column, int count, const QModelIndex & parent = QModelIndex() )
    	smokeperl_object * mi = sv_obj_info(ST(3));
        if(!mi)
            croak( "%s", "1st argument to Qt::AbstractItemModel::insertColumns is"
                " not a Qt4 object");
        if(isDerivedFrom(mi, "QModelIndex") == -1)
            croak( "%s", "1st argument to Qt::AbstractItemModel::insertColumns is"
                " not a Qt::ModelIndex" );
		const QModelIndex * modelIndex = (const QModelIndex *) mi->ptr;
		if (model->insertColumns(SvIV(ST(1)), SvIV(ST(2)), *modelIndex)) {
            XSRETURN_YES;
        }
        else {
            XSRETURN_NO;
        }
	}

	croak("%s", "Invalid argument list to Qt::AbstractItemModel::insertColumns");
}

XS(XS_qabstract_item_model_removerows) {
    dXSARGS;
    smokeperl_object *o = sv_obj_info(ST(0));
    if(!o)
        croak( "%s", "Qt::AbstractItemModel::removeRows called on a non-Qt4"
            " object");
    if(isDerivedFrom(o, "QAbstractItemModel") == -1)
        croak( "%s", "Qt::AbstractItemModel::removeRows called on a"
            " non-AbstractItemModel object");
	QAbstractItemModel * model = (QAbstractItemModel *) o->ptr;

	if (items == 3) {
        //bool removeRows( int row, int count )
		if (model->removeRows(SvIV(ST(1)), SvIV(ST(2)))) {
            XSRETURN_YES;
        }
        else {
            XSRETURN_NO;
        }
	}
	else if (items == 4) {
        //bool removeRows( int row, int count, const QModelIndex & parent = QModelIndex() )
    	smokeperl_object * mi = sv_obj_info(ST(3));
        if(!mi)
            croak( "%s", "1st argument to Qt::AbstractItemModel::removeRows is"
                " not a Qt4 object");
        if(isDerivedFrom(mi, "QModelIndex") == -1)
            croak( "%s", "1st argument to Qt::AbstractItemModel::removeRows is"
                " not a Qt::ModelIndex" );
		const QModelIndex * modelIndex = (const QModelIndex *) mi->ptr;
		if (model->removeRows(SvIV(ST(1)), SvIV(ST(2)), *modelIndex)) {
            XSRETURN_YES;
        }
        else {
            XSRETURN_NO;
        }
	}

	croak("%s", "Invalid argument list to Qt::AbstractItemModel::removeRows");
}

XS(XS_qabstract_item_model_removecolumns) {
    dXSARGS;
    smokeperl_object *o = sv_obj_info(ST(0));
    if(!o)
        croak( "%s", "Qt::AbstractItemModel::removeColumns called on a non-Qt4"
            " object");
    if(isDerivedFrom(o, "QAbstractItemModel") == -1)
        croak( "%s", "Qt::AbstractItemModel::removeColumns called on a"
            " non-AbstractItemModel object");
	QAbstractItemModel * model = (QAbstractItemModel *) o->ptr;

	if (items == 3) {
        //bool removeColumns( int column, int count )
		if (model->removeColumns(SvIV(ST(1)), SvIV(ST(2)))) {
            XSRETURN_YES;
        }
        else {
            XSRETURN_NO;
        }
	}
	else if (items == 4) {
        //bool removeColumns( int column, int count, const QModelIndex & parent = QModelIndex() )
    	smokeperl_object * mi = sv_obj_info(ST(3));
        if(!mi)
            croak( "%s", "1st argument to Qt::AbstractItemModel::removeColumns is"
                " not a Qt4 object");
        if(isDerivedFrom(mi, "QModelIndex") == -1)
            croak( "%s", "1st argument to Qt::AbstractItemModel::removeColumns is"
                " not a Qt::ModelIndex" );
		const QModelIndex * modelIndex = (const QModelIndex *) mi->ptr;
		if (model->removeColumns(SvIV(ST(1)), SvIV(ST(2)), *modelIndex)) {
            XSRETURN_YES;
        }
        else {
            XSRETURN_NO;
        }
	}

	croak("%s", "Invalid argument list to Qt::AbstractItemModel::removeColumns");
}

XS(XS_qabstractitemmodel_createindex) {
    dXSARGS;
    if (items == 2 || items == 3) {
        smokeperl_object* o = sv_obj_info(sv_this);
        if (!o)
            croak( "%s", "Qt::AbstractItemModel::createIndex must be called as a method on a Qt::AbstractItemModel object, eg. $model->createIndex" );
        Smoke::ModuleIndex nameId = qtcore_Smoke->idMethodName("createIndex$$$");
        Smoke::ModuleIndex meth = qtcore_Smoke->findMethod(qtcore_Smoke->findClass("QAbstractItemModel"), nameId);
        Smoke::Index i = meth.smoke->methodMaps[meth.index].method;
        i = -i;		// turn into ambiguousMethodList index
        while (meth.smoke->ambiguousMethodList[i] != 0) {
            if ( qstrcmp( meth.smoke->types[meth.smoke->argumentList[meth.smoke->methods[meth.smoke->ambiguousMethodList[i]].args + 2]].name,
                        "void*" ) == 0 )
            {
                Smoke::Method &m = meth.smoke->methods[meth.smoke->ambiguousMethodList[i]];
                Smoke::ClassFn fn = meth.smoke->classes[m.classId].classFn;
                Smoke::StackItem stack[4];
                stack[1].s_int = SvIV(ST(0));
                stack[2].s_int = SvIV(ST(1));
                if (items == 2) {
                    stack[3].s_voidp = (void*) &PL_sv_undef;
                } else {
                    // In order for two model indexes to be considered
                    // identical, they must have the same row, column, parent,
                    // and internal pointer/id.  Because of that last
                    // requirement, we can't store the RV as the internal
                    // pointer, we must dereference it.  Then, in calls to
                    // internalPointer(), we make a new reference, and return
                    // that.  So to the user it is transparent.
                    if ( !SvROK( ST(2) ) ) {
                        croak( "%s", "Must provide a reference as 3rd argument "
                            "to Qt::AbstractItemModel::createIndex" );
                    }
                    SV* refval = SvRV( ST(2) );

                    //TODO: figure out a way to decrement the refcount when the
                    //modelindex is deleted
                    SvREFCNT_inc(refval);
                    stack[3].s_voidp = (void*)refval;
                }
                (*fn)(m.method, o->ptr, stack);
                smokeperl_object* result = alloc_smokeperl_object(
                    true, 
                    qtcore_Smoke,
                    qtcore_Smoke->idClass("QModelIndex").index, 
                    stack[0].s_voidp
                );

                ST(0) = set_obj_info(" Qt::ModelIndex", result);
                XSRETURN(1);
            }

            ++i;
        }
    }

    //return rb_call_super(argc, argv);
}

XS(XS_qmodelindex_internalpointer) {
    dXSARGS;
    smokeperl_object *o = sv_obj_info(ST(0));
	QModelIndex * index = (QModelIndex *) o->ptr;
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

XS(XS_qbytearray_data) {
    dXSARGS;
    if (items != 1) {
        croak( "%s", "Invalid argument list to Qt::ByteArray::data()" );
    }

    smokeperl_object *o = sv_obj_info(ST(0));

    if (!o) {
        croak( "Qt::ByteArray::data() called on a non-Qt object" );
    }
    if(isDerivedFrom(o, "QByteArray") == -1) {
        croak( "%s", "Qt::ByteArray::data called on a"
            " non-ByteArray object");
    }

    QByteArray * bytes = (QByteArray *) o->ptr;
    ST(0) = sv_2mortal( perlstringFromQByteArray(bytes) );

    XSRETURN(1);
}

#if defined(Q_OS_WIN32)
// screw you PerlLIO_read, PerlProc_signal
#undef read
#undef signal
#endif

XS(XS_qiodevice_read) {
    dXSARGS;
    if (items < 2 || items > 3) {
        croak( "%s", "Invalid argument list to Qt::IODevice::read()" );
    }

    smokeperl_object *o = sv_obj_info(ST(0));

    if (!o) {
        croak( "Qt::IODevice::read() called on a non-Qt object" );
    }
    if(isDerivedFrom(o, "QIODevice") == -1) {
        croak( "%s", "Qt::IODevice::read() called on a"
            " non-IODevice object");
    }

    QIODevice * device = (QIODevice *) o->smoke->cast(
        o->ptr,
        o->classId,
        o->smoke->idClass("QIODevice").index
    );

    if (items == 2) {
        qint64 maxSize = SvIV( ST(1) );
        QByteArray bytearray = device->read( maxSize );
        // bytearray is stack allocated, so we have to copy
        QByteArray * copy = new QByteArray( bytearray );
        smokeperl_object* o = alloc_smokeperl_object(
            true,
            qtcore_Smoke,
            qtcore_Smoke->idClass("QByteArray").index,
            (void*)copy
        );
        ST(0) = sv_2mortal( set_obj_info( " Qt::ByteArray", o) );
        XSRETURN(1);

    }
    else {
        if ( !SvROK(ST(1)) ) {
            croak( "%s", "Error: First argument to Qt::IODevice::read(char*, qint64) should be a scalar reference" );
        }
        qint64 maxSize = SvIV( ST(2) );
        char* data = new char[maxSize];
        qint64 bytesRead = device->read( data, maxSize );

        STRLEN len = bytesRead;
        sv_setsv( SvRV(ST(1)), newSVpvn( data, len ) );
        delete[] data;
        ST(0) = sv_2mortal( newSViv( bytesRead ) );
        XSRETURN(1);
    }
}

XS(XS_qdatastream_readrawdata) {
    dXSARGS;
    if (items != 3) {
        croak( "%s", "Invalid argument list to Qt::DataStream::readRawData()" );
    }

    smokeperl_object *o = sv_obj_info(ST(0));

    if (!o) {
        croak( "Qt::DataStream::read() called on a non-Qt object" );
    }
    if(isDerivedFrom(o, "QDataStream") == -1) {
        croak( "%s", "Qt::DataStream::read() called on a"
            " non-DataStream object");
    }

    QDataStream * stream = (QDataStream *) o->smoke->cast(
        o->ptr,
        o->classId,
        o->smoke->idClass("QDataStream").index
    );

    if ( !SvROK(ST(1)) ) {
        croak( "%s", "Error: First argument to Qt::DataStream::readRawData(char*, uint) should be a scalar reference" );
    }
    uint maxSize = SvIV( ST(2) );
    char* data = new char[maxSize];
    int bytesRead = stream->readRawData( data, maxSize );

    sv_setsv( SvRV(ST(1)), newSVpvn( data, bytesRead ) );

    // Return the QDataStream that's already at ST(0)
    delete[] data;
    ST(0) = sv_2mortal( newSViv( bytesRead ) );
    XSRETURN(1);
}

// TODO: Find a better place to put these.
Q_DECLARE_METATYPE(HV*)
Q_DECLARE_METATYPE(AV*)

XS(XS_qvariant_value) {
    dXSARGS;
	void * sv_ptr = 0;
	SV *retval = &PL_sv_undef;

    if ( items < 1 ) {
        croak( "%s", "Usage: Qt::qVariantValue( Qt::Variant, $typeName )" );
    }

    smokeperl_object *o = sv_obj_info(ST(0));
	if (o == 0 || o->ptr == 0) {
		ST(0) = retval;
        XSRETURN(1);
	}

	QVariant * variant = (QVariant*) o->ptr;

    // If the QVariant contains a user type, don't bother to look at the Perl
    // class argument
    if (variant->type() >= QVariant::UserType) {
#ifdef QT_QTDBUS 
        if (qstrcmp(variant->typeName(), "QDBusObjectPath") == 0) {
            QString s = qVariantValue<QDBusObjectPath>(*variant).path();
            ST(0) = sv_2mortal( newSVpv( s.toLatin1(), s.size() ) );
            XSRETURN(1);
        }
        else if (qstrcmp(variant->typeName(), "QDBusSignature") == 0) {
            QString s = qVariantValue<QDBusSignature>(*variant).signature();
            ST(0) = sv_2mortal( newSVpv( s.toLatin1(), s.size() ) );
            XSRETURN(1);
        }
#endif
        if(qstrcmp(variant->typeName(), "AV*") == 0) {
            ST(0) = sv_2mortal( newRV( (SV*)qVariantValue<AV*>(*variant) ) );
            XSRETURN(1);
        }
        else if(qstrcmp(variant->typeName(), "HV*") == 0) {
            ST(0) = sv_2mortal( newRV( (SV*)qVariantValue<HV*>(*variant) ) );
            XSRETURN(1);
        }
        else if (strcmp(variant->typeName(), "QDBusVariant") == 0) {
            void *value_ptr = QMetaType::construct(QMetaType::type(variant->typeName()), (void *) variant->constData());
            Smoke::ModuleIndex mi = o->smoke->findClass("QVariant");

            smokeperl_object* obj = alloc_smokeperl_object(
                true,
                mi.smoke,
                mi.index,
                value_ptr );

            SV* retval = set_obj_info( perlqt_modules[mi.smoke].binding->className(mi.index), obj );
            ST(0) = sv_2mortal(retval);
            XSRETURN(1);
        }

        void *value_ptr = QMetaType::construct(QMetaType::type(variant->typeName()), (void *) variant->constData());
        Smoke::ModuleIndex mi = o->smoke->findClass(variant->typeName());

        smokeperl_object* obj = alloc_smokeperl_object(
            true,
            mi.smoke,
            mi.index,
            value_ptr );

        SV* retval = set_obj_info( perlqt_modules[mi.smoke].binding->className(mi.index), obj );
        ST(0) = sv_2mortal(retval);
        XSRETURN(1);
    }

    if ( items != 2 ) {
        croak( "%s", "Usage: Qt::qVariantValue( Qt::Variant, $typeName )" );
    }
	const char * classname = SvPV_nolen(ST(1));
    Smoke::ModuleIndex * sv_class_id = new Smoke::ModuleIndex;
    SV* moduleIdRef = package_classId(classname);
    sv_class_id->smoke = smokeList[SvIV(*(SV**)av_fetch((AV*)SvRV(moduleIdRef), 0, 0))];
    sv_class_id->index = SvIV(*(SV**)av_fetch((AV*)SvRV(moduleIdRef), 1, 0));

	if (sv_class_id->index == 0) {
		ST(0) = retval;
        XSRETURN(1);
	}

	if (qstrcmp(classname, "Qt::Pixmap") == 0) {
		QPixmap v = qVariantValue<QPixmap>(*variant);
		sv_ptr = (void *) new QPixmap(v);
	} else if (qstrcmp(classname, "Qt::Font") == 0) {
		QFont v = qVariantValue<QFont>(*variant);
		sv_ptr = (void *) new QFont(v);
	} else if (qstrcmp(classname, "Qt::Brush") == 0) {
		QBrush v = qVariantValue<QBrush>(*variant);
		sv_ptr = (void *) new QBrush(v);
	} else if (qstrcmp(classname, "Qt::Color") == 0) {
		QColor v = qVariantValue<QColor>(*variant);
		sv_ptr = (void *) new QColor(v);
	} else if (qstrcmp(classname, "Qt::Palette") == 0) {
		QPalette v = qVariantValue<QPalette>(*variant);
		sv_ptr = (void *) new QPalette(v);
	} else if (qstrcmp(classname, "Qt::Icon") == 0) {
		QIcon v = qVariantValue<QIcon>(*variant);
		sv_ptr = (void *) new QIcon(v);
	} else if (qstrcmp(classname, "Qt::Image") == 0) {
		QImage v = qVariantValue<QImage>(*variant);
		sv_ptr = (void *) new QImage(v);
	} else if (qstrcmp(classname, "Qt::Polygon") == 0) {
		QPolygon v = qVariantValue<QPolygon>(*variant);
		sv_ptr = (void *) new QPolygon(v);
	} else if (qstrcmp(classname, "Qt::Region") == 0) {
		QRegion v = qVariantValue<QRegion>(*variant);
		sv_ptr = (void *) new QRegion(v);
	} else if (qstrcmp(classname, "Qt::Bitmap") == 0) {
		QBitmap v = qVariantValue<QBitmap>(*variant);
		sv_ptr = (void *) new QBitmap(v);
	} else if (qstrcmp(classname, "Qt::Cursor") == 0) {
		QCursor v = qVariantValue<QCursor>(*variant);
		sv_ptr = (void *) new QCursor(v);
	} else if (qstrcmp(classname, "Qt::SizePolicy") == 0) {
		QSizePolicy v = qVariantValue<QSizePolicy>(*variant);
		sv_ptr = (void *) new QSizePolicy(v);
	} else if (qstrcmp(classname, "Qt::KeySequence") == 0) {
		QKeySequence v = qVariantValue<QKeySequence>(*variant);
		sv_ptr = (void *) new QKeySequence(v);
	} else if (qstrcmp(classname, "Qt::Pen") == 0) {
		QPen v = qVariantValue<QPen>(*variant);
		sv_ptr = (void *) new QPen(v);
	} else if (qstrcmp(classname, "Qt::TextLength") == 0) {
		QTextLength v = qVariantValue<QTextLength>(*variant);
		sv_ptr = (void *) new QTextLength(v);
	} else if (qstrcmp(classname, "Qt::TextFormat") == 0) {
		QTextFormat v = qVariantValue<QTextFormat>(*variant);
		sv_ptr = (void *) new QTextFormat(v);
	} else if (qstrcmp(classname, "Qt::Variant") == 0) {
		sv_ptr = (void *) new QVariant(*((QVariant *) variant->constData()));
	} else {
		// Assume the value of the Qt::Variant can be obtained
		// with a call such as Qt::Variant.toPoint()
        /*
		QByteArray toValueMethodName(classname);
		if (toValueMethodName.startsWith("Qt::")) {
			toValueMethodName.remove(0, strlen("Qt::"));
		}
		toValueMethodName.prepend("to");
		return rb_funcall(variant_value, rb_intern(toValueMethodName), 1, variant_value);
        */
	}

    smokeperl_object* reto = alloc_smokeperl_object(
        true, sv_class_id->smoke, sv_class_id->index, sv_ptr);
    const char* retclassname = perlqt_modules[reto->smoke].resolve_classname(reto);
    retval = set_obj_info( retclassname, reto );

    delete sv_class_id;

	//ST(0) = sv_2mortal(retval);
	ST(0) = retval;
    XSRETURN(1);
}

XS(XS_qvariant_from_value) {
    dXSARGS;
    if (0 > items && items < 2) {
        croak( "%s, %d %s", "qVariantFromValue requires 1 or 2 arguments", items, "were supplied" );
        XSRETURN_UNDEF;
    }

    if (items == 2) {
        Smoke::ModuleIndex nameId = qtcore_Smoke->NullModuleIndex;
        smokeperl_object *o = sv_obj_info(ST(0));
        if (o) {
            nameId = qtcore_Smoke->idMethodName("QVariant#");
        } else if (SvTYPE(ST(0)) == SVt_PVAV) {
            nameId = qtcore_Smoke->idMethodName("QVariant?");
        } else {
            nameId = qtcore_Smoke->idMethodName("QVariant$");
        }

        Smoke::ModuleIndex meth = qtcore_Smoke->findMethod(qtcore_Smoke->idClass("QVariant"), nameId);
        Smoke::Index i = meth.smoke->methodMaps[meth.index].method;
        i = -i;		// turn into ambiguousMethodList index
        while (meth.smoke->ambiguousMethodList[i] != 0) {
            if ( qstrcmp( meth.smoke->types[meth.smoke->argumentList[meth.smoke->methods[meth.smoke->ambiguousMethodList[i]].args]].name,
                        HvNAME(ST(1)) ) == 0 )
            {
                Smoke::Index methodId = meth.smoke->ambiguousMethodList[i];
                PerlQt4::MethodCall c(qtcore_Smoke, methodId, o, SP, 0);
                c.next();
                ST(0) = sv_2mortal(c.var());
                XSRETURN(1);
            }

            ++i;
        }
    }

    QVariant * v = 0;
    const char * classname = 0;
    smokeperl_object *o = 0;
    if( SvROK(ST(0)) ) {
        o = sv_obj_info(ST(0));
        if(o)
            classname = HvNAME(SvSTASH(SvRV(ST(0))));
    }

    if(o) {
        if (qstrcmp(classname, " Qt::Pixmap") == 0) {
            v = new QVariant(qVariantFromValue(*(QPixmap*) o->ptr));
        } else if (qstrcmp(classname, " Qt::Font") == 0) {
            v = new QVariant(qVariantFromValue(*(QFont*) o->ptr));
        } else if (qstrcmp(classname, " Qt::Brush") == 0) {
            v = new QVariant(qVariantFromValue(*(QBrush*) o->ptr));
        } else if (qstrcmp(classname, " Qt::Color") == 0) {
            v = new QVariant(qVariantFromValue(*(QColor*) o->ptr));
        } else if (qstrcmp(classname, " Qt::Palette") == 0) {
            v = new QVariant(qVariantFromValue(*(QPalette*) o->ptr));
        } else if (qstrcmp(classname, " Qt::Icon") == 0) {
            v = new QVariant(qVariantFromValue(*(QIcon*) o->ptr));
        } else if (qstrcmp(classname, " Qt::Image") == 0) {
            v = new QVariant(qVariantFromValue(*(QImage*) o->ptr));
        } else if (qstrcmp(classname, " Qt::Polygon") == 0) {
            v = new QVariant(qVariantFromValue(*(QPolygon*) o->ptr));
        } else if (qstrcmp(classname, " Qt::Region") == 0) {
            v = new QVariant(qVariantFromValue(*(QRegion*) o->ptr));
        } else if (qstrcmp(classname, " Qt::Bitmap") == 0) {
            v = new QVariant(qVariantFromValue(*(QBitmap*) o->ptr));
        } else if (qstrcmp(classname, " Qt::Cursor") == 0) {
            v = new QVariant(qVariantFromValue(*(QCursor*) o->ptr));
        } else if (qstrcmp(classname, " Qt::SizePolicy") == 0) {
            v = new QVariant(qVariantFromValue(*(QSizePolicy*) o->ptr));
        } else if (qstrcmp(classname, " Qt::KeySequence") == 0) {
            v = new QVariant(qVariantFromValue(*(QKeySequence*) o->ptr));
        } else if (qstrcmp(classname, " Qt::Pen") == 0) {
            v = new QVariant(qVariantFromValue(*(QPen*) o->ptr));
        } else if (qstrcmp(classname, " Qt::TextLength") == 0) {
            v = new QVariant(qVariantFromValue(*(QTextLength*) o->ptr));
        } else if (qstrcmp(classname, " Qt::TextFormat") == 0) {
            v = new QVariant(qVariantFromValue(*(QTextFormat*) o->ptr));
        } else if (QVariant::nameToType(o->smoke->classes[o->classId].className) >= QVariant::UserType) {
            v = new QVariant(QMetaType::type(o->smoke->classes[o->classId].className), o->ptr);
        } else {
            // Assume the Qt::Variant can be created with a
            // Qt::Variant.new(obj) call
            fprintf( stderr, "Cannot handle type %s in qVariantToValue", classname );
            XSRETURN_UNDEF;
            //return rb_funcall(qvariant_class, rb_intern("new"), 1, ST(0));
        }
    }
    else {
        SV* perlvar = ST(0);
        if (SvROK(perlvar)) {
            switch ( SvTYPE(SvRV(perlvar))) {
                case SVt_PVAV:
                    SvREFCNT_inc(perlvar);
                    v = new QVariant(qVariantFromValue((AV*)SvRV(perlvar)));
                    break;
                break;
                case SVt_PVHV:
                    SvREFCNT_inc(perlvar);
                    v = new QVariant(qVariantFromValue((HV*)SvRV(perlvar)));
                    break;
                break;
                default:
                    croak( "%s", "Can only handle hash and array references in"
                        " call to Qt::Variant constructor" );
            };
        }
        else
            croak( "%s", "Can only handle hash and array references in call to"
                " Qt::Variant constructor" );
    }


    smokeperl_object* reto = alloc_smokeperl_object(
        true, qtcore_Smoke, qtcore_Smoke->idClass("QVariant").index, v);
    const char* retclassname = perlqt_modules[reto->smoke].resolve_classname(reto);
    SV* retval = set_obj_info( retclassname, reto );

    ST(0) = retval;
    XSRETURN(1);
}

XS(XS_AUTOLOAD) {
    dXSARGS;
    PERL_SET_CONTEXT(PL_curinterp);
    // Figure out which package and method is being called, based on the
    // autoload variable
    SV* autoload = get_sv( "Qt::AutoLoad::AUTOLOAD", TRUE );
    char* package = SvPV_nolen( autoload );
    char* methodname = 0;
    // Splits off the method name from the package
    for( char* s = package; *s; s++ ) {
        if( *s == ':') methodname = s;
    }
    // No method to call was passed, so error out
    if( !methodname ) XSRETURN_NO;
    // Erases the first character off the method, killing the ':', and truncate
    // the value of method off package.
    *( methodname++ - 1 ) = 0;

    // We need to do the same thing again, to look for SUPER
    char* super = 0;
    for( char* s = package; *s; s++ ) {
        if( *s == ':') super = s;
    }
    if ( super )
        super++;

    int withObject = ( *package == ' ' ) ? 1 : 0;
    if( withObject ) {
        ++package;
    }
    if ( super ) {
        // We'll only ever get here if we're called on an object.  If we have
        // $class = 'foo'; $class->SUPER::NEW(), we won't get here.  But if we
        // have this->SUPER::someMethod(), we will.
        withObject |= strcmp( super, "SUPER" ) == 0;
    }

#ifdef PERLQTDEBUG
    if( do_debug && ( do_debug & qtdb_autoload ) ) {
        fprintf(stderr, "In XS Autoload for %s::%s()", package, methodname);
        if((do_debug & qtdb_verbose) && withObject) {
            smokeperl_object *o = sv_obj_info(withObject ? ST(0) : sv_this);
            if(o)
                fprintf(stderr, " - SV*: %p this: (%s)%p\n", withObject ? ST(0) : sv_this, o->smoke->classes[o->classId].className, o->ptr);
            else
                fprintf(stderr, " - this: (unknown)(nil)\n");
        }
        else {
            fprintf(stderr, "\n");
        }
    }
#endif

    // For anything we do here where withObject is true, sv_this should be set
    // to the first argument on the stack, since that's where perl puts it.
    // Wherever we return, be sure to restore sv_this.
    SV* old_this = 0;
    if( withObject ) {
        old_this = sv_this;
        sv_this = newSVsv(ST(0));
    }
        
    // See if we need to call a perl method
    HV* stash = gv_stashpv( package, TRUE );
    GV* gv = gv_fetchmethod_autoload( stash, methodname, 0 );

    if(gv) {
        // Found a perl method
#ifdef PERLQTDEBUG
        if(do_debug && (do_debug & qtdb_autoload))
            fprintf(stderr, "\t%s::%s found in Perl stash\n", package, methodname);
#endif            

        // Call the found method
        sv_setsv( ERRSV, &PL_sv_undef );
        ENTER;
        SAVETMPS;
        PUSHMARK(SP - items + withObject);
        // What context are we calling this subroutine in?
        I32 gimme = GIMME_V;
        // Make the call, save number of returned values
        int count = call_sv((SV*)GvCV(gv), gimme);
        // Get the return value
        SPAGAIN;
        SP -= count;
        if (withObject)
            for (int i=0; i<count; i++)
                ST(i) = ST(i+1);
        PUTBACK;
        LEAVE;

        // Clean up
        if(withObject){
            SvREFCNT_dec(sv_this);
            sv_this = old_this;
        }

        // Error out if necessary
        if(SvTRUE(ERRSV))
            croak("%s", SvPV_nolen(ERRSV));

        if (gimme == G_VOID)
            XSRETURN_UNDEF;
        else
            XSRETURN(count);
    }
    else if( !strcmp( methodname, "DESTROY" ) ) {
        smokeperl_object* o = sv_obj_info(sv_this);

        // Check to see that o exists (has a smokeperl_object in sv_this), has
        // a valid pointer, and (is allocated or has an entry in the pointer
        // map).  If all of that's true, or we're in global destruction, we
        // don't really care what happens.
        if( PL_dirty ) {
            // This block will be repeated a lot to clean stuff up.
            if( withObject ) {
                // Restore sv_this
                SvREFCNT_dec(sv_this);
                sv_this = old_this;
            }
            XSRETURN_YES;
        }
        if( !(o && o->ptr && (o->allocated || getPointerObject(o->ptr))) ) {
            // This block will be repeated a lot to clean stuff up.
            if( withObject ) {
                // Restore sv_this
                SvREFCNT_dec(sv_this);
                sv_this = old_this;
            }
            XSRETURN_YES;
        }

        // Check to see if a delete of this object has been tried before, by
        // seeing if the object's hash has the "has been hidden" key
        static const char* key = "has been hidden";
        U32 klen = 15;
        SV** svp = 0;
        if( SvROK(sv_this) && SvTYPE(SvRV(sv_this)) == SVt_PVHV ) {
            HV* hv = (HV*)SvRV(sv_this);
            svp = hv_fetch( hv, key, klen, 0);
        }
        if(svp) {
            // Found "has been hidden", so don't do anything, just clean up 
            if( withObject ) {
                // Restore sv_this
                SvREFCNT_dec(sv_this);
                sv_this = old_this;
            }
            XSRETURN_YES;
        }

#ifdef PERLQTDEBUG
        // The following perl call seems to stomp on the package name, let's copy it
        char* packagecpy = new char[strlen(package)+1];
        strcpy( packagecpy, package );
#endif

        // Call the ON_DESTROY method, that stores a reference (increasing the
        // refcnt) if necessary
        if( !stash )
            stash = gv_stashpv(package, TRUE);
        gv = gv_fetchmethod_autoload(stash, "ON_DESTROY", 0);
        int retval = 0;
        if( gv ) {
            PUSHMARK(SP);
            int count = call_sv((SV*)GvCV(gv), G_SCALAR|G_NOARGS);
            SPAGAIN;
            if (count != 1) {
                if( withObject ) {
                    // Restore sv_this
                    SvREFCNT_dec(sv_this);
                    sv_this = old_this;
                }
                croak( "Corrupt ON_DESTROY return value: Got %d value(s), expected 1\n", count );
            }
            retval = POPi;
            PUTBACK;
        }

#ifdef PERLQTDEBUG
        if( do_debug && retval && (do_debug & qtdb_gc) )
            fprintf(stderr, "Increasing refcount in DESTROY for %s=%p (still has a parent)\n", packagecpy, o->ptr);
        delete[] packagecpy;
#endif

        // Now clean up
        if( withObject ) {
            SvREFCNT_dec(sv_this);
            sv_this = old_this;
        }
    }
    else {
        // We're calling a c++ method

        // Get the classId (eventually converting SUPER to the right Qt4 class)
        SV* moduleIdRef = package_classId( package );
        Smoke::ModuleIndex mi;

        // This complicated mess is just $moduleIdRef->[0], $moduleIdRef->[1];
        mi.smoke = smokeList[SvIV(*(SV**)av_fetch((AV*)SvRV(moduleIdRef), 0, 0))];
        mi.index = SvIV(*(SV**)av_fetch((AV*)SvRV(moduleIdRef), 1, 0));
        char* classname = (char*) mi.smoke->className( mi.index );
        // We may call a perl sub to find the retModuleId.  This will overwrite
        // the current SP pointer, so save a copy
        SV** savestack = new SV*[items+1];

        // The deal with SP - items + 1: SP is a stack.  Arguments get pushed
        // onto the stack.  Therefore, the position of the stack pointer when
        // our sub gets it is set to the last argument on the stack.  To get
        // the position of the first argument, you subtract the # of arguments,
        // aka items.  +1 because it's an array.
        Copy( SP - items + 1 + withObject, savestack, items + withObject, SV* );

        // Look in the cache; if this method was called before with the same
        // arguments, we already know the retModuleId
        // The key to the methodcache looks like this:
        // class      method     arg types
        // QPopupMenu;insertItem;s;QApplication;s
        int lclassname = strlen(classname);
        int lmethodname = strlen(methodname);
        char mcid[256];
        strncpy(mcid, classname, lclassname);
        char *ptr = mcid + lclassname;
        *(ptr++) = ';'; //Set the current position to ; then increment
        strncpy(ptr, methodname, lmethodname);
        ptr += lmethodname;

        // that gives us the first 2 parts of the methcache key, now for the
        // args
        for(int i = withObject; i < items; i++) {
            *(ptr++) = ';';
            const char *type = get_SVt(ST(i));
            int typelen = strlen(type);
            strncpy( ptr, type, typelen );
            ptr += typelen;
        }
        *ptr = 0; // Don't forget to null-terminate the string

        // See if it's cached
        Smoke::ModuleIndex* rcid = methcache.value(mcid);
        if(rcid) {
            // Got a hit
            mi = *rcid;
        }
        else {
            // Call getSmokeMethodId to get the retModuleId
            sv_setsv( ERRSV, &PL_sv_undef );
            ENTER;
            SAVETMPS;
            PUSHMARK( SP - items + withObject );
            EXTEND( SP, 3 );
            PUSHs(sv_2mortal(alloc_perl_moduleindex(smokeList.indexOf(mi.smoke), mi.index)));
            PUSHs(sv_2mortal(newSVpv(methodname, 0)));
            PUSHs(sv_2mortal(newSVpv(classname, 0)));
            PUTBACK;
            int count = call_pv( "Qt::_internal::getSmokeMethodId", G_ARRAY|G_EVAL );
            SPAGAIN;
            // See if getSmokeMethodId die'd
            if (SvTRUE(ERRSV)) {
                if( withObject ) {
                    SvREFCNT_dec(sv_this);
                    sv_this = old_this;
                }
                delete[] savestack;
                croak("%s", SvPV_nolen(ERRSV));
            }

            if (count != 3) {
                // Error, clean up our crap
                if( withObject ) {
                    SvREFCNT_dec(sv_this);
                    sv_this = old_this;
                }

                // Error out
                croak( "Corrupt getSmokeMethodId return value: Got %d value(s), expected 3\n", count );
            }

            int cacheLookup = POPi;
            Smoke::Index retMethodId = POPi;
            Smoke::Index retSmokeId = POPi;
            PUTBACK;
            FREETMPS;
            LEAVE;

            // Save our lookup
            mi.smoke = smokeList[retSmokeId];
            mi.index = retMethodId;
            if ( cacheLookup ) 
                methcache.insert(mcid, new Smoke::ModuleIndex(mi));
        }

        static smokeperl_object nothis = { 0, 0, 0, false };
        smokeperl_object* call_this = 0;
        if ( SvOK(sv_this) ) {
            call_this = sv_obj_info( sv_this );
            if ( !call_this )
                call_this = &nothis;
        }
        else {
            call_this = &nothis;
        }

#ifdef PERLQTDEBUG
        if(do_debug && (do_debug & qtdb_calls)) {
            fprintf(stderr, "Calling method\t%s\t%s\n", methodname, SvPV_nolen(sv_2mortal(prettyPrintMethod(mi))));
            if(do_debug & qtdb_verbose) {
                fprintf(stderr, "with arguments (%s)\n", SvPV_nolen(sv_2mortal(catArguments(savestack, items - withObject))));
            }
        }
#endif

        PerlQt4::MethodCall call( mi.smoke,
                         mi.index,
                         call_this,
                         savestack,
                         items  - withObject );
        call.next();

        // The savestack will only be a copy created with new[] if we called a
        // perl method.  If we did, the savestack pointer will differ from the
        // SP pointer, because the perl method changed it.
        if( savestack )
            delete[] savestack;

        if( withObject ) {
            SvREFCNT_dec(sv_this);
            sv_this = old_this;
        }

        SV* retval = call.var();

        // Put the return value onto perl's stack
        ST(0) = sv_2mortal(retval);
        XSRETURN(1);
    }
}

XS(XS_qt_metacall){
    dXSARGS;
    PERL_UNUSED_VAR(items);
    PERL_SET_CONTEXT(PL_curinterp);

    // Get my arguments off the stack
    QObject* sv_this_ptr = (QObject*)sv_obj_info(sv_this)->ptr;
    // This is an enum value, so it's stored as a scalar reference.
    QMetaObject::Call _c = (QMetaObject::Call)SvIV(SvRV(ST(0)));
    int _id = (int)SvIV(ST(1));
    void** _a = (void**)sv_obj_info(ST(2))->ptr;

    // Assume the target slot is a C++ one
    smokeperl_object* o = sv_obj_info(sv_this);
    Smoke::ModuleIndex nameId = o->smoke->idMethodName("qt_metacall$$?");
    Smoke::ModuleIndex classIdx( o->smoke, o->classId );
    Smoke::ModuleIndex meth = nameId.smoke->findMethod(classIdx, nameId);
    if (meth.index > 0) {
        Smoke::Method &m = meth.smoke->methods[meth.smoke->methodMaps[meth.index].method];
        Smoke::ClassFn fn = meth.smoke->classes[m.classId].classFn;
        Smoke::StackItem i[4];
        i[1].s_enum = _c;
        i[2].s_int = _id;
        i[3].s_voidp = _a;
        (*fn)(m.method, o->ptr, i);
        int ret = i[0].s_int;
        if (ret < 0) {
            ST(0) = sv_2mortal(newSViv(ret));
            XSRETURN(1);
        }
    } else {
        // Should never happen..
        croak( "Cannot find %s::qt_metacall() method\n", 
               o->smoke->classes[o->classId].className );
    }

    // Get the current metaobject with a virtual call
    const QMetaObject* metaobject = sv_this_ptr->metaObject();

    // get method/property count
    int count = 0;
    if (_c == QMetaObject::InvokeMetaMethod) {
        count = metaobject->methodCount();
    } else {
        count = metaobject->propertyCount();
    }

    if (_c == QMetaObject::InvokeMetaMethod) {
        QMetaMethod method = metaobject->method(_id);

        // Signals are easy, just activate the meta object
        // This code gets called when a cxx signal is connected to a signal
        // defined in a perl package
        if (method.methodType() == QMetaMethod::Signal) {
#ifdef PERLQTDEBUG
            if(do_debug && (do_debug & qtdb_signals))
                fprintf( stderr, "In signal for %s::%s\n", metaobject->className(), method.signature() );
#endif
            metaobject->activate(sv_this_ptr, metaobject, 0, _a);
            // +1.  Id is 0 based, count is 1 based
            ST(0) = sv_2mortal(newSViv(_id - count + 1));
            XSRETURN(1);
        }
        else if (method.methodType() == QMetaMethod::Slot) {

            // Get the smoke to type id relationship args
            QList<MocArgument*> mocArgs = getMocArguments(o->smoke, method.typeName(), method.parameterTypes());

            // Find the name of the method being called
            QString name(method.signature());
            static QRegExp* rx = 0;
            if (rx == 0) {
                rx = new QRegExp("\\(.*");
            }
            name.replace(*rx, "");

            PerlQt4::InvokeSlot slot( sv_this, name.toLatin1().data(), mocArgs, _a );
            slot.next();
        }
    }

    // This should return -1 when we're the one that handled the call
    ST(0) = sv_2mortal(newSViv(_id - count));
    XSRETURN(1);
}

XS(XS_signal){
    dXSARGS;

    smokeperl_object *o = sv_obj_info(sv_this);
    QObject *qobj = (QObject*)o->smoke->cast( o->ptr, o->classId, o->smoke->idClass("QObject").index );
    if(qobj->signalsBlocked()) XSRETURN_UNDEF;

    // Each xs method has an implied cv argument that holds the info for the
    // called subroutine.  Use it to determine the name of the signal being
    // called.
    GV* gv = CvGV(cv);
    QLatin1String signalname( GvNAME(gv) );
#ifdef PERLQTDEBUG
    if(do_debug && (do_debug & qtdb_signals)){
        char* package = HvNAME( GvSTASH(gv) );
        fprintf( stderr, "In signal call %s::%s\n", package, GvNAME(gv) );
        if(do_debug & qtdb_verbose) {
            fprintf(stderr, "with arguments (%s) ", SvPV_nolen(sv_2mortal(catArguments(SP - items + 1, items ))));
            // See cop.h in the perl src for more info on Control ops
            fprintf(stderr, "called at line %lu in %s\n", CopLINE(PL_curcop), GvNAME(CopFILEGV(PL_curcop))+2 );
        }
    }
#endif

    // Get the current metaobject with a virtual call
    const QMetaObject* metaobject = qobj->metaObject();

    // Find the method's meta id.  This loop is easier than building the method
    // signature to send to indexOfMethod, but makes it impossible to make 2
    // signals with the same name but different signatures (arguments).
    int index = -1;
    QMetaMethod method;
    bool methodFound = false;
    for (index = metaobject->methodCount() - 1; index > -1; --index) {
		if (metaobject->method(index).methodType() == QMetaMethod::Signal) {
			QString name(metaobject->method(index).signature());
            static QRegExp * rx = 0;
			if (rx == 0) {
				rx = new QRegExp("\\(.*");
			}
			name.replace(*rx, "");

			if (name == signalname) {
                method = metaobject->method(index);
                methodFound = true;
                if ( method.parameterTypes().size() == items ) {
                    break;
                }
			}
		}
    }

	if (!methodFound) {
		XSRETURN_UNDEF;
	}
    // Have to check this twice to account for signal name overloading
    if ( method.parameterTypes().size() != items ) {
        // Incorrect arguments
        COP* callercop = caller(2);
        croak( "Wrong number of arguments in signal call %s::%s\n" 
            "Got     : %s(%s)\n"
            "Expected: %s\n"
            "called at %s line %lu\n",
            HvNAME( GvSTASH(gv) ),
            GvNAME(gv),
            GvNAME(gv),
            SvPV_nolen(sv_2mortal(catArguments(SP - items + 1, items ))),
            method.signature(),
            GvNAME(CopFILEGV(callercop))+2,
            CopLINE(callercop));
    }

    QList<MocArgument*> args = getMocArguments(o->smoke, method.typeName(), method.parameterTypes());

    SV* retval = sv_2mortal(newSV(0));

    // Our args here:
    // qobj: Whoever is emitting the signal, cast to a QObject*
    // index: The index of the current signal in QMetaObject's array of sig/slots
    // items: The number of arguments we are calling with
    // args: A QList, whose length is items + 1, that tell us how to convert the args to ones Qt4 likes
    // SP: ...not sure if this is correct.  If items=0, we'll pass sp+1, which
    // should be out of bounds.  But it doesn't matter, since the signal won't
    // do anything with those.
    // retval: Will (at some point, maybe) get populated with the return value from the signal.
    PerlQt4::EmitSignal signal(qobj, metaobject, index, items, args, SP - items + 1, retval);
    signal.next();

    // TODO: Handle signal return value
}

XS(XS_this) {
    dXSARGS;
    PERL_UNUSED_VAR(items);
    ST(0) = sv_this;
    XSRETURN(1);
}

