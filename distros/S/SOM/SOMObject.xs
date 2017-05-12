#define INCL_DOSERRORS
#define INCL_WINERRORS
#include "os2.h"

#include <somcls.h>
#include <somobj.h>

/* In SOM 'any' is struct */
#define any Perlish_any

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "common_init.h"

/* We use xsubpp from 5.005_64, and it puts some unexpected macros */
#ifdef CUSTOM_XSUBPP
#  define aTHX_
#endif

#undef any
#define boolean bool
#define octet	unsigned char

MODULE = SOMObject		PACKAGE = SOMObject::IDL

# These methods were copied from SOMOBJ.idl with obvious edits
# // => ##, in => IN etc, and the leading "IN SOMObject fromObj, " was added.
# (also ", )" to ")")...
# SOMObject => "SOMObject *"
# SOMClass => "SOMClass *"
# Comment out va_list stuff
# Prepend "_"

void _somDefaultInit(IN SOMObject * self, IN som3InitCtrl *ctrl);
## A default initializer for a SOM object. Passing a null ctrl
## indicates to the receiver that its class is the class of the
## object being initialized, whereby the initializer will determine
## an appropriate control structure.

void _somDestruct(IN SOMObject * self, IN octet doFree, IN som3DestructCtrl *ctrl);
## The default destructor for a SOM object. A nonzero <doFree>
## indicates that the object storage should be freed by the
## object's class (IN SOMObject * self, via somDeallocate) after uninitialization.
## As with somDefaultInit, a null ctrl can be passed.

void _somDefaultCopyInit(IN SOMObject * self, IN som3InitCtrl *ctrl, IN SOMObject * fromObj);
## A default copy constructor. Use this to make copies of objects for
## calling methods with "by-value" argument semantics.

SOMObject * _somDefaultAssign(IN SOMObject * self, IN som3AssignCtrl *ctrl, IN SOMObject * fromObj);
## A default assignment operator. Use this to "assign" the state of one
## object to another.

void _somDefaultConstCopyInit(IN SOMObject * self, IN som3InitCtrl *ctrl, IN SOMObject * fromObj);
## A default copy constructor that uses a const fromObj.

void _somDefaultVCopyInit(IN SOMObject * self, IN som3InitCtrl *ctrl, IN SOMObject * fromObj);
## A default copy constructor that uses a volatile fromObj.

void _somDefaultConstVCopyInit(IN SOMObject * self, IN som3InitCtrl *ctrl, IN SOMObject * fromObj);
## A default copy constructor that uses a const volatile fromObj.

SOMObject * _somDefaultConstAssign(IN SOMObject * self, IN som3AssignCtrl *ctrl, IN SOMObject * fromObj);
## A default assignment operator that uses a const fromObj.

SOMObject * _somDefaultVAssign(IN SOMObject * self, IN som3AssignCtrl *ctrl, IN SOMObject * fromObj);
## A default assignment operator that uses a volatile fromObj.

SOMObject * _somDefaultConstVAssign(IN SOMObject * self, IN som3AssignCtrl *ctrl, IN SOMObject * fromObj);
## A default assignment operator that uses a const volatile fromObj.

void _somInit(IN SOMObject * self);
## Obsolete but still supported. Override somDefaultInit instead of somInit.

void _somFree(IN SOMObject * self);
## Use as directed by framework implementations.

void _somUninit(IN SOMObject * self);
## Obsolete but still supported. Override somDestruct instead of somUninit.

SOMClass * _somGetClass(IN SOMObject * self);
## Return the receiver's class.

string _somGetClassName(IN SOMObject * self);
## Return the name of the receiver's class.

long _somGetSize(IN SOMObject * self);
## Return the size of the receiver.

boolean _somIsA(IN SOMObject * self, IN SOMClass * aClassObj);
## Returns 1 (IN SOMObject * self, true) if the receiver responds to methods
## introduced by <aClassObj>, and 0 (IN SOMObject * self, false) otherwise.

boolean _somIsInstanceOf(IN SOMObject * self, IN SOMClass * aClassObj);
## Returns 1 (IN SOMObject * self, true) if the receiver is an instance of
## <aClassObj> and 0 (IN SOMObject * self, false) otherwise.

boolean _somRespondsTo(IN SOMObject * self, IN somId mId);
## Returns 1 (IN SOMObject * self, true) if the indicated method can be invoked
## on the receiver and 0 (IN SOMObject * self, false) otherwise.

#boolean _somDispatch(IN SOMObject * self, OUTLIST somToken retValue, IN somId methodId, IN va_list ap);
## This method provides a generic, class-specific dispatch mechanism.
## It accepts as input <retValue> a pointer to the memory area to be
## loaded with the result of dispatching the method indicated by
## <methodId> using the arguments IN <ap>. <ap> contains the object
## on which the method is to be invoked as the first argument.

#boolean _somClassDispatch(IN SOMObject * self, IN SOMClass * clsObj, OUTLIST somToken retValue, IN somId methodId, IN va_list ap);
## Like somDispatch, but method resolution for static methods is done
## according to the clsObj instance method table.

boolean _somCastObj(IN SOMObject * self, IN SOMClass * cls);
## cast the receiving object to cls (IN SOMObject * self, which must be an ancestor of the
## objects true class. Returns true on success.

boolean _somResetObj(IN SOMObject * self);
## reset an object to its true class. Returns true always.


#void _somDispatchV(IN SOMObject * self, IN somId methodId, IN somId descriptor, IN va_list ap);
## Obsolete. Use somDispatch instead.

#long _somDispatchL(IN SOMObject * self, IN somId methodId, IN somId descriptor, IN va_list ap);
## Obsolete. Use somDispatch instead.

#void* _somDispatchA(IN SOMObject * self, IN somId methodId, IN somId descriptor, IN va_list ap);
## Obsolete. Use somDispatch instead.

#double _somDispatchD(IN SOMObject * self, IN somId methodId, IN somId descriptor, IN va_list ap);
## Obsolete. Use somDispatch instead.

SOMObject * _somPrintSelf(IN SOMObject * self);
## Uses <SOMOutCharRoutine> to write a brief string with identifying
## information about this object.  The default implementation just gives
## the object's class name and its address IN memory.
## <self> is returned.

void _somDumpSelf(IN SOMObject * self, IN long level);
## Uses <SOMOutCharRoutine> to write a detailed description of this object
## and its current state.
#
## <level> indicates the nesting level for describing compound objects
## it must be greater than or equal to zero.  All lines IN the
## description will be preceeded by <2*level> spaces.
#
## This routine only actually writes the data that concerns the object
## as a whole, such as class, and uses <somDumpSelfInt> to describe
## the object's current state.  This approach allows readable
## descriptions of compound objects to be constructed.
#
## Generally it is not necessary to override this method, if it is
## overriden it generally must be completely replaced.

void _somDumpSelfInt(IN SOMObject * self, IN long level);
## Uses <SOMOutCharRoutine> to write IN the current state of this object.
## Generally this method will need to be overridden.  When overriding
## it, begIN by calling the parent class form of this method and then
## write IN a description of your class's instance data. This will
## result IN a description of all the object's instance data going
## from its root ancestor class to its specific class.
