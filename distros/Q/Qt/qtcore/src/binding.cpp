#include <QObject>
#include <QRegExp>

#include "marshall_types.h"
#include "binding.h"
#include "QtCore4.h"
#include "smokeperl.h"

extern "C" {
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
}

extern Q_DECL_EXPORT Smoke *qtcore_Smoke;
extern Q_DECL_EXPORT int do_debug;
extern Q_DECL_EXPORT QList<Smoke*> smokeList;

namespace PerlQt4 {

Binding::Binding() : SmokeBinding(0) {};
Binding::Binding(Smoke *s) : SmokeBinding(s) {};

void Binding::deleted(Smoke::Index /*classId*/, void *ptr) {
    SV* obj = getPointerObject(ptr);
    smokeperl_object* o = sv_obj_info(obj);
    if (!o || !o->ptr) {
        return;
    }
    unmapPointer( o, o->classId, 0 );

    // If it's a QObject, unmap all it's children too.
    if ( isDerivedFrom( o->smoke, o->classId, o->smoke->idClass("QObject").index, 0 ) >= 0 ) {
        QObject* objptr = (QObject*)o->smoke->cast(
            ptr,
            o->classId,
            o->smoke->idClass("QObject").index
        );
        QObjectList mychildren = objptr->children();
        foreach( QObject* child, mychildren ) {
            deleted( 0, child );
        }
    }

    o->ptr = 0;
}

bool Binding::callMethod(Smoke::Index method, void *ptr, Smoke::Stack args, bool isAbstract) {
    // If the Qt process forked, we want to make sure we can see the
    // interpreter
    PERL_SET_CONTEXT(PL_curinterp);


    // Look for a perl sv associated with this pointer
    SV *obj = getPointerObject(ptr);
    smokeperl_object *o = sv_obj_info(obj);

    // Didn't find one
    if(!o) {
#ifdef PERLQTDEBUG
        if(!PL_dirty && (do_debug && (do_debug & qtdb_virtual) && (do_debug & qtdb_verbose)))// If not in global destruction
            fprintf(stderr, "Cannot find object for virtual method\n");
#endif
        if ( isAbstract ) {
            Smoke::Method methodobj = o->smoke->methods[method];
            croak( "%s: %s::%s", "Unimplemented pure virtual method called",
                o->smoke->classes[methodobj.classId].className, o->smoke->methodNames[methodobj.name] );
        }
        return false;
    }

#ifdef PERLQTDEBUG
    if( do_debug && (do_debug & qtdb_virtual) && (do_debug & qtdb_verbose)){
        Smoke::Method methodobj = o->smoke->methods[method];
        fprintf( stderr, "Looking for virtual method override for %p->%s::%s()\n",
            ptr, o->smoke->classes[methodobj.classId].className, o->smoke->methodNames[methodobj.name] );
    }
#endif

    // Now find the stash for this perl object
    HV *stash = SvSTASH(SvRV(obj));
    if(*HvNAME(stash) == ' ') // if withObject, look for a diff stash
        stash = gv_stashpv(HvNAME(stash) + 1, TRUE);

    // Get the name of the method being called
    const char *methodname = smoke->methodNames[smoke->methods[method].name];
    // Look up the autoload subroutine for that method
    GV *gv = gv_fetchmethod_autoload(stash, methodname, 0);
    // Found no autoload function
    if(!gv) {
        if ( isAbstract ) {
            Smoke::Method methodobj = o->smoke->methods[method];
            croak( "%s: %s::%s", "Unimplemented pure virtual method called",
                o->smoke->classes[methodobj.classId].className, o->smoke->methodNames[methodobj.name] );
        }
        return false;
    }

    // If this virtual method call came from a Perl method, and '::SUPER' is in
    // that method name, we need to check to make sure that the method we're
    // about to call isn't the same method we just came from.  Otherwise we'd
    // end up in an infinite loop.
    SV* autoload = get_sv( "Qt::AutoLoad::AUTOLOAD", TRUE );
    char* srcpackage = SvPV_nolen( autoload );
    char* srcmethod = srcpackage + strlen(srcpackage)+2;
    static QRegExp rx("::SUPER$");
    int index = rx.indexIn( srcpackage );
    if ( index >= 0 ) {
        srcpackage[index] = 0;
        if ( qstrcmp( HvNAME(stash), srcpackage ) == 0 &&
            qstrcmp( methodname, srcmethod ) == 0 ) {
            return false;
        }
    }


#ifdef PERLQTDEBUG
    if( do_debug && ( do_debug & qtdb_virtual ) ) {
        fprintf(stderr, "In Virtual override for %s, called from %s %s\n", methodname, srcpackage, srcmethod);
    }
#endif

    VirtualMethodCall call(smoke, method, args, obj, gv);
    call.next();
    return true;
}

// Args: Smoke::Index classId: the smoke classId to get the perl package name for
// Returns: char* containing the perl package name
char* Binding::className(Smoke::Index classId) {
    // Find the classId->package hash
    HV* classId2package = get_hv( "Qt::_internal::classId2package", FALSE );
    if( !classId2package ) croak( "Internal error: Unable to find classId2package hash" );

    int smokeId = smokeList.indexOf(smoke);
    // Look up the package's name in the hash
    char* key = new char[7];
    int klen = sprintf( key, "%d", (classId<<8) + smokeId );
    //*(key + klen) = 0;
    SV** packagename = hv_fetch( classId2package, key, klen, FALSE );
    delete[] key;

    if( !packagename ) {
        // Shouldn't happen
        croak( "Internal error: Unable to resolve class %s, classId %d, smoke %d, to perl package",
               smoke->classes[classId].className, classId, smokeId );
    }

    SV* retval = sv_2mortal(newSVpvf(" %s", SvPV_nolen(*packagename)));
    return SvPV_nolen(retval);
}

} // End namespace PerlQt4
