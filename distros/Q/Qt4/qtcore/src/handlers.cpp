/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

#include <QtCore/qdir.h>
#include <QtCore/qhash.h>
#include <QtCore/qlinkedlist.h>
#include <QtCore/qmetaobject.h>
#include <QtCore/qobject.h>
#include <QtCore/qpair.h>
#include <QtCore/qprocess.h>
#include <QtCore/qregexp.h>
#include <QtCore/qstring.h>
#include <QtCore/qtextcodec.h>
#include <QtCore/qurl.h>
#include <QtGui/qabstractbutton.h>
#include <QtGui/qaction.h>
#include <QtGui/qapplication.h>
#include <QtGui/qdockwidget.h>
#include <QtGui/qevent.h>
#include <QtGui/qlayout.h>
#include <QtGui/qlistwidget.h>
#include <QtGui/qpainter.h>
#include <QtGui/qpalette.h>
#include <QtGui/qpixmap.h>
#include <QtGui/qpolygon.h>
#include <QtGui/qtabbar.h>
#include <QtGui/qtablewidget.h>
#include <QtGui/qtextedit.h>
#include <QtGui/qtextlayout.h>
#include <QtGui/qtextobject.h>
#include <QtGui/qtoolbar.h>
#include <QtGui/qtreewidget.h>
#include <QtGui/qwidget.h>
#include <QtNetwork/qhostaddress.h>
#include <QtNetwork/qnetworkinterface.h>
#include <QtNetwork/qurlinfo.h>


#if QT_VERSION >= 0x40200
#include <QtGui/qgraphicsitem.h>
#include <QtGui/qgraphicsscene.h>
#include <QtGui/qstandarditemmodel.h>
#include <QtGui/qundostack.h>
#endif

#if QT_VERSION >= 0x40300
#include <QtGui/qmdisubwindow.h>
#include <QtNetwork/qsslcertificate.h>
#include <QtNetwork/qsslcipher.h>
#include <QtNetwork/qsslerror.h>
#include <QtXml/qxmlstream.h>
#include <QMultiMap>
#endif

#if QT_VERSION >= 0x040400
#include <QtGui/qprinterinfo.h>
#include <QtNetwork/qnetworkcookie.h>
#endif

//==============================================================================

#include "handlers.h"
#include "binding.h"
#include "QtCore4.h"
#include "marshall_basetypes.h"
#include "marshall_macros.h"
#include "smokeperl.h"
#include "smokehelp.h"
#include "util.h"

extern Q_DECL_EXPORT Smoke* qtcore_Smoke;

HV *type_handlers = 0;

struct mgvtbl vtbl_smoke = { 0, 0, 0, 0, smokeperl_free };

int smokeperl_free(pTHX_ SV* /*sv*/, MAGIC* mg) {
    smokeperl_object* o = (smokeperl_object*)mg->mg_ptr;
    if (o->allocated && o->ptr) {
        invoke_dtor( o );

        mg->mg_ptr = 0;
    }
    return 0;
}

void invoke_dtor(smokeperl_object* o) {
    Smoke::Index methodId = 0;
    if ( methodId ) { // Cache lookup
    }
    else {
        const char* className = o->smoke->classes[o->classId].className;
        char* methodName = new char[strlen(className) + 2];
        methodName[0] = '~';
        strcpy(methodName + 1, className);
        Smoke::Index method = o->smoke->findMethod( className, methodName ).index;
        if (method > 0) {
            Smoke::Method& m = o->smoke->methods[o->smoke->methodMaps[method].method];
            Smoke::ClassFn fn = o->smoke->classes[m.classId].classFn;
            Smoke::StackItem i[1];
#ifdef PERLQTDEBUG
            if( do_debug && (do_debug & qtdb_gc) )
                fprintf( stderr, "Deleting (%s*)%p\n", o->smoke->classes[o->classId].className, o->ptr );
#endif
            (*fn)(m.method, o->ptr, i);
        }
        delete [] methodName;
    }
}

bool matches_arg(Smoke *smoke, Smoke::Index meth, Smoke::Index argidx, const char *argtype) {
    Smoke::Index *arg = smoke->argumentList + smoke->methods[meth].args + argidx;
    SmokeType type = SmokeType(smoke, *arg);
    if(type.name() && !strcmp(type.name(), argtype))
	return true;
    return false;
}

void *construct_copy(smokeperl_object *o) {
    Smoke::Index *pccMeth = 0;//cctorcache->find(o->classId);
    Smoke::Index ccMeth = 0;
    if(!pccMeth) {
        const char *className = o->smoke->className(o->classId);
        int classNameLen = strlen(className);
        char *ccSig = new char[classNameLen + 2];       // copy constructor signature
        strcpy(ccSig, className);
        strcat(ccSig, "#");
        Smoke::ModuleIndex ccId = o->smoke->idMethodName(ccSig);
        delete[] ccSig;

        char *ccArg = new char[classNameLen + 8];
        sprintf(ccArg, "const %s&", className);

        Smoke::ModuleIndex classIdx( o->smoke, o->classId );
        ccMeth = o->smoke->findMethod( classIdx, ccId ).index;

        if(!ccMeth) {
            //cctorcache->insert(o->classId, new Smoke::Index(0));
            return 0;
        }
        Smoke::Index method =  o->smoke->methodMaps[ccMeth].method;
        if(method > 0) {
            // Make sure it's a copy constructor
            if(!matches_arg(o->smoke, method, 0, ccArg)) {
                delete[] ccArg;
                //cctorcache->insert(o->classId, new Smoke::Index(0));
                return 0;
            }
            delete[] ccArg;
            ccMeth = method;
        } else {
            // ambiguous method, pick the copy constructor
            Smoke::Index i = -method;
            while(o->smoke->ambiguousMethodList[i]) {
                if(matches_arg(o->smoke, o->smoke->ambiguousMethodList[i], 0, ccArg))
                    break;
                i++;
            }
            delete[] ccArg;
            ccMeth = o->smoke->ambiguousMethodList[i];
            if(!ccMeth) {
                //cctorcache->insert(o->classId, new Smoke::Index(0));
                return 0;
            }
        }
        //cctorcache->insert(o->classId, new Smoke::Index(ccMeth));
    } else {
        ccMeth = *pccMeth;
        if(!ccMeth)
            return 0;
    }
    // Okay, ccMeth is the copy constructor. Time to call it.
    Smoke::StackItem args[2];
    args[0].s_voidp = 0;
    args[1].s_voidp = o->ptr;
    Smoke::ClassFn fn = o->smoke->classes[o->classId].classFn;
    (*fn)(o->smoke->methods[ccMeth].method, 0, args);
    // Assign the new object's binding
    args[1].s_voidp = perlqt_modules[o->smoke].binding;
    (*fn)(0, args[0].s_voidp, args);

    if( do_debug && (do_debug & qtdb_gc) )
        fprintf( stderr, "Copied (%s*)%p to (%s*)%p\n",
            o->smoke->classes[o->classId].className,
            o->ptr,
            o->smoke->classes[o->classId].className,
            args[0].s_voidp
        );

    return args[0].s_voidp;
}

template <class T>
void marshall_it(Marshall* m) {
    switch( m->action() ) {
        case Marshall::FromSV:
            marshall_from_perl<T>( m );
        break;

        case Marshall::ToSV:
            marshall_to_perl<T>( m );
        break;

        default:
            m->unsupported();
        break;
    }
}

template Q_DECL_EXPORT void marshall_it<unsigned int *>(Marshall* m);

QString* qstringFromPerlString( SV* perlstring ) {
    // Finally found how 'in_constructor' is being used
    // PerlQt3 has this bizness:
    // COP *cop = in_constructor ? cxstack[cxstack_ix-3].blk_oldcop : cxstack[cxstack_ix].blk_oldcop;
    // It looks like the 'cxstack' array can be used to look at the current
    // call stack.  If 'in_constructor' is set, we need to look farther up the
    // call stack to find the correct caller.
    // Forget that crap for now.
    // What's blk_oldcop?
    if( SvROK( perlstring ) )
        perlstring = SvRV( perlstring );
    else if( !SvOK( perlstring ) )
        return new QString();

    switch( SvTYPE(perlstring) ) {
        case SVt_PVAV:
        case SVt_PVHV:
        case SVt_PVCV:
        case SVt_PVGV:
            croak( "Request to convert non scalar type to a string\n" );
            break;
        default:
            break; // no error
    }
    COP *cop = cxstack[cxstack_ix].blk_oldcop;
    STRLEN len;
    char* buf = SvPV(perlstring, len);
    if ( SvUTF8( perlstring ) )
        return new QString(QString::fromUtf8(buf, len));
    else if ( cop->op_private & HINT_LOCALE )
        return new QString(QString::fromLocal8Bit(buf, len));

    else
        return new QString(QString::fromLatin1(buf, len));
}

QByteArray* qbytearrayFromPerlString( SV* perlstring ) {
    STRLEN len = 0;
    char *s = SvPV( perlstring, len );
    return new QByteArray( s, len );
}

SV* perlstringFromQString( QString * s ) {
    SV *retval = newSV(0);
    COP *cop = cxstack[cxstack_ix].blk_oldcop;
    if ( !(cop->op_private & HINT_BYTES ) ) {
        sv_setpvn( retval, s->toUtf8().constData(), s->toUtf8().length() );
        SvUTF8_on( retval );
    }
    else if ( cop->op_private & HINT_LOCALE )
        sv_setpvn( retval, s->toLocal8Bit().constData(), s->toLocal8Bit().length() );
    else
        sv_setpvn( retval, s->toLatin1().constData(), s->toLatin1().length() );

    return retval;
}

SV* perlstringFromQByteArray( QByteArray * s ) {
    return newSVpv(s->data(), s->size());
}

void marshall_basetype(Marshall* m) {
    switch( m->type().elem() ) {

        case Smoke::t_bool:
            marshall_it<bool>(m);
        break;

        case Smoke::t_char:
            marshall_it<signed char>(m);
        break;

        case Smoke::t_uchar:
            marshall_it<unsigned char>(m);
        break;

        case Smoke::t_short:
            marshall_it<short>(m);
        break;

        case Smoke::t_ushort:
            marshall_it<unsigned short>(m);
        break;

        case Smoke::t_int:
            marshall_it<int>(m);
        break;

        case Smoke::t_uint:
            marshall_it<unsigned int>(m);
        break;

        case Smoke::t_long:
            marshall_it<long>(m);
        break;

        case Smoke::t_ulong:
            marshall_it<unsigned long>(m);
        break;

        case Smoke::t_float:
            marshall_it<float>(m);
        break;

        case Smoke::t_double:
            marshall_it<double>(m);
        break;

        case Smoke::t_enum:
            switch(m->action()) {
                case Marshall::FromSV:
                    if( SvROK(m->var()) ) {
                        m->item().s_enum = (long)SvIV(SvRV(m->var()));
                    }
                    else {
                        m->item().s_enum = (long)SvIV(m->var());
                    }
                break;
                case Marshall::ToSV: {
                    // Bless the enum value to a package named the same as the
                    // enum name
                    SV* rv = newRV_noinc(newSViv((IV)m->item().s_enum));
                    sv_bless( rv, gv_stashpv(m->type().name(), TRUE) );
                    sv_setsv_mg(m->var(), rv);
                }
                break;
            }
        break;

        case Smoke::t_class:
            switch( m->action() ) {
                case Marshall::FromSV: {
                    smokeperl_object* o = sv_obj_info( m->var() );
                    if( !o || !o->ptr ) {
                        if( m->type().isRef() ) {
                            warn( "References can't be null or undef\n");
                            m->unsupported();
                        }
                        m->item().s_class = 0;
                        break;
                    }

                    void* ptr = o->ptr;

                    if( !m->cleanup() && m->type().isStack()) {
                        ptr = construct_copy( o );
                        // We don't want to set o->ptr = ptr here.  Doing that
                        // will muck with our input variable.  It can cause a
                        // situation where two perl variables point to the same
                        // c++ pointer, and both perl variables say they own
                        // that memory.  Then when GC happens, we'd get a
                        // double free.
                    }

                    Smoke::ModuleIndex fromClass;
                    fromClass.smoke = o->smoke;
                    fromClass.index = o->classId;

                    Smoke::ModuleIndex toClass;
                    toClass.smoke = m->smoke();
                    toClass.index = m->type().classId();

                    ptr = o->smoke->cast(
                        ptr,
                        fromClass,
                        toClass
                    );

                    m->item().s_voidp = ptr;
                }
                break;
                case Marshall::ToSV: {
                    if ( !m->item().s_voidp ) {
                        SvSetMagicSV(m->var(), &PL_sv_undef);
                        return;
                    }

                    // Get return value
                    void* cxxptr = m->item().s_voidp;

                    // The return type may be a class that is defined in a
                    // different smoke object.  So we need to find out which
                    // smoke object to put into the resulting perl object.
                    Smoke::Index returnCId = m->type().classId();
                    Smoke::Class returnClass = m->smoke()->classes[returnCId];
                    Smoke::ModuleIndex returnMId;
                    if ( returnClass.external ) {
                        returnMId = Smoke::classMap[returnClass.className];
                    }
                    else {
                        returnMId = Smoke::ModuleIndex( m->smoke(), returnCId );
                    }

                    // See if we already made a perl object for this pointer
                    SV* var = getPointerObject(cxxptr);
                    if (var) {
                        // We've found something in the pointer map that
                        // matches.  Let's make sure that object is still
                        // valid.  This shouldn't be necessary, but it seems
                        // that some things bypass the Binding::deleted code.
                        smokeperl_object* o = sv_obj_info(var);
                        if( o && o->ptr ) {
                            if ( Smoke::isDerivedFrom( o->smoke, o->classId, returnMId.smoke, returnMId.index ) ) {
                                SvSetMagicSV(m->var(), var);
                                break;
                            }
                            else {
                                unmapPointer( o, o->classId, 0 );
                            }
                        }
                    }

                    // We have a pointer to something that we didn't create.
                    // We don't own this memory, so we don't want to delete it.
                    // The smokeperl_object contains all the info we need to
                    // know about this object
                    smokeperl_object* o = alloc_smokeperl_object(
                        false, returnMId.smoke, returnMId.index, cxxptr );

                    // Try to create a copy (using the copy constructor) if
                    // it's a const ref
                    if( m->type().isConst() && m->type().isRef()) {
	                    cxxptr = construct_copy( o );

                        if(cxxptr) {
                            o->ptr = cxxptr;
                            // We made this copy, we do own this memory
                            o->allocated = true;
                        }
                    }

                    // Figure out what Perl name this should get
                    const char* classname = perlqt_modules[o->smoke].resolve_classname(o);

                    // Bless a HV ref into that package name, and shove o into
                    // var
                    var = sv_2mortal(set_obj_info( classname, o ) );

                    // Store this into the ptr map for reference from virtual
                    // function calls.
                    if( SmokeClass( m->type() ).hasVirtual() )
                        mapPointer(var, o, pointer_map, o->classId, 0);

                    // Copy our local var into the marshaller's var, and make
                    // sure to copy our magic with it
                    SvSetMagicSV(m->var(), var);
                }
            }
        break;

        default:
            return marshall_unknown( m );
        break;
    }
}

void marshall_void(Marshall *) {}
void marshall_unknown(Marshall *m) {
    m->unsupported();
}

static void marshall_doubleR(Marshall *m) {
    switch(m->action()) {
        case Marshall::FromSV: {
            SV *rv = m->var();
            double * d = new double;
            if ( SvOK( rv ) ) {
                *d = SvNV(rv);
            }
            else {
                *d = 0;
            }
            m->item().s_voidp = d;
            m->next();
            if (m->cleanup() && m->type().isConst()) {
                delete d;
            } else {
                sv_setnv(m->var(), *d);
            }
        }
        break;
        case Marshall::ToSV: {
            double *dp = (double*)m->item().s_voidp;
            SV *rv = m->var();
            if (dp == 0) {
                sv_setsv( rv, &PL_sv_undef );
                break;
            }
            sv_setnv(m->var(), *dp);
            m->next();
            if (!m->type().isConst()) {
                *dp = SvNV(m->var());
            }
        }
        break;
        default:
            m->unsupported();
        break;
    }
}

void marshall_QString(Marshall* m) {
    switch(m->action()) {
        case Marshall::FromSV: {
            SV* sv = m->var();
            QString* mystr = 0;

            if( SvROK( sv ) )
                sv = SvRV( sv );

            // Don't check for SvPOK.  Calling SvPV_nolen will stringify the
            // sv, which is what we want for numbers.
            mystr = qstringFromPerlString( sv );

            m->item().s_voidp = (void*)mystr;
            m->next();

            if (!m->type().isConst() && !SvREADONLY(sv) && mystr != 0) {
                sv_setsv( sv, perlstringFromQString(mystr) );
            }

            if ( mystr != 0 && m->cleanup() ) {
                delete mystr;
            }
        }
        break;
        case Marshall::ToSV: {
            QString* cxxptr = (QString*)m->item().s_voidp;
            if( cxxptr ) {
                if (cxxptr->isNull()) {
                    sv_setsv( m->var(), &PL_sv_undef );
                }
                else {
                    sv_setsv( m->var(), perlstringFromQString( cxxptr ) );
                }

                if (m->cleanup() || m->type().isStack() ) {
                    delete cxxptr;
                }
            }
            else {
                sv_setsv( m->var(), &PL_sv_undef );
            }
        }
        break;
        default:
            m->unsupported();
        break;
    }
}

static void marshall_QByteArray(Marshall *m) {
    UNTESTED_HANDLER("marshall_QByteArray");
    switch(m->action()) {
        case Marshall::FromSV: {
            QByteArray* s = 0;
            SV* sv = m->var();
            if( SvOK(sv) ) {
                s = qbytearrayFromPerlString( sv );
            } else {
                s = new QByteArray();
            }

            m->item().s_voidp = s;
            m->next();

            if ( s != 0 && m->cleanup() ) {
                delete s;
            }
        }
        break;

        case Marshall::ToSV: {
            QByteArray *s = (QByteArray*)m->item().s_voidp;
            if( s ) {
                // No magic needed on these, they're not blessed
                if (s->isNull()) {
                    sv_setsv( m->var(), &PL_sv_undef );
                } else {
                    sv_setsv( m->var(), perlstringFromQByteArray(s) );
                }
                if(m->cleanup() || m->type().isStack() ) {
                    delete s;
                }
            } else {
                sv_setsv( m->var(), &PL_sv_undef );
            }
        }
        break;

        default:
            m->unsupported();
            break;
    }
}

static void marshall_charP_array(Marshall* m) {
    switch( m->action() ) {
        case Marshall::FromSV: {
            SV* arglistref = m->var();
            if ( !SvOK( arglistref ) && !SvROK( arglistref ) ) {
                m->item().s_voidp = 0;
                break;
            }

            AV* arglist = (AV*)SvRV( arglistref );

            int argc = av_len(arglist) + 1;
            char** argv = new char*[argc + 1];
            long i;
            for (i = 0; i < argc; ++i) {
                SV** item = av_fetch(arglist, i, 0);
                if( item ) {
                    STRLEN len = 0;
                    char* s = SvPV( *item, len );
                    argv[i] = new char[len + 1];
                    strcpy( argv[i], s );
                }
            }
            argv[i] = 0;
            m->item().s_voidp = argv;
            m->next();

            // No cleanup, we don't know what's pointing to us
        }
        break;

        default:
            m->unsupported();
        break;
    }
}

void marshall_QStringList(Marshall *m) {
    // Not copied from ruby
    switch(m->action()) {
        case Marshall::FromSV: {
            SV* listref = m->var();
            if( !SvROK(listref) && (SvTYPE(SvRV(listref)) != SVt_PVAV) ) {
                m->item().s_voidp = 0;
                break;
            }
            AV* list = (AV*)SvRV(listref);

            int count = av_len(list) + 1;
            QStringList *stringlist = new QStringList;

            for(long i = 0; i < count; ++i) {
                SV** lookup = av_fetch( list, i, 0 );
                if( !lookup ) {
                    continue;
                }
                SV* item = *lookup;
                if(!item && ( SvPOK(item) ) ) {
                    stringlist->append(QString());
                    continue;
                }
                stringlist->append(*(qstringFromPerlString(item)));
            }

            m->item().s_voidp = stringlist;
            m->next();

            // After we do the method call, the contents of the stringlist may
            // have changed.  To support reference-like behavior, we need to
            // make sure that our perl array matches the current contents of
            // the qstringlist.
            if (stringlist != 0 && !m->type().isConst()) {
                av_clear(list);
                for(QStringList::Iterator it = stringlist->begin(); it != stringlist->end(); ++it)
                    av_push( list, perlstringFromQString(&(*it)) );
            }

            if (m->cleanup()) {
                delete stringlist;
            }

            break;
        }
        case Marshall::ToSV: {
            QStringList *stringlist = static_cast<QStringList*>(m->item().s_voidp);
            if (!stringlist) {
                sv_setsv(m->var(), &PL_sv_undef);
                break;
            }

            AV* av = newAV();
            SV* sv = newRV_noinc( (SV*)av );
            for (QStringList::Iterator it = stringlist->begin(); it != stringlist->end(); ++it) {
                av_push( av, perlstringFromQString(&(*it)) );
            }

            sv_setsv(m->var(), sv);

            if (m->cleanup()) {
                delete stringlist;
            }
        }
        break;
    default:
        m->unsupported();
        break;
    }
}

void marshall_QByteArrayList(Marshall *m) {
    UNTESTED_HANDLER("marshall_QByteArrayList");
    switch(m->action()) {
        case Marshall::FromSV: {
            SV *listref = m->var();
            if ( !SvOK( listref ) && !SvROK( listref ) ) {
                m->item().s_voidp = 0;
                break;
            }

            AV *list = (AV*)SvRV( listref );

            int count = av_len(list) + 1;
            QList<QByteArray> *stringlist = new QList<QByteArray>;

            for(long i = 0; i < count; ++i) {
                SV **item = av_fetch(list, i, 0);
                if( !item ) {
                    stringlist->append(QByteArray());
                    continue;
                }

                STRLEN len = 0;
                char *s = SvPV( *item, len );
                stringlist->append(QByteArray(s, len));
            }

            m->item().s_voidp = stringlist;
            m->next();

            if (!m->type().isConst()) {
                av_clear(list);
                for (int i = 0; i < stringlist->size(); ++i) {
                    av_push(list, newSVpv((const char *) stringlist->at(i), 0));
                }
            }

            if(m->cleanup()) {
                delete stringlist;
            }
        }
        break;
        case Marshall::ToSV: {
            QList<QByteArray> *stringlist = static_cast<QList<QByteArray>*>(m->item().s_voidp);
            if(!stringlist) {
                sv_setsv(m->var(), &PL_sv_undef);
                break;
            }

            AV *av = newAV();
            for (int i = 0; i < stringlist->size(); ++i) {
                SV *rv = newSVpv((const char *) stringlist->at(i), 0);
                av_push(av, rv);
            }

            sv_setsv( m->var(), newRV_noinc( (SV*)av ) );

            if (m->cleanup()) {
                delete stringlist;
            }
        }
        break;
        default:
            m->unsupported();
        break;
    }
}

void marshall_QListCharStar(Marshall *m) {
    UNTESTED_HANDLER("marshall_QListCharStar");
    switch(m->action()) {
        case Marshall::FromSV: {
            SV *avref = m->var();
            if ( !SvOK( avref ) && !SvROK( avref ) ) {
                m->item().s_voidp = 0;
                break;
            }

            AV *av = (AV*)SvRV( avref );

            int count = av_len(av) + 1;
            QList<const char*> *list = new QList<const char*>;
            long i;
            for(i = 0; i < count; ++i) {
                SV **item = av_fetch(av, i, 0);
                if ( !item ) {
                    list->append(0);
                    continue;
                }
                list->append(SvPV_nolen(*item));
            }

            m->item().s_voidp = list;
        }
        break;
        case Marshall::ToSV: {
            QList<const char*> *list = (QList<const char*>*)m->item().s_voidp;
            if (list == 0) {
                sv_setsv( m->var(), &PL_sv_undef );
                break;
            }

            AV *av = newAV();
            for ( QList<const char*>::iterator i = list->begin(); 
                  i != list->end(); 
                  ++i ) 
            {
                av_push(av, newSVpv((const char *)*i, 0));
            }

            sv_setsv( m->var(), newRV_noinc( (SV*)av ) );
            m->next();
        }
        break;
        default:
            m->unsupported();
        break;
    }
}

void marshall_QListInt(Marshall *m) {
    switch(m->action()) {
        case Marshall::FromSV: {
            SV *listref = m->var();
            if ( !SvOK( listref ) && !SvROK( listref ) ) {
                m->item().s_voidp = 0;
                break;
            }

            AV *list = (AV*)SvRV( listref );
            
            int count = av_len(list) + 1;
            QList<int> *valuelist = new QList<int>;
            for( long i = 0; i < count; ++i) {
                SV **item = av_fetch(list, i, 0);
                if( !item || !SvIOK( *item ) ) {
                    valuelist->append(0);
                    continue;
                }
                valuelist->append(SvIV(*item));
            }

            m->item().s_voidp = valuelist;
            m->next();

            if (!m->type().isConst()) {
                av_clear(list);

                for (	QList<int>::iterator i = valuelist->begin(); 
                        i != valuelist->end(); 
                        ++i ) 
                {
                    av_push(list, newSViv((int)*i));
                }
            }

            if (m->cleanup()) {
                delete valuelist;
            }
        }
        break;
        case Marshall::ToSV: {
            QList<int> *valuelist = (QList<int>*)m->item().s_voidp;
            if(!valuelist) {
                sv_setsv(m->var(), &PL_sv_undef);
                break;
            }

            AV *av = newAV();

            for (	QList<int>::iterator i = valuelist->begin(); 
                    i != valuelist->end(); 
                    ++i ) 
            {
                av_push(av, newSViv((int)*i));
            }

            sv_setsv( m->var(), newRV_noinc( (SV*)av ) );
            m->next();

            if (m->cleanup()) {
                delete valuelist;
            }
        }
        break;
        default:
            m->unsupported();
            break;
    }
}

void marshall_QListUInt(Marshall *m) {
    UNTESTED_HANDLER("marshall_QListUInt");
    switch(m->action()) {
        case Marshall::FromSV: {
            SV *listref = m->var();
            if ( !SvOK( listref ) && !SvROK( listref ) ) {
                m->item().s_voidp = 0;
                break;
            }

            AV *list = (AV*)SvRV( listref );

            int count = av_len(list) + 1;
            QList<uint> *valuelist = new QList<uint>;

            long i;
            for(i = 0; i < count; ++i) {
                SV **item = av_fetch(list, i, 0);
                if( !item ) {
                    valuelist->append(0);
                    continue;
                }
                valuelist->append(SvUV(*item));
            }

            m->item().s_voidp = valuelist;
            m->next();

            if (!m->type().isConst()) {
                av_clear(list);

                for (	QList<uint>::iterator i = valuelist->begin(); 
                        i != valuelist->end(); 
                        ++i ) 
                {
                    av_push(list, newSVuv((int)*i));
                }
            }

            if (m->cleanup()) {
                delete valuelist;
            }
        }
        break;
        case Marshall::ToSV: {
            QList<uint> *valuelist = (QList<uint>*)m->item().s_voidp;
            if(!valuelist) {
                sv_setsv(m->var(), &PL_sv_undef);
                break;
            }

            AV *av = newAV();

            for (	QList<uint>::iterator i = valuelist->begin(); 
                    i != valuelist->end(); 
                    ++i ) 
            {
                av_push(av, newSVuv((int)*i));
            }

            sv_setsv( m->var(), newRV_noinc( (SV*)av ) );
            m->next();

            if (m->cleanup()) {
                delete valuelist;
            }
        }
        break;
        default:
            m->unsupported();
        break;
    }
}

void marshall_QListqreal(Marshall *m) {
    UNTESTED_HANDLER("marshall_QListqreal");
    switch(m->action()) {
        case Marshall::FromSV: {
            SV* listref = m->var();
            if ( !SvOK( listref ) && !SvROK( listref ) ) {
                m->item().s_voidp = 0;
                break;
            }

            AV *list = (AV*)SvRV( listref );

            int count = av_len(list) + 1;
            QList<qreal> *valuelist = new QList<qreal>;
            for(long i = 0; i < count; ++i) {
                SV **item = av_fetch(list, i, 0);
                if( !item ) {
                    valuelist->append(0.0);
                    continue;
                }
                valuelist->append(SvNV(*item));
            }

            m->item().s_voidp = valuelist;
            m->next();

            if (!m->type().isConst()) {
                av_clear(list);

                for (	QList<qreal>::iterator i = valuelist->begin(); 
                        i != valuelist->end(); 
                        ++i ) 
                {
                    av_push(list, newSVnv((qreal)*i));
                }
            }

            if (m->cleanup()) {
                delete valuelist;
            }
        }
        break;
        case Marshall::ToSV: {
            QList<qreal> *valuelist = (QList<qreal>*)m->item().s_voidp;
            if(!valuelist) {
                sv_setsv(m->var(), &PL_sv_undef);
                break;
            }

            AV *av = newAV();

            for (	QList<qreal>::iterator i = valuelist->begin(); 
                    i != valuelist->end(); 
                    ++i ) 
            {
                av_push(av, newSVnv((qreal)*i));
            }

            sv_setsv( m->var(), newRV_noinc( (SV*)av ) );
            m->next();

            if (m->cleanup()) {
                delete valuelist;
            }
        }
        break;
        default:
            m->unsupported();
        break;
    }
}

void marshall_QListLocaleCountry(Marshall *m){
    switch(m->action()) {
        case Marshall::FromSV: {
            m->unsupported();
        }
        break;

        case Marshall::ToSV: {
            QList<QLocale::Country> *valuelist = (QList<QLocale::Country>*)m->item().s_voidp;
            if(!valuelist) {
                sv_setsv(m->var(), &PL_sv_undef);
                break;
            }

            AV* av = newAV();
            SV* avref = newRV_noinc((SV*)av);

            for(int i=0; i < valuelist->size(); ++i) {
                void *p = (void *) &(valuelist->at(i));

                SV *rv = newRV_noinc(newSViv(*(IV*)p));
                sv_bless( rv, gv_stashpv("QLocale::Country", TRUE) );
                av_push(av, rv);
            }

            sv_setsv(m->var(), avref);
            m->next();

            if (m->cleanup()) {
                delete valuelist;
            }

        }
        break;

        default:
            m->unsupported();
        break;
    }
}

void marshall_QVectorQPairDoubleQColor(Marshall *m)  {
    switch(m->action()) {
        case Marshall::FromSV: {
            SV *listref = m->var();
            if ( !listref || !SvROK( listref ) || SvTYPE( SvRV(listref) ) != SVt_PVAV ) {
                m->item().s_voidp = 0;
                break;
            }
            AV *list = (AV*)SvRV(listref);
            int count = av_len(list) + 1;
            QVector <QPair<double,QColor> > *cpplist = new QVector< QPair<double,QColor> >;
            for(long i = 0; i < count; ++i) {
                SV **item = av_fetch(list, i, 0);
                // TODO do type checking!
                if(!item || !SvOK(*item) || !SvROK(*item) || SvTYPE(SvRV(*item)) != SVt_PVAV)
                    continue;

                AV* pair = (AV*)SvRV(*item);                
                QPair<double,QColor>* qpair = new QPair<double,QColor>;
                qpair->first = SvNV(*(av_fetch(pair, 0, 0)));
                smokeperl_object* qcoloro = sv_obj_info(*(av_fetch(pair, 1, 0)));

                if ( !qcoloro || !qcoloro->ptr )
                    continue;

                void* qcolorptr = qcoloro->smoke->cast(
                    qcoloro->ptr,                // pointer
                    qcoloro->classId,                // from
                    qcoloro->smoke->idClass("QColor").index            // to
                );
                qpair->second = *(QColor*)qcolorptr;
                cpplist->append(*qpair);
            }

            m->item().s_voidp = cpplist;
            m->next();

            if (!m->type().isConst()) {
                av_clear(list);
                for(int i=0; i < cpplist->size(); ++i) {
                    QPair<double,QColor> qpair = cpplist->at(i);

                    AV *pair = newAV();
                    SV *pairref = newRV_noinc((SV*)pair);

                    av_push( pair, newSVnv( qpair.first ) );

                    SV *obj = getPointerObject((void*)&qpair.second);
                    av_push( pair, obj );
                    av_push(list, pairref);
                }
            }

            if (m->cleanup()) {
                delete cpplist;
            }
        }
        break;

        case Marshall::ToSV: {
            QVector <QPair<double,QColor> > *valuelist = (QVector <QPair<double,QColor> >*)m->item().s_voidp;
            if(!valuelist) {
                sv_setsv(m->var(), &PL_sv_undef);
                break;
            }

            AV* av = newAV();
            SV* avref = newRV_noinc((SV*)av);

            //int ix = m->smoke()->idClass(ItemSTR).index;
            //const char * className = binding.className(ix);

            for(int i=0; i < valuelist->size(); ++i) {
                QPair<double,QColor> p = valuelist->at(i);

                if(m->item().s_voidp == 0) {
                    sv_setsv(m->var(), &PL_sv_undef);
                    break;
                }

                AV *pair = newAV();
                SV *pairref = newRV_noinc((SV*)pair);

                av_push( pair, newSVnv( p.first ) );

                SV *obj = getPointerObject((void*)&p.second);
                if( !obj || !SvOK(obj) ) {
                    Smoke::ModuleIndex mi = m->smoke()->findClass("QColor");
                    smokeperl_object *o = alloc_smokeperl_object(
                        false, mi.smoke, mi.index, (void*)&p.second );
                    if( !m->cleanup() && m->type().isStack()) {

                        void *ptr = construct_copy( o );
                        if(ptr) {
                            o->ptr = ptr;
                            o->allocated = true;
                        }
                    }

                    const char* classname = perlqt_modules[o->smoke].resolve_classname(o);

                    obj = set_obj_info( classname, o );
                }

                av_push( pair, obj );

                av_push(av, pairref);
            }

            sv_setsv(m->var(), avref);
            m->next();

            if (m->cleanup()) {
                delete valuelist;
            }
        }
        break;

        default:
            m->unsupported();
        break;
    }
}

void marshall_QVectorqreal(Marshall *m) {
    UNTESTED_HANDLER("marshall_QVectorqreal");
    switch(m->action()) {
        case Marshall::FromSV: {
            SV *listref = m->var();
            if ( !SvOK( listref ) && !SvROK( listref ) ) {
                m->item().s_voidp = 0;
                break;
            }

            AV *list = (AV*)SvRV( listref );

            int count = av_len(list) + 1;
            QVector<qreal> *valuelist = new QVector<qreal>;
            for ( long i = 0; i < count; ++i) {
                SV **item = av_fetch(list, i, 0);
                if( !item ) {
                    valuelist->append(0.0);
                    continue;
                }

                valuelist->append(SvNV(*item));
            }

            m->item().s_voidp = valuelist;
            m->next();

            if (!m->type().isConst()) {
                av_clear(list);

                for (	QVector<qreal>::iterator i = valuelist->begin(); 
                        i != valuelist->end(); 
                        ++i ) 
                {
                    av_push(list, newSVnv((qreal)*i));
                }
            }

            if (m->cleanup()) {
                delete valuelist;
            }
        }
        break;
        case Marshall::ToSV: {
            QVector<qreal> *valuelist = (QVector<qreal>*)m->item().s_voidp;
            if(!valuelist) {
                sv_setsv(m->var(), &PL_sv_undef);
                break;
            }

            AV *av = newAV();

            for (	QVector<qreal>::iterator i = valuelist->begin(); 
                    i != valuelist->end(); 
                    ++i ) 
            {
                av_push(av, newSVnv((qreal)*i));
            }

            sv_setsv( m->var(), newRV_noinc( (SV*)av ) );
            m->next();

            if (m->cleanup()) {
                delete valuelist;
            }
        }
        break;
        default:
            m->unsupported();
        break;
    }
}

void marshall_QVectorint(Marshall *m) {
    UNTESTED_HANDLER("marshall_QVectorint");
    switch(m->action()) {
        case Marshall::FromSV: {
            SV *listref = m->var();
            if ( !SvOK( listref ) && !SvROK( listref ) ) {
                m->item().s_voidp = 0;
                break;
            }

            AV *list = (AV*)SvRV( listref );

            int count = av_len(list) + 1;
            QVector<int> *valuelist = new QVector<int>;
            for ( long i = 0; i < count; ++i) {
                SV **item = av_fetch(list, i, 0);
                if( !item ) {
                    valuelist->append(0);
                    continue;
                }

                valuelist->append(SvIV(*item));
            }

            m->item().s_voidp = valuelist;
            m->next();

            if (!m->type().isConst()) {
                av_clear(list);

                for (	QVector<int>::iterator i = valuelist->begin(); 
                        i != valuelist->end(); 
                        ++i ) 
                {
                    av_push(list, newSViv((int)*i));
                }
            }

            if (m->cleanup()) {
                delete valuelist;
            }
        }
        break;
        case Marshall::ToSV: {
            QVector<int> *valuelist = (QVector<int>*)m->item().s_voidp;
            if(!valuelist) {
                sv_setsv(m->var(), &PL_sv_undef);
                break;
            }

            AV *av = newAV();

            for (	QVector<int>::iterator i = valuelist->begin(); 
                    i != valuelist->end(); 
                    ++i ) 
            {
                av_push(av, newSViv((int)*i));
            }

            sv_setsv( m->var(), newRV_noinc( (SV*)av ) );
            m->next();

            if (m->cleanup()) {
                delete valuelist;
            }
        }
        break;
        default:
            m->unsupported();
        break;
    }
}

/*
void marshall_voidP(Marshall *m) {
    UNTESTED_HANDLER("marshall_voidP");
    switch(m->action()) {
      case Marshall::FromSV:
	{
	    VALUE rv = *(m->var());
	    if (rv != Qnil)
		m->item().s_voidp = (void*)NUM2INT(*(m->var()));
	    else
		m->item().s_voidp = 0;
	}
	break;
      case Marshall::ToSV:
	{
	    *(m->var()) = Data_Wrap_Struct(rb_cObject, 0, 0, m->item().s_voidp);
	}
	break;
      default:
	m->unsupported();
	break;
    }
}
*/

void marshall_QMapQStringQString(Marshall *m) {
    UNTESTED_HANDLER("marshall_QMapQStringQString");
    switch(m->action()) {
        case Marshall::FromSV: {
            SV *hashref = m->var();
            if( !SvROK(hashref) && (SvTYPE(SvRV(hashref)) != SVt_PVHV) ) {
                m->item().s_voidp = 0;
                break;
            }

            HV *hash = (HV*)SvRV(hashref);
            QMap<QString,QString> * map = new QMap<QString,QString>;

            char* key;
            SV* val;
            I32* keylen = new I32;
            while( ( val = hv_iternextsv( hash, &key, keylen ) ) ) {
                (*map)[QString(key)] = QString(SvPV_nolen(val));
            }
            delete keylen;

            m->item().s_voidp = map;
            m->next();

            if(m->cleanup())
                delete map;
        }
        break;
        case Marshall::ToSV: {
            QMap<QString,QString> *map = (QMap<QString,QString>*)m->item().s_voidp;
            if(!map) {
                sv_setsv(m->var(), &PL_sv_undef);
                break;
            }

            HV *hv = newHV();
            SV *sv = newRV_noinc( (SV*)hv );

            QMap<QString,QString>::Iterator it;
            for (it = map->begin(); it != map->end(); ++it) {
                SV *key = perlstringFromQString((QString*)&(it.key()));
                STRLEN keylen = it.key().size();
                SV *val = perlstringFromQString((QString*) &(it.value()));
                hv_store( hv, SvPV_nolen(key), keylen, val, 0 );
            }

            sv_setsv(m->var(), sv);
            m->next();

            if(m->cleanup())
                delete map;
        }
        break;
        default:
            m->unsupported();
        break;
    }
}

void marshall_QMapQStringQUrl(Marshall *m) {
    switch(m->action()) {
        case Marshall::FromSV: {
            SV *hashref = m->var();
            if( !SvROK(hashref) && (SvTYPE(SvRV(hashref)) != SVt_PVHV) ) {
                m->item().s_voidp = 0;
                break;
            }

            HV *hash = (HV*)SvRV(hashref);
            QMap<QString,QUrl> * map = new QMap<QString,QUrl>;

            char* key;
            SV* value;
            I32* keylen = new I32;
            while( ( value = hv_iternextsv( hash, &key, keylen ) ) ) {
                smokeperl_object *o = sv_obj_info(value);
                if (!o || !o->ptr || o->classId != o->smoke->findClass("QVariant").index) {
                    continue;
                    // If the value isn't a Qt::Variant, then try and construct
                    // a Qt::Variant from it
                    // TODO: I have no idea how to do this.
                    /*
                    value = rb_funcall(qvariant_class, rb_intern("fromValue"), 1, value);
                    if (value == Qnil) {
                        continue;
                    }
                    o = value_obj_info(value);
                    */
                }

                (*map)[QString(key)] = (QUrl)*(QUrl*)o->ptr;
            }
            delete keylen;

            m->item().s_voidp = map;
            m->next();

            if(m->cleanup())
                delete map;
        }
        break;
        case Marshall::ToSV: {
            QMap<QString,QUrl> *map = (QMap<QString,QUrl>*)m->item().s_voidp;
            if(!map) {
                sv_setsv(m->var(), &PL_sv_undef);
                break;
            }

            HV *hv = newHV();
            SV *sv = newRV_noinc( (SV*)hv );

            QMap<QString,QUrl>::Iterator it;
            for (it = map->begin(); it != map->end(); ++it) {
                void *p = new QUrl(it.value());
                SV *obj = getPointerObject(p);

                if ( !obj || !SvOK(obj) ) {
                    Smoke::ModuleIndex returnMId = Smoke::classMap["QUrl"];
                    smokeperl_object * o = alloc_smokeperl_object(
                        true, 
                        returnMId.smoke,
                        returnMId.index,
                        p );
                    obj = set_obj_info(" Qt::Url", o);
                }

                SV *key = perlstringFromQString((QString*)&(it.key()));
                STRLEN keylen = it.key().size();
                hv_store( hv, SvPV_nolen(key), keylen, obj, 0 );
            }

            sv_setsv(m->var(), sv);
            m->next();

            if(m->cleanup())
                delete map;
        }
        break;
        default:
            m->unsupported();
        break;
    }
}

void marshall_QMapQStringQVariant(Marshall *m) {
    switch(m->action()) {
        case Marshall::FromSV: {
            SV *hashref = m->var();
            if( !SvROK(hashref) && (SvTYPE(SvRV(hashref)) != SVt_PVHV) ) {
                m->item().s_voidp = 0;
                break;
            }

            HV *hash = (HV*)SvRV(hashref);
            QMap<QString,QVariant> * map = new QMap<QString,QVariant>;

            char* key;
            SV* value;
            I32* keylen = new I32;
            while( ( value = hv_iternextsv( hash, &key, keylen ) ) ) {
                smokeperl_object *o = sv_obj_info(value);
                if (!o || !o->ptr || o->classId != o->smoke->findClass("QVariant").index) {
                    continue;
                    // If the value isn't a Qt::Variant, then try and construct
                    // a Qt::Variant from it
                    // TODO: I have no idea how to do this.
                    /*
                    value = rb_funcall(qvariant_class, rb_intern("fromValue"), 1, value);
                    if (value == Qnil) {
                        continue;
                    }
                    o = value_obj_info(value);
                    */
                }

                (*map)[QString(key)] = (QVariant)*(QVariant*)o->ptr;
            }
            delete keylen;

            m->item().s_voidp = map;
            m->next();

            if(m->cleanup())
                delete map;
        }
        break;
        case Marshall::ToSV: {
            QMap<QString,QVariant> *map = (QMap<QString,QVariant>*)m->item().s_voidp;
            if(!map) {
                sv_setsv(m->var(), &PL_sv_undef);
                break;
            }

            HV *hv = newHV();
            SV *sv = newRV_noinc( (SV*)hv );

            QMap<QString,QVariant>::Iterator it;
            for (it = map->begin(); it != map->end(); ++it) {
                void *p = new QVariant(it.value());
                SV *obj = getPointerObject(p);

                if ( !obj || !SvOK(obj) ) {
                    smokeperl_object  * o = alloc_smokeperl_object(	true, 
                                                                    m->smoke(), 
                                                                    m->smoke()->idClass("QVariant").index, 
                                                                    p );
                    obj = set_obj_info(" Qt::Variant", o);
                }

                SV *key = perlstringFromQString((QString*)&(it.key()));
                STRLEN keylen = it.key().size();
                hv_store( hv, SvPV_nolen(key), keylen, obj, 0 );
            }

            sv_setsv(m->var(), sv);
            m->next();

            if(m->cleanup())
                delete map;
        }
        break;
        default:
            m->unsupported();
        break;
    }
}

void marshall_QMapIntQVariant(Marshall *m) {
    UNTESTED_HANDLER("marshall_QMapIntQVariant");
    switch(m->action()) {
        case Marshall::FromSV: {
            SV *hashref = m->var();
            if( !SvROK(hashref) && (SvTYPE(SvRV(hashref)) != SVt_PVHV) ) {
                m->item().s_voidp = 0;
                break;
            }

            HV *hash = (HV*)SvRV(hashref);
            QMap<int,QVariant> * map = new QMap<int,QVariant>;

            char* key;
            SV* value;
            I32* keylen = new I32;
            while( ( value = hv_iternextsv( hash, &key, keylen ) ) ) {
                smokeperl_object *o = sv_obj_info(value);
                if (!o || !o->ptr || o->classId != o->smoke->findClass("QVariant").index) {
                    continue;
                    /*
                    // If the value isn't a Qt::Variant, then try and construct
                    // a Qt::Variant from it
                    value = rb_funcall(qvariant_class, rb_intern("fromValue"), 1, value);
                    if ( !value && !SvOK(value) ) {
                        continue;
                    }
                    o = sv_obj_info(value);
                    */
                }

                // Convert the char* into an int
                int intkey;
                if( EOF == sscanf( key, "%d", &intkey ) ) {
                    fprintf( stderr, "Error in marshall_QMapIntQVariant while converting key to integer type\n" );
                }

                (*map)[intkey] = (QVariant)*(QVariant*)o->ptr;
            }
            delete keylen;

            m->item().s_voidp = map;
            m->next();

            if(m->cleanup())
                delete map;
        }
        break;
        case Marshall::ToSV: {
            QMap<int,QVariant> *map = (QMap<int,QVariant>*)m->item().s_voidp;
            if (!map) {
                sv_setsv(m->var(), &PL_sv_undef);
                break;
            }

            HV *hv = newHV();
            SV *sv = newRV_noinc( (SV*)hv );

            QMap<int,QVariant>::Iterator it;
            for (it = map->begin(); it != map->end(); ++it) {
                void *p = new QVariant(it.value());
                SV *obj = getPointerObject(p);

                if ( !obj || !SvOK(obj) ) {
                    smokeperl_object * o = alloc_smokeperl_object( true, 
                        m->smoke(), 
                        m->smoke()->idClass("QVariant").index, 
                        p );
                    obj = set_obj_info("Qt::Variant", o);
                }

                SV *key = newSViv(it.key());
                STRLEN keylen = SvLEN( key );
                hv_store( hv, SvPV_nolen(key), keylen, obj, 0 );
            }

            sv_setsv(m->var(), sv);
            m->next();

            if(m->cleanup())
                delete map;
        }
        break;
        default:
            m->unsupported();
        break;
    }
}

/*
void marshall_QMapintQVariant(Marshall *m) {
    UNTESTED_HANDLER("marshall_QMapintQVariant");
    switch(m->action()) {
      case Marshall::FromSV:
	{
	    VALUE hash = *(m->var());
	    if (TYPE(hash) != T_HASH) {
		m->item().s_voidp = 0;
		break;
	    }
		
		QMap<int,QVariant> * map = new QMap<int,QVariant>;
		
		// Convert the ruby hash to an array of key/value arrays
		VALUE temp = rb_funcall(hash, rb_intern("to_a"), 0);

		for (long i = 0; i < RARRAY_LEN(temp); ++i) {
			VALUE key = rb_ary_entry(rb_ary_entry(temp, i), 0);
			VALUE value = rb_ary_entry(rb_ary_entry(temp, i), 1);
			
			smokeruby_object *o = value_obj_info(value);
			if( !o || !o->ptr)
                   continue;
			void * ptr = o->ptr;
			ptr = o->smoke->cast(ptr, o->classId, o->smoke->idClass("QVariant").index);
			
			(*map)[NUM2INT(key)] = (QVariant)*(QVariant*)ptr;
		}
	    
		m->item().s_voidp = map;
		m->next();
		
	    if(m->cleanup())
		delete map;
	}
	break;
      case Marshall::ToSV:
	{
	    QMap<int,QVariant> *map = (QMap<int,QVariant>*)m->item().s_voidp;
	    if(!map) {
		*(m->var()) = Qnil;
		break;
	    }
		
	    VALUE hv = rb_hash_new();
			
		QMap<int,QVariant>::Iterator it;
		for (it = map->begin(); it != map->end(); ++it) {
			void *p = new QVariant(it.value());
			VALUE obj = getPointerObject(p);
				
			if (obj == Qnil) {
				smokeruby_object  * o = alloc_smokeruby_object(	true, 
																m->smoke(), 
																m->smoke()->idClass("QVariant").index, 
																p );
				obj = set_obj_info("Qt::Variant", o);
			}
			
			rb_hash_aset(hv, INT2NUM((int)(it.key())), obj);
        }
		
		*(m->var()) = hv;
		m->next();
		
	    if(m->cleanup())
		delete map;
	}
	break;
      default:
	m->unsupported();
	break;
    }
}

void marshall_voidP_array(Marshall *m) {
    UNTESTED_HANDLER("marshall_voidP_array");
    switch(m->action()) {
	case Marshall::FromSV:
	{
	    VALUE rv = *(m->var());
		if (rv != Qnil) {
			Data_Get_Struct(rv, void*, m->item().s_voidp);
		} else {
			m->item().s_voidp = 0;
		}
	}
	break;
	case Marshall::ToSV:
	{
		VALUE rv = Data_Wrap_Struct(rb_cObject, 0, 0, m->item().s_voidp);
		*(m->var()) = rv;
	}
	break;
		default:
		m->unsupported();
	break;
    }
}
*/

Q_DECL_EXPORT void marshall_QHashQStringQVariant(Marshall *m) {
    switch(m->action()) {
        case Marshall::FromSV: {
            SV *hashref = m->var();
            if( !SvROK(hashref) && (SvTYPE(SvRV(hashref)) != SVt_PVHV) ) {
                m->item().s_voidp = 0;
                break;
            }

            HV *hash = (HV*)SvRV(hashref);
            QHash<QString,QVariant> * chash = new QHash<QString,QVariant>;

            char* key;
            SV* value;
            I32* keylen = new I32;
            while( ( value = hv_iternextsv( hash, &key, keylen ) ) ) {
                smokeperl_object *o = sv_obj_info(value);
                if (!o || !o->ptr || o->classId != o->smoke->findClass("QVariant").index) {
                    continue;
                    // If the value isn't a Qt::Variant, then try and construct
                    // a Qt::Variant from it
                    // TODO: I have no idea how to do this.
                    /*
                    value = rb_funcall(qvariant_class, rb_intern("fromValue"), 1, value);
                    if (value == Qnil) {
                        continue;
                    }
                    o = value_obj_info(value);
                    */
                }

                (*chash)[QString(key)] = (QVariant)*(QVariant*)o->ptr;
            }
            delete keylen;

            m->item().s_voidp = chash;
            m->next();

            if(m->cleanup())
                delete chash;
        }
        break;
        case Marshall::ToSV: {
            QHash<QString,QVariant> *chash = (QHash<QString,QVariant>*)m->item().s_voidp;
            if(!chash) {
                sv_setsv(m->var(), &PL_sv_undef);
                break;
            }

            HV *hv = newHV();
            SV *sv = newRV_noinc( (SV*)hv );

            QHash<QString,QVariant>::Iterator it;
            for (it = chash->begin(); it != chash->end(); ++it) {
                void *p = new QVariant(it.value());
                SV *obj = getPointerObject(p);

                if ( !obj || !SvOK(obj) ) {
                    // We know what module QVariant is defined in.  Hard-code
                    // that smoke object
                    smokeperl_object  * o = alloc_smokeperl_object(	true, 
                                                                    qtcore_Smoke,
                                                                    qtcore_Smoke->idClass("QVariant").index, 
                                                                    p );
                    obj = set_obj_info(" Qt::Variant", o);
                }

                SV *key = perlstringFromQString((QString*)&(it.key()));
                STRLEN keylen = it.key().size();
                hv_store( hv, SvPV_nolen(key), keylen, obj, 0 );
            }

            sv_setsv(m->var(), sv);
            m->next();

            if(m->cleanup())
                delete chash;
        }
        break;
        default:
            m->unsupported();
        break;
    }
}

void marshall_QRgb_array(Marshall *m) {
    UNTESTED_HANDLER("marshall_QRgb_array");
    switch(m->action()) {
        case Marshall::FromSV: {
            SV *listref = m->var();
            if ( !SvOK( listref ) && !SvROK( listref ) ) {
                m->item().s_voidp = 0;
                break;
            }

            AV *list = (AV*)SvRV( listref );

            int count = av_len(list) + 1;
            // Why +2?
            QRgb *rgb = new QRgb[count + 2];
            for( long i = 0; i < count; ++i) {
                SV **item = av_fetch(list, i, 0);
                if( !item && !SvIOK( *item ) ) {
                    rgb[i] = 0;
                    continue;
                }

                rgb[i] = SvUV(*item);
            }

            m->item().s_voidp = rgb;
            m->next();
        }
        break;
        case Marshall::ToSV:
            // Implement this with a tied array or something
        default:
            m->unsupported();
        break;
    }
}

void marshall_QPairQStringQStringList(Marshall *m) {
    UNTESTED_HANDLER("marshall_QPairQStringQStringList");
    switch(m->action()) {
        case Marshall::FromSV: {
            SV *listref = m->var();
            if ( !SvOK( listref ) && !SvROK( listref ) ) {
                m->item().s_voidp = 0;
                break;
            }

            AV *list = (AV*)SvRV( listref );

            int count = av_len(list) + 1;
            QList<QPair<QString,QString> > * pairlist = new QList<QPair<QString,QString> >();

            for (long i = 0; i < count; ++i) {
                AV **item = (AV**)av_fetch(list, i, 0);
                if( !item || !SvROK( *item ) || SvTYPE(*item) != SVt_PVAV ) {
                    continue;
                }
                AV *perlpair = (AV*)SvRV(*item);
                if ( av_len(perlpair) != 2 ) {
                    continue;
                }
                SV **s1 = av_fetch(*item, 0, 0);
                SV **s2 = av_fetch(*item, 1, 0);
                if( !s1 || !s2 || !SvOK( *s1 ) || !SvOK( *s2 ) ) {
                    continue;
                }
                QPair<QString,QString> * qpair = new QPair<QString,QString>(*(qstringFromPerlString(*s1)),*(qstringFromPerlString(*s2)));
                pairlist->append(*qpair);
            }

            m->item().s_voidp = pairlist;
            m->next();

            if (m->cleanup()) {
                delete pairlist;
            }

        }
        break;

        case Marshall::ToSV: {
            QList<QPair<QString,QString> > *pairlist = static_cast<QList<QPair<QString,QString> > * >(m->item().s_voidp);
            if (pairlist == 0) {
                sv_setsv(m->var(), &PL_sv_undef);
                break;
            }

            AV *av = newAV();

            for (QList<QPair<QString,QString> >::Iterator it = pairlist->begin(); it != pairlist->end(); ++it) {
                QPair<QString,QString> * pair = &(*it);
                SV *rv1 = perlstringFromQString(&(pair->first));
                SV *rv2 = perlstringFromQString(&(pair->second));
                AV *pv = newAV();
                av_push(pv, rv1);
                av_push(pv, rv2);
                av_push(av, newRV_noinc((SV*)pv) );
            }

            sv_setsv( m->var(), newRV_noinc( (SV*)av ) );

            if (m->cleanup()) {
                delete pairlist;
            }

        }
        break;
        default:
            m->unsupported();
        break;
    }
}

void marshall_QPairqrealQColor(Marshall *m) {
    UNTESTED_HANDLER("marshall_QPairqrealQColor");
    switch(m->action()) {
        case Marshall::FromSV: {
            SV *listref = m->var();
            if( !listref || !SvROK( listref ) || SvTYPE(listref) != SVt_PVAV ) {
                m->item().s_voidp = 0;
                break;
            }
            AV *list = (AV*)SvRV(listref);
            if ( av_len(list) != 2 ) {
                m->item().s_voidp = 0;
                break;
            }

            qreal real;
            SV **item = av_fetch(list, 0, 0);
            if ( !item || !SvOK( *item ) || SvTYPE(*item) != SVt_NV ) {
                real = 0;
            }
            else {
                real = SvNV(*item);
            }

            SV **item2 = av_fetch(list, 1, 0);
            smokeperl_object *o;

            if ( !item2 || !SvOK( *item2 ) || SvTYPE(*item2) != SVt_PVMG ) {
                // Error
            }
            else {
                o = sv_obj_info(*item2);
                if (o == 0 || o->ptr == 0) {
                    m->item().s_voidp = 0;
                    break;
                }
            }

            // This should check to make sure o->ptr can be a QColor

            QPair<qreal,QColor> * qpair = new QPair<qreal,QColor>(real, *((QColor *) o->ptr));
            m->item().s_voidp = qpair;
            m->next();

            if (m->cleanup()) {
                delete qpair;
            }
        }
        break;
        case Marshall::ToSV: {
            QPair<qreal,QColor> * qpair = static_cast<QPair<qreal,QColor> * >(m->item().s_voidp); 
            if (qpair == 0) {
                sv_setsv(m->var(), &PL_sv_undef);
                break;
            }

            SV *rv1 = newSVnv(qpair->first);

            void *p = (void *) &(qpair->second);
            SV *rv2 = getPointerObject(p);
            if ( !SvOK( rv2 ) ) {
                smokeperl_object * o = alloc_smokeperl_object( true, 
                    m->smoke(), 
                    m->smoke()->idClass("QColor").index, 
                    p );
                rv2 = set_obj_info("Qt::Color", o);
            }

            AV *av = newAV();
            av_push(av, rv1);
            av_push(av, rv2);
            sv_setsv(m->var(), newRV_noinc((SV*)av));

            if (m->cleanup()) {
                // This is commented out in QtRuby.
                //delete qpair;
            }
        }
        break;
        default:
            m->unsupported();
            break;
    }
}

void marshall_QPairintint(Marshall *m) {
    UNTESTED_HANDLER("marshall_QPairintint");
    switch(m->action()) {
        case Marshall::FromSV: {
            SV *listref = m->var();
            if( !listref || !SvROK( listref ) || SvTYPE(listref) != SVt_PVAV ) {
                m->item().s_voidp = 0;
                break;
            }
            AV *list = (AV*)SvRV(listref);
            if ( av_len(list) != 2 ) {
                m->item().s_voidp = 0;
                break;
            }

            int int0;
            int int1;
            SV **item = av_fetch(list, 0, 0);
            if ( !item || !SvOK( *item ) || SvTYPE(*item) != SVt_IV ) {
                int0 = 0;
            }
            else {
                int0 = SvIV(*item);
            }

            item = av_fetch(list, 1, 0);

            if ( !item || !SvOK( *item ) || SvTYPE(*item) != SVt_IV ) {
                int1 = 0;
            }
            else {
                int1 = SvIV(*item);
            }

            QPair<int,int> * qpair = new QPair<int,int>(int0,int1);
            m->item().s_voidp = qpair;
            m->next();

            if (m->cleanup()) {
                delete qpair;
            }
        }
        break;
        case Marshall::ToSV:
        default:
            m->unsupported();
        break;
    }
}

void marshall_voidP_array(Marshall *m) {
    // This is a hack that should be removed.
    switch(m->action()) {
        case Marshall::FromSV:
        {
            m->unsupported();
        }
        break;
        case Marshall::ToSV:
        {
            // This is ghetto.
            void* cxxptr = m->item().s_voidp;

            smokeperl_object* o = alloc_smokeperl_object(
                false,
                m->smoke(),
                0,
                cxxptr );
            SV *var = sv_2mortal( set_obj_info( "voidparray", o ) );

            SvSetMagicSV(m->var(), var);
        }
        break;
        default:
            m->unsupported();
        break;
    }
}

#if QT_VERSION >= 0x40300
void marshall_QMultiMapQStringQString(Marshall *m) {
    switch(m->action()) {
        case Marshall::ToSV: {
            QMultiMap<QString,QString> *map = (QMultiMap<QString,QString>*)m->item().s_voidp;
            if(!map) {
                sv_setsv(m->var(), &PL_sv_undef);
                break;
            }

            HV *hv = newHV();
            SV *sv = newRV_noinc( (SV*)hv );

            QMap<QString,QString>::Iterator it;
            for (it = map->begin(); it != map->end(); ++it) {
                SV *key = perlstringFromQString((QString*)&(it.key()));
                STRLEN keylen = it.key().size();
                QList<QString> values = map->values(it.key());
                AV *val = newAV();
                SV *valref = newRV_noinc( (SV*)val );
                foreach ( QString entry, values ) {
                    av_push(val, perlstringFromQString((QString*) &(it.value())));
                }
                hv_store( hv, SvPV_nolen(key), keylen, valref, 0 );
            }

            sv_setsv(m->var(), sv);
            m->next();

            if(m->cleanup())
                delete map;
        }
        break;
        default:
            m->unsupported();
        break;
    }
}
#endif

DEF_LIST_MARSHALLER( QAbstractButtonList, QList<QAbstractButton*>, QAbstractButton )
DEF_LIST_MARSHALLER( QActionGroupList, QList<QActionGroup*>, QActionGroup )
DEF_LIST_MARSHALLER( QActionList, QList<QAction*>, QAction )
DEF_LIST_MARSHALLER( QListWidgetItemList, QList<QListWidgetItem*>, QListWidgetItem )
DEF_LIST_MARSHALLER( QObjectList, QList<QObject*>, QObject )
DEF_LIST_MARSHALLER( QTableWidgetList, QList<QTableWidget*>, QTableWidget ) // !! not in Qt4_handlers
DEF_LIST_MARSHALLER( QTableWidgetItemList, QList<QTableWidgetItem*>, QTableWidgetItem )
DEF_LIST_MARSHALLER( QTextFrameList, QList<QTextFrame*>, QTextFrame )
DEF_LIST_MARSHALLER( QTreeWidgetItemList, QList<QTreeWidgetItem*>, QTreeWidgetItem )
DEF_LIST_MARSHALLER( QTreeWidgetList, QList<QTreeWidget*>, QTreeWidget ) // !! not in Qt4_handlers
DEF_LIST_MARSHALLER( QWidgetList, QList<QWidget*>, QWidget )
DEF_LIST_MARSHALLER( QWidgetPtrList, QList<QWidget*>, QWidget )

#if QT_VERSION >= 0x40200
DEF_LIST_MARSHALLER( QGraphicsItemList, QList<QGraphicsItem*>, QGraphicsItem )
DEF_LIST_MARSHALLER( QStandardItemList, QList<QStandardItem*>, QStandardItem )
DEF_LIST_MARSHALLER( QUndoStackList, QList<QUndoStack*>, QUndoStack )
#endif

#if QT_VERSION >= 0x40300
DEF_LIST_MARSHALLER( QMdiSubWindowList, QList<QMdiSubWindow*>, QMdiSubWindow )
#endif

DEF_VALUELIST_MARSHALLER( QColorVector, QVector<QColor>, QColor )
DEF_VALUELIST_MARSHALLER( QFileInfoList, QFileInfoList, QFileInfo )
DEF_VALUELIST_MARSHALLER( QHostAddressList, QList<QHostAddress>, QHostAddress )
DEF_VALUELIST_MARSHALLER( QImageTextKeyLangList, QList<QImageTextKeyLang>, QImageTextKeyLang )
DEF_VALUELIST_MARSHALLER( QKeySequenceList, QList<QKeySequence>, QKeySequence )
DEF_VALUELIST_MARSHALLER( QLineFVector, QVector<QLineF>, QLineF )
DEF_VALUELIST_MARSHALLER( QLineVector, QVector<QLine>, QLine )
DEF_VALUELIST_MARSHALLER( QModelIndexList, QList<QModelIndex>, QModelIndex )
DEF_VALUELIST_MARSHALLER( QNetworkAddressEntryList, QList<QNetworkAddressEntry>, QNetworkAddressEntry )
DEF_VALUELIST_MARSHALLER( QNetworkInterfaceList, QList<QNetworkInterface>, QNetworkInterface )
DEF_VALUELIST_MARSHALLER( QPixmapList, QList<QPixmap>, QPixmap )
DEF_VALUELIST_MARSHALLER( QPointFVector, QVector<QPointF>, QPointF )
DEF_VALUELIST_MARSHALLER( QPointVector, QVector<QPoint>, QPoint )
DEF_VALUELIST_MARSHALLER( QPolygonFList, QList<QPolygonF>, QPolygonF )
DEF_VALUELIST_MARSHALLER( QRectFList, QList<QRectF>, QRectF )
DEF_VALUELIST_MARSHALLER( QRectFVector, QVector<QRectF>, QRectF )
DEF_VALUELIST_MARSHALLER( QRectVector, QVector<QRect>, QRect )
DEF_VALUELIST_MARSHALLER( QRgbVector, QVector<QRgb>, QRgb )
DEF_VALUELIST_MARSHALLER( QTableWidgetSelectionRangeList, QList<QTableWidgetSelectionRange>, QTableWidgetSelectionRange )
DEF_VALUELIST_MARSHALLER( QTextBlockList, QList<QTextBlock>, QTextBlock )
DEF_VALUELIST_MARSHALLER( QTextEditExtraSelectionsList, QList<QTextEdit::ExtraSelection>, QTextEdit::ExtraSelection )
DEF_VALUELIST_MARSHALLER( QTextFormatVector, QVector<QTextFormat>, QTextFormat )
DEF_VALUELIST_MARSHALLER( QTextLayoutFormatRangeList, QList<QTextLayout::FormatRange>, QTextLayout::FormatRange)
DEF_VALUELIST_MARSHALLER( QTextLengthVector, QVector<QTextLength>, QTextLength )
DEF_VALUELIST_MARSHALLER( QUrlList, QList<QUrl>, QUrl )
DEF_VALUELIST_MARSHALLER( QVariantList, QList<QVariant>, QVariant )
DEF_VALUELIST_MARSHALLER( QVariantVector, QVector<QVariant>, QVariant )

#if QT_VERSION >= 0x40300
DEF_VALUELIST_MARSHALLER( QSslCertificateList, QList<QSslCertificate>, QSslCertificate )
DEF_VALUELIST_MARSHALLER( QSslCipherList, QList<QSslCipher>, QSslCipher )
DEF_VALUELIST_MARSHALLER( QSslErrorList, QList<QSslError>, QSslError )
DEF_VALUELIST_MARSHALLER( QXmlStreamEntityDeclarations, QVector<QXmlStreamEntityDeclaration>, QXmlStreamEntityDeclaration )
DEF_VALUELIST_MARSHALLER( QXmlStreamNamespaceDeclarations, QVector<QXmlStreamNamespaceDeclaration>, QXmlStreamNamespaceDeclaration )
DEF_VALUELIST_MARSHALLER( QXmlStreamNotationDeclarations, QVector<QXmlStreamNotationDeclaration>, QXmlStreamNotationDeclaration )
#endif

#if QT_VERSION >= 0x40400
DEF_VALUELIST_MARSHALLER( QNetworkCookieList, QList<QNetworkCookie>, QNetworkCookie )
DEF_VALUELIST_MARSHALLER( QPrinterInfoList, QList<QPrinterInfo>, QPrinterInfo )
#endif

Q_DECL_EXPORT TypeHandler Qt4_handlers[] = {
    { "bool*", marshall_it<bool *> },
    { "bool&", marshall_it<bool *> },
    { "char**", marshall_charP_array },
    { "char*",marshall_it<char *> },
    { "char*&",marshall_it<char *&> },
    { "DOM::DOMTimeStamp", marshall_it<long long> },
    { "double*", marshall_doubleR },
    { "double&", marshall_doubleR },
    { "int*", marshall_it<int *> },
    { "int&", marshall_it<int *> },
    { "KIO::filesize_t", marshall_it<long long> },
    { "long long", marshall_it<long long> },
    { "long long&", marshall_it<long long> },
    { "long long int", marshall_it<long long> },
    { "long long int&", marshall_it<long long> },
    { "QList<QFileInfo>", marshall_QFileInfoList },
    { "QFileInfoList", marshall_QFileInfoList },
    { "QGradiantStops", marshall_QPairqrealQColor },
    { "QGradiantStops&", marshall_QPairqrealQColor },
    { "unsigned int&", marshall_it<unsigned int *> },
    { "quint32&", marshall_it<unsigned int *> },
    { "uint&", marshall_it<unsigned int *> },
    { "qint32&", marshall_it<int *> },
    { "short&", marshall_it<short *> },
    { "short&", marshall_it<short *> },
    { "qint16&", marshall_it<short *> },
    { "unsigned short&", marshall_it<unsigned short *> },
    { "ushort&", marshall_it<unsigned short *> },
    { "quint16&", marshall_it<unsigned short *> },
    { "qint64", marshall_it<long long> },
    { "qint64&", marshall_it<long long> },
    { "QHash<QString,QVariant>", marshall_QHashQStringQVariant },
    { "const QHash<QString,QVariant>&", marshall_QHashQStringQVariant },
    { "QList<const char*>", marshall_QListCharStar },
    { "QList<int>", marshall_QListInt },
    { "QList<int>&", marshall_QListInt },
    { "QList<uint>", marshall_QListUInt },
    { "QList<uint>&", marshall_QListUInt },
    { "QList<QAbstractButton*>", marshall_QAbstractButtonList },
    { "QList<QActionGroup*>", marshall_QActionGroupList },
    { "QList<QAction*>", marshall_QActionList },
    { "QList<QAction*>&", marshall_QActionList },
    { "QList<QByteArray>", marshall_QByteArrayList },
    { "QList<QByteArray>*", marshall_QByteArrayList },
    { "QList<QByteArray>&", marshall_QByteArrayList },
    { "QList<QHostAddress>", marshall_QHostAddressList },
    { "QList<QHostAddress>&", marshall_QHostAddressList },
    { "QList<QImageTextKeyLang>", marshall_QImageTextKeyLangList },
    { "QList<QKeySequence>", marshall_QKeySequenceList },
    { "QList<QKeySequence>&", marshall_QKeySequenceList },
    { "QList<QLocale::Country>", marshall_QListLocaleCountry },
    { "QList<QListWidgetItem*>", marshall_QListWidgetItemList },
    { "QList<QListWidgetItem*>&", marshall_QListWidgetItemList },
    { "QList<QModelIndex>", marshall_QModelIndexList },
    { "QList<QModelIndex>&", marshall_QModelIndexList },
    { "QList<QNetworkAddressEntry>", marshall_QNetworkAddressEntryList },
    { "QList<QNetworkInterface>", marshall_QNetworkInterfaceList },
    { "QList<QPair<QString,QString> >", marshall_QPairQStringQStringList },
    { "QList<QPair<QString,QString> >&", marshall_QPairQStringQStringList },
    { "QList<QPixmap>", marshall_QPixmapList },
    { "QList<QPolygonF>", marshall_QPolygonFList },
    { "QList<QRectF>", marshall_QRectFList },
    { "QList<QRectF>&", marshall_QRectFList },
    { "QList<qreal>", marshall_QListqreal },
    { "QList<double>", marshall_QListqreal },
    { "QwtValueList", marshall_QListqreal },
    { "QwtValueList&", marshall_QListqreal },
    { "QList<double>&", marshall_QListqreal },
    { "QList<QObject*>", marshall_QObjectList },
    { "QList<QObject*>&", marshall_QObjectList },
    { "QList<QTableWidgetItem*>", marshall_QTableWidgetItemList },
    { "QList<QTableWidgetItem*>&", marshall_QTableWidgetItemList },
    { "QList<QTableWidgetSelectionRange>", marshall_QTableWidgetSelectionRangeList },
    { "QList<QTextBlock>", marshall_QTextBlockList },
    { "QList<QTextEdit::ExtraSelection>", marshall_QTextEditExtraSelectionsList },
    { "QList<QTextEdit::ExtraSelection>&", marshall_QTextEditExtraSelectionsList },
    { "QList<QTextFrame*>", marshall_QTextFrameList },
    { "QList<QTextLayout::FormatRange>", marshall_QTextLayoutFormatRangeList },
    { "QList<QTextLayout::FormatRange>&", marshall_QTextLayoutFormatRangeList },
    { "QList<QTreeWidgetItem*>", marshall_QTreeWidgetItemList },
    { "QList<QTreeWidgetItem*>&", marshall_QTreeWidgetItemList },
    { "QList<QUndoStack*>", marshall_QUndoStackList },
    { "QList<QUndoStack*>&", marshall_QUndoStackList },
    { "QList<QUrl>", marshall_QUrlList },
    { "QList<QUrl>&", marshall_QUrlList },
    { "QList<QVariant>", marshall_QVariantList },
    { "QList<QVariant>&", marshall_QVariantList },
    { "QList<QWidget*>", marshall_QWidgetPtrList },
    { "QList<QWidget*>&", marshall_QWidgetPtrList },
    { "qlonglong", marshall_it<long long> },
    { "qlonglong&", marshall_it<long long> },
    //{ "QMap<int,QVariant>", marshall_QMapintQVariant },
    { "QMap<int,QVariant>", marshall_QMapIntQVariant },
    { "QMap<int,QVariant>&", marshall_QMapIntQVariant },
    { "QMap<QString,QString>", marshall_QMapQStringQString },
    { "QMap<QString,QString>&", marshall_QMapQStringQString },
    { "QMap<QString,QUrl>", marshall_QMapQStringQUrl },
    { "QMap<QString,QVariant>", marshall_QMapQStringQVariant },
    { "QMap<QString,QVariant>&", marshall_QMapQStringQVariant },
    { "QVariantMap", marshall_QMapQStringQVariant },
    { "QVariantMap&", marshall_QMapQStringQVariant },
    { "QModelIndexList", marshall_QModelIndexList },
    { "QModelIndexList&", marshall_QModelIndexList },
    { "QObjectList", marshall_QObjectList },
    { "QObjectList&", marshall_QObjectList },
    { "QPair<int,int>&", marshall_QPairintint },
    { "Q_PID", marshall_it<Q_PID> },
    { "qreal*", marshall_doubleR },
    { "qreal&", marshall_doubleR },
    { "QRgb*", marshall_QRgb_array },
    { "QStringList", marshall_QStringList },
    { "QStringList*", marshall_QStringList },
    { "QStringList&", marshall_QStringList },
    { "QString", marshall_QString },
    { "QString*", marshall_QString },
    { "QString&", marshall_QString },
    { "QByteArray", marshall_QByteArray },
    { "QByteArray*", marshall_QByteArray },
    { "QByteArray&", marshall_QByteArray },
    { "quint64", marshall_it<unsigned long long> },
    { "quint64&", marshall_it<unsigned long long> },
    { "qulonglong", marshall_it<unsigned long long> },
    { "qulonglong&", marshall_it<unsigned long long> },
    { "QVariantList&", marshall_QVariantList },
    { "QVector<int>", marshall_QVectorint },
    { "QVector<int>&", marshall_QVectorint },
    { "QVector<QColor>", marshall_QColorVector },
    { "QVector<QColor>&", marshall_QColorVector },
    { "QVector<QLineF>", marshall_QLineFVector },
    { "QVector<QLineF>&", marshall_QLineFVector },
    { "QVector<QLine>", marshall_QLineVector },
    { "QVector<QLine>&", marshall_QLineVector },
    { "QVector<QPointF>", marshall_QPointFVector },
    { "QVector<QPointF>&", marshall_QPointFVector },
    { "QVector<QPoint>", marshall_QPointVector },
    { "QVector<QPoint>&", marshall_QPointVector },
    { "QVector<qreal>", marshall_QVectorqreal },
    { "QVector<qreal>&", marshall_QVectorqreal },
    { "QVector<QRectF>", marshall_QRectFVector },
    { "QVector<QRectF>&", marshall_QRectFVector },
    { "QVector<QRect>", marshall_QRectVector },
    { "QVector<QRect>&", marshall_QRectVector },
    { "QVector<QRgb>", marshall_QRgbVector },
    { "QVector<QRgb>&", marshall_QRgbVector },
    { "QVector<QTextFormat>", marshall_QTextFormatVector },
    { "QVector<QTextFormat>&", marshall_QTextFormatVector },
    { "QVector<QTextLength>", marshall_QTextLengthVector },
    { "QVector<QTextLength>&", marshall_QTextLengthVector },
    { "QVector<QVariant>", marshall_QVariantVector },
    { "QVector<QVariant>&", marshall_QVariantVector },
    { "QVector<QPair<double,QColor> >&", marshall_QVectorQPairDoubleQColor },
    { "QVector<QPair<double,QColor> >", marshall_QVectorQPairDoubleQColor },
    { "QWidgetList", marshall_QWidgetList },
    { "QWidgetList&", marshall_QWidgetList },
    { "QwtArray<double>", marshall_QVectorqreal },
    { "QwtArray<double>&", marshall_QVectorqreal },
    { "QwtArray<int>", marshall_QVectorint },
    { "QwtArray<int>&", marshall_QVectorint },
    { "signed int&", marshall_it<int *> },
    { "uchar*", marshall_it<unsigned char *> },
    { "unsigned char*", marshall_it<unsigned char *> },
    { "unsigned long long int", marshall_it<long long> },
    { "unsigned long long int&", marshall_it<long long> },
    { "void", marshall_void },
    { "void**", marshall_voidP_array },
    { "WId", marshall_it<WId> },
#if QT_VERSION >= 0x40200
    { "QList<QGraphicsItem*>", marshall_QGraphicsItemList },
    { "QList<QGraphicsItem*>&", marshall_QGraphicsItemList },
    { "QList<QStandardItem*>", marshall_QStandardItemList },
    { "QList<QStandardItem*>&", marshall_QStandardItemList },
    { "QList<QUndoStack*>", marshall_QUndoStackList },
    { "QList<QUndoStack*>&", marshall_QUndoStackList },
#endif
#if QT_VERSION >= 0x40300
    { "QList<QMdiSubWindow*>", marshall_QMdiSubWindowList },
    { "QList<QSslCertificate>", marshall_QSslCertificateList },
    { "QList<QSslCertificate>&", marshall_QSslCertificateList },
    { "QList<QSslCipher>", marshall_QSslCipherList },
    { "QList<QSslCipher>&", marshall_QSslCipherList },
    { "QList<QSslError>", marshall_QSslErrorList },
    { "QList<QSslError>&", marshall_QSslErrorList },
    { "QXmlStreamEntityDeclarations", marshall_QXmlStreamEntityDeclarations },
    { "QXmlStreamNamespaceDeclarations", marshall_QXmlStreamNamespaceDeclarations },
    { "QXmlStreamNotationDeclarations", marshall_QXmlStreamNotationDeclarations },
    { "QMultiMap<QString,QString>", marshall_QMultiMapQStringQString },
    { "QMultiMap<QString,QString>&", marshall_QMultiMapQStringQString },
#endif
#if QT_VERSION >= 0x040400
    { "QList<QNetworkCookie>", marshall_QNetworkCookieList },
    { "QList<QNetworkCookie>&", marshall_QNetworkCookieList },
    { "QList<QPrinterInfo>", marshall_QPrinterInfoList },
#endif
    { 0, 0 }
};

Q_DECL_EXPORT void install_handlers(TypeHandler *handler) {
    if(!type_handlers) type_handlers = newHV();
    while(handler->name) {
        hv_store(type_handlers, handler->name, strlen(handler->name), newSViv((IV)handler), 0);
        handler++;
    }
}

Marshall::HandlerFn getMarshallFn(const SmokeType &type) {
    if(type.elem()) // If it's not t_voidp
        return marshall_basetype;
    if(!type.name())
        return marshall_void;

    U32 len = strlen(type.name());
    //fprintf( stderr, "Request to marshall %s\n", type.name() );
    SV **svp = hv_fetch(type_handlers, type.name(), len, 0);

    //                           len > strlen("const ")
    if(!svp && type.isConst() && len > 6) {
        // Look for a type name that doesn't include const.
        svp = hv_fetch(type_handlers, type.name() + 6, len - 6, 0);
    }

    if(svp) {
        TypeHandler *h = (TypeHandler*)SvIV(*svp);
        return h->fn;
    }

    return marshall_unknown;
}
