#include <stdio.h>
#include <qglobal.h>
#include <qstring.h>
#include <qapplication.h>
#include <qmetaobject.h>
#include <private/qucomextra_p.h>
#include "smoke.h"

#undef DEBUG
#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif
#ifndef __USE_POSIX
#define __USE_POSIX
#endif
#ifndef __USE_XOPEN
#define __USE_XOPEN
#endif
#ifdef _BOOL
#define HAS_BOOL
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifndef QT_VERSION_STR
#define QT_VERSION_STR "Unknown"
#endif

#undef free
#undef malloc

#include "marshall.h"
#include "perlqt.h"
#include "smokeperl.h"

#ifndef IN_BYTES
#define IN_BYTES IN_BYTE
#endif

#ifndef IN_LOCALE
#define IN_LOCALE (PL_curcop->op_private & HINT_LOCALE)
#endif

extern Smoke *qt_Smoke;
extern void init_qt_Smoke();

int do_debug = qtdb_none;

HV *pointer_map = 0;
SV *sv_qapp = 0;
int object_count = 0;
void *_current_object = 0;    // TODO: ask myself if this is stupid

bool temporary_virtual_function_success = false;

static QAsciiDict<Smoke::Index> *methcache = 0;
static QAsciiDict<Smoke::Index> *classcache = 0;

SV *sv_this = 0;

Smoke::Index _current_object_class = 0;
Smoke::Index _current_method = 0;
/*
 * Type handling by moc is simple.
 *
 * If the type name matches /^(?:const\s+)?\Q$types\E&?$/, use the
 * static_QUType, where $types is join('|', qw(bool int double char* QString);
 *
 * Everything else is passed as a pointer! There are types which aren't
 * Smoke::tf_ptr but will have to be passed as a pointer. Make sure to keep
 * track of what's what.
 */

/*
 * Simply using typeids isn't enough for signals/slots. It will be possible
 * to declare signals and slots which use arguments which can't all be
 * found in a single smoke object. Instead, we need to store smoke => typeid
 * pairs. We also need additional informatation, such as whether we're passing
 * a pointer to the union element.
 */

enum MocArgumentType {
    xmoc_ptr,
    xmoc_bool,
    xmoc_int,
    xmoc_double,
    xmoc_charstar,
    xmoc_QString
};

struct MocArgument {
    // smoke object and associated typeid
    SmokeType st;
    MocArgumentType argType;
};


extern TypeHandler Qt_handlers[];
void install_handlers(TypeHandler *);

void *sv_to_ptr(SV *sv) {  // ptr on success, null on fail
    smokeperl_object *o = sv_obj_info(sv);
    return o ? o->ptr : 0;
}

bool isQObject(Smoke *smoke, Smoke::Index classId) {
    if(!strcmp(smoke->classes[classId].className, "QObject"))
	return true;
    for(Smoke::Index *p = smoke->inheritanceList + smoke->classes[classId].parents;
	*p;
	p++) {
	if(isQObject(smoke, *p))
	    return true;
    }
    return false;
}

int isDerivedFrom(Smoke *smoke, Smoke::Index classId, Smoke::Index baseId, int cnt) {
    if(classId == baseId)
	return cnt;
    cnt++;
    for(Smoke::Index *p = smoke->inheritanceList + smoke->classes[classId].parents;
	*p;
	p++) {
	if(isDerivedFrom(smoke, *p, baseId, cnt) != -1)
	    return cnt;
    }
    return -1;
}

int isDerivedFrom(Smoke *smoke, const char *className, const char *baseClassName, int cnt) {
    if(!smoke || !className || !baseClassName)
	return -1;
    Smoke::Index idClass = smoke->idClass(className);
    Smoke::Index idBase = smoke->idClass(baseClassName);
    return isDerivedFrom(smoke, idClass, idBase, cnt);
}

SV *getPointerObject(void *ptr) {
    HV *hv = pointer_map;
    SV *keysv = newSViv((IV)ptr);
    STRLEN len;
    char *key = SvPV(keysv, len);
    SV **svp = hv_fetch(hv, key, len, 0);
    if(!svp){
	 SvREFCNT_dec(keysv);
	 return 0;
    }
    if(!SvOK(*svp)){
	hv_delete(hv, key, len, G_DISCARD);
	SvREFCNT_dec(keysv);
	return 0;
    }
    return *svp;
}

void unmapPointer(smokeperl_object *o, Smoke::Index classId, void *lastptr) {
    HV *hv = pointer_map;
    void *ptr = o->smoke->cast(o->ptr, o->classId, classId);
    if(ptr != lastptr) {
	lastptr = ptr;
	SV *keysv = newSViv((IV)ptr);
	STRLEN len;
	char *key = SvPV(keysv, len);
	if(hv_exists(hv, key, len))
	    hv_delete(hv, key, len, G_DISCARD);
	SvREFCNT_dec(keysv);
    }
    for(Smoke::Index *i = o->smoke->inheritanceList + o->smoke->classes[classId].parents;
	*i;
	i++) {
	unmapPointer(o, *i, lastptr);
    }
}

// Store pointer in pointer_map hash : "pointer_to_Qt_object" => weak ref to associated Perl object
// Recurse to store it also as casted to its parent classes.

void mapPointer(SV *obj, smokeperl_object *o, HV *hv, Smoke::Index classId, void *lastptr) {
    void *ptr = o->smoke->cast(o->ptr, o->classId, classId);
    if(ptr != lastptr) {
	lastptr = ptr;
	SV *keysv = newSViv((IV)ptr);
	STRLEN len;
	char *key = SvPV(keysv, len);
	SV *rv = newSVsv(obj);
	sv_rvweaken(rv);		// weak reference!
	hv_store(hv, key, len, rv, 0);
	SvREFCNT_dec(keysv);
    }
    for(Smoke::Index *i = o->smoke->inheritanceList + o->smoke->classes[classId].parents;
	*i;
	i++) {
	mapPointer(obj, o, hv, *i, lastptr);
    }
}

Marshall::HandlerFn getMarshallFn(const SmokeType &type);

class VirtualMethodReturnValue : public Marshall {
    Smoke *_smoke;
    Smoke::Index _method;
    Smoke::Stack _stack;
    SmokeType _st;
    SV *_retval;
public:
    const Smoke::Method &method() { return _smoke->methods[_method]; }
    SmokeType type() { return _st; }
    Marshall::Action action() { return Marshall::FromSV; }
    Smoke::StackItem &item() { return _stack[0]; }
    SV *var() { return _retval; }
    void unsupported() {
	croak("Cannot handle '%s' as return-type of virtual method %s::%s",
		type().name(),
		_smoke->className(method().classId),
		_smoke->methodNames[method().name]);
    }
    Smoke *smoke() { return _smoke; }
    void next() {}
    bool cleanup() { return false; }
    VirtualMethodReturnValue(Smoke *smoke, Smoke::Index meth, Smoke::Stack stack, SV *retval) :
	_smoke(smoke), _method(meth), _stack(stack), _retval(retval) {
	_st.set(_smoke, method().ret);
 	Marshall::HandlerFn fn = getMarshallFn(type());
	(*fn)(this);
   }
};

class VirtualMethodCall : public Marshall {
    Smoke *_smoke;
    Smoke::Index _method;
    Smoke::Stack _stack;
    GV *_gv;
    int _cur;
    Smoke::Index *_args;
    SV **_sp;
    bool _called;
    SV *_savethis;

public:
    SmokeType type() { return SmokeType(_smoke, _args[_cur]); }
    Marshall::Action action() { return Marshall::ToSV; }
    Smoke::StackItem &item() { return _stack[_cur + 1]; }
    SV *var() { return _sp[_cur]; }
    const Smoke::Method &method() { return _smoke->methods[_method]; }
    void unsupported() {
	croak("Cannot handle '%s' as argument of virtual method %s::%s",
		type().name(),
		_smoke->className(method().classId),
		_smoke->methodNames[method().name]);
    }
    Smoke *smoke() { return _smoke; }
    void callMethod() {
	dSP;
	if(_called) return;
	_called = true;
	SP = _sp + method().numArgs - 1;
	PUTBACK;
	int count = call_sv((SV*)GvCV(_gv), G_SCALAR);
	SPAGAIN;
	VirtualMethodReturnValue r(_smoke, _method, _stack, POPs);
	PUTBACK;
	FREETMPS;
	LEAVE;
    }
    void next() {
	int oldcur = _cur;
	_cur++;
	while(!_called && _cur < method().numArgs) {
	    Marshall::HandlerFn fn = getMarshallFn(type());
	    (*fn)(this);
	    _cur++;
	}
	callMethod();
	_cur = oldcur;
    }
    bool cleanup() { return false; }   // is this right?
    VirtualMethodCall(Smoke *smoke, Smoke::Index meth, Smoke::Stack stack, SV *obj, GV *gv) :
	_smoke(smoke), _method(meth), _stack(stack), _gv(gv), _cur(-1), _sp(0), _called(false) {
	dSP;
	ENTER;
	SAVETMPS;
	PUSHMARK(SP);
	EXTEND(SP, method().numArgs);
	_savethis = sv_this;
	sv_this = newSVsv(obj);
	_sp = SP + 1;
	for(int i = 0; i < method().numArgs; i++)
	    _sp[i] = sv_newmortal();
	_args = _smoke->argumentList + method().args;
    }
    ~VirtualMethodCall() {
	SvREFCNT_dec(sv_this);
	sv_this = _savethis;
    }
};

class MethodReturnValue : public Marshall {
    Smoke *_smoke;
    Smoke::Index _method;
    SV *_retval;
    Smoke::Stack _stack;
public:
    MethodReturnValue(Smoke *smoke, Smoke::Index method, Smoke::Stack stack, SV *retval) :
	_smoke(smoke), _method(method), _retval(retval), _stack(stack) {
	Marshall::HandlerFn fn = getMarshallFn(type());
	(*fn)(this);
    }
    const Smoke::Method &method() { return _smoke->methods[_method]; }
    SmokeType type() { return SmokeType(_smoke, method().ret); }
    Marshall::Action action() { return Marshall::ToSV; }
    Smoke::StackItem &item() { return _stack[0]; }
    SV *var() { return _retval; }
    void unsupported() {
	croak("Cannot handle '%s' as return-type of %s::%s",
		type().name(),
		_smoke->className(method().classId),
		_smoke->methodNames[method().name]);
    }
    Smoke *smoke() { return _smoke; }
    void next() {}
    bool cleanup() { return false; }
};

class MethodCall : public Marshall {
    int _cur;
    Smoke *_smoke;
    Smoke::Stack _stack;
    Smoke::Index _method;
    Smoke::Index *_args;
    SV **_sp;
    int _items;
    SV *_retval;
    bool _called;
public:
    MethodCall(Smoke *smoke, Smoke::Index method, SV **sp, int items) :
	_smoke(smoke), _method(method), _sp(sp), _items(items), _cur(-1), _called(false) {
	_args = _smoke->argumentList + _smoke->methods[_method].args;
	_items = _smoke->methods[_method].numArgs;
	_stack = new Smoke::StackItem[items + 1];
	_retval = newSV(0);
    }
    ~MethodCall() {
	delete[] _stack;
	SvREFCNT_dec(_retval);
    }
    SmokeType type() { return SmokeType(_smoke, _args[_cur]); }
    Marshall::Action action() { return Marshall::FromSV; }
    Smoke::StackItem &item() { return _stack[_cur + 1]; }
    SV *var() {
	if(_cur < 0) return _retval;
	SvGETMAGIC(*(_sp + _cur));
	return *(_sp + _cur);
    }
    inline const Smoke::Method &method() { return _smoke->methods[_method]; }
    void unsupported() {
	croak("Cannot handle '%s' as argument to %s::%s",
		type().name(),
		_smoke->className(method().classId),
		_smoke->methodNames[method().name]);
    }
    Smoke *smoke() { return _smoke; }
    inline void callMethod() {
	if(_called) return;
	_called = true;
	Smoke::ClassFn fn = _smoke->classes[method().classId].classFn;
	void *ptr = _smoke->cast(
	    _current_object,
	    _current_object_class,
	    method().classId
	);
	_items = -1;
	(*fn)(method().method, ptr, _stack);
	MethodReturnValue r(_smoke, _method, _stack, _retval);
    }
    void next() {
	int oldcur = _cur;
	_cur++;

	while(!_called && _cur < _items) {
	    Marshall::HandlerFn fn = getMarshallFn(type());
	    (*fn)(this);
	    _cur++;
	}

	callMethod();
	_cur = oldcur;
    }
    bool cleanup() { return true; }
};

class UnencapsulatedQObject : public QObject {
public:
    QConnectionList *public_receivers(int signal) const { return receivers(signal); }
    void public_activate_signal(QConnectionList *clist, QUObject *o) { activate_signal(clist, o); }
};

class EmitSignal : public Marshall {
    UnencapsulatedQObject *_qobj;
    int _id;
    MocArgument *_args;
    SV **_sp;
    int _items;
    int _cur;
    Smoke::Stack _stack;
    bool _called;
public:
    EmitSignal(QObject *qobj, int id, int items, MocArgument *args, SV **sp) :
	_qobj((UnencapsulatedQObject*)qobj), _id(id), _items(items), _args(args),
	_sp(sp), _cur(-1), _called(false) {
	_stack = new Smoke::StackItem[_items];
    }
    ~EmitSignal() {
	delete[] _stack;
    }
    const MocArgument &arg() { return _args[_cur]; }
    SmokeType type() { return arg().st; }
    Marshall::Action action() { return Marshall::FromSV; }
    Smoke::StackItem &item() { return _stack[_cur]; }
    SV *var() { return _sp[_cur]; }
    void unsupported() {
	croak("Cannot handle '%s' as signal argument", type().name());
    }
    Smoke *smoke() { return type().smoke(); }
    void emitSignal() {
	if(_called) return;
	_called = true;

	QConnectionList *clist = _qobj->public_receivers(_id);
	if(!clist) return;

	QUObject *o = new QUObject[_items + 1];
	for(int i = 0; i < _items; i++) {
	    QUObject *po = o + i + 1;
	    Smoke::StackItem *si = _stack + i;
	    switch(_args[i].argType) {
	      case xmoc_bool:
		static_QUType_bool.set(po, si->s_bool);
		break;
	      case xmoc_int:
		static_QUType_int.set(po, si->s_int);
		break;
	      case xmoc_double:
		static_QUType_double.set(po, si->s_double);
		break;
	      case xmoc_charstar:
		static_QUType_charstar.set(po, (char*)si->s_voidp);
		break;
	      case xmoc_QString:
		static_QUType_QString.set(po, *(QString*)si->s_voidp);
		break;
	      default:
		{
		    const SmokeType &t = _args[i].st;
		    void *p;
		    switch(t.elem()) {
		      case Smoke::t_bool:
			p = &si->s_bool;
			break;
		      case Smoke::t_char:
			p = &si->s_char;
			break;
		      case Smoke::t_uchar:
			p = &si->s_uchar;
			break;
		      case Smoke::t_short:
			p = &si->s_short;
			break;
		      case Smoke::t_ushort:
			p = &si->s_ushort;
			break;
		      case Smoke::t_int:
			p = &si->s_int;
			break;
		      case Smoke::t_uint:
			p = &si->s_uint;
			break;
		      case Smoke::t_long:
			p = &si->s_long;
			break;
		      case Smoke::t_ulong:
			p = &si->s_ulong;
			break;
		      case Smoke::t_float:
			p = &si->s_float;
			break;
		      case Smoke::t_double:
			p = &si->s_double;
			break;
		      case Smoke::t_enum:
			{
			    // allocate a new enum value
			    Smoke::EnumFn fn = SmokeClass(t).enumFn();
			    if(!fn) {
				warn("Unknown enumeration %s\n", t.name());
				p = new int((int)si->s_enum);
				break;
			    }
			    Smoke::Index id = t.typeId();
			    (*fn)(Smoke::EnumNew, id, p, si->s_enum);
			    (*fn)(Smoke::EnumFromLong, id, p, si->s_enum);
			    // FIXME: MEMORY LEAK
			}
			break;
		      case Smoke::t_class:
		      case Smoke::t_voidp:
			p = si->s_voidp;
			break;
		      default:
			p = 0;
			break;
		    }
		    static_QUType_ptr.set(po, p);
		}
	    }
	}

	_qobj->public_activate_signal(clist, o);
        delete[] o;
    }
    void next() {
	int oldcur = _cur;
	_cur++;

	while(!_called && _cur < _items) {
	    Marshall::HandlerFn fn = getMarshallFn(type());
	    (*fn)(this);
	    _cur++;
	}

	emitSignal();
	_cur = oldcur;
    }
    bool cleanup() { return true; }
};

class InvokeSlot : public Marshall {
    QObject *_qobj;
    GV *_gv;
    int _items;
    MocArgument *_args;
    QUObject *_o;
    int _cur;
    bool _called;
    SV **_sp;
    Smoke::Stack _stack;
public:
    const MocArgument &arg() { return _args[_cur]; }
    SmokeType type() { return arg().st; }
    Marshall::Action action() { return Marshall::ToSV; }
    Smoke::StackItem &item() { return _stack[_cur]; }
    SV *var() { return _sp[_cur]; }
    Smoke *smoke() { return type().smoke(); }
    bool cleanup() { return false; }
    void unsupported() {
	croak("Cannot handle '%s' as slot argument\n", type().name());
    }
    void copyArguments() {
	for(int i = 0; i < _items; i++) {
	    QUObject *o = _o + i + 1;
	    switch(_args[i].argType) {
	      case xmoc_bool:
		_stack[i].s_bool = static_QUType_bool.get(o);
		break;
	      case xmoc_int:
		_stack[i].s_int = static_QUType_int.get(o);
		break;
	      case xmoc_double:
		_stack[i].s_double = static_QUType_double.get(o);
		break;
	      case xmoc_charstar:
		_stack[i].s_voidp = static_QUType_charstar.get(o);
		break;
	      case xmoc_QString:
		_stack[i].s_voidp = &static_QUType_QString.get(o);
		break;
	      default:	// case xmoc_ptr:
		{
		    const SmokeType &t = _args[i].st;
		    void *p = static_QUType_ptr.get(o);
		    switch(t.elem()) {
		      case Smoke::t_bool:
			_stack[i].s_bool = *(bool*)p;
			break;
		      case Smoke::t_char:
			_stack[i].s_char = *(char*)p;
			break;
		      case Smoke::t_uchar:
			_stack[i].s_uchar = *(unsigned char*)p;
			break;
		      case Smoke::t_short:
			_stack[i].s_short = *(short*)p;
			break;
		      case Smoke::t_ushort:
			_stack[i].s_ushort = *(unsigned short*)p;
			break;
		      case Smoke::t_int:
			_stack[i].s_int = *(int*)p;
			break;
		      case Smoke::t_uint:
			_stack[i].s_uint = *(unsigned int*)p;
			break;
		      case Smoke::t_long:
			_stack[i].s_long = *(long*)p;
			break;
		      case Smoke::t_ulong:
			_stack[i].s_ulong = *(unsigned long*)p;
			break;
		      case Smoke::t_float:
			_stack[i].s_float = *(float*)p;
			break;
		      case Smoke::t_double:
			_stack[i].s_double = *(double*)p;
			break;
		      case Smoke::t_enum:
			{
			    Smoke::EnumFn fn = SmokeClass(t).enumFn();
			    if(!fn) {
				warn("Unknown enumeration %s\n", t.name());
				_stack[i].s_enum = *(int*)p;
				break;
			    }
			    Smoke::Index id = t.typeId();
			    (*fn)(Smoke::EnumToLong, id, p, _stack[i].s_enum);
			}
			break;
		      case Smoke::t_class:
		      case Smoke::t_voidp:
			_stack[i].s_voidp = p;
			break;
		    }
		}
	    }
	}
    }
    void invokeSlot() {
	dSP;
	if(_called) return;
	_called = true;

	SP = _sp + _items - 1;
	PUTBACK;
	int count = call_sv((SV*)GvCV(_gv), G_SCALAR);
	SPAGAIN;
	SP -= count;
	PUTBACK;
	FREETMPS;
	LEAVE;
    }
    void next() {
	int oldcur = _cur;
	_cur++;

	while(!_called && _cur < _items) {
	    Marshall::HandlerFn fn = getMarshallFn(type());
	    (*fn)(this);
	    _cur++;
	}

	invokeSlot();
	_cur = oldcur;
    }
    InvokeSlot(QObject *qobj, GV *gv, int items, MocArgument *args, QUObject *o) :
	_qobj(qobj), _gv(gv), _items(items), _args(args), _o(o), _cur(-1), _called(false) {
	dSP;
	ENTER;
	SAVETMPS;
	PUSHMARK(SP);
	EXTEND(SP, items);
	PUTBACK;
	_sp = SP + 1;
	for(int i = 0; i < _items; i++)
	    _sp[i] = sv_newmortal();
	_stack = new Smoke::StackItem[_items];
	copyArguments();
    }
    ~InvokeSlot() {
	delete[] _stack;
    }

};

class QtSmokeBinding : public SmokeBinding {
public:
    QtSmokeBinding(Smoke *s) : SmokeBinding(s) {}
    void deleted(Smoke::Index classId, void *ptr) {
	SV *obj = getPointerObject(ptr);
	smokeperl_object *o = sv_obj_info(obj);
	if(do_debug && (do_debug & qtdb_gc)) {
            fprintf(stderr, "%p->~%s()\n", ptr, smoke->className(classId));
        }
	if(!o || !o->ptr) {
	    return;
	}
        unmapPointer(o, o->classId, 0);
	o->ptr = 0;
    }
    bool callMethod(Smoke::Index method, void *ptr, Smoke::Stack args, bool isAbstract) {
	SV *obj = getPointerObject(ptr);
	smokeperl_object *o = sv_obj_info(obj);
	if(do_debug && (do_debug & qtdb_virtual)) fprintf(stderr, "virtual %p->%s::%s() called\n", ptr,
	    smoke->classes[smoke->methods[method].classId].className,
	    smoke->methodNames[smoke->methods[method].name]
        );

	if(!o) {
	    if(!PL_dirty && (do_debug && (do_debug & qtdb_virtual)) )   // if not in global destruction
		fprintf(stderr, "Cannot find object for virtual method\n");
	    return false;
	}
	HV *stash = SvSTASH(SvRV(obj));
	if(*HvNAME(stash) == ' ')
	    stash = gv_stashpv(HvNAME(stash) + 1, TRUE);
	const char *methodName = smoke->methodNames[smoke->methods[method].name];
	GV *gv = gv_fetchmethod_autoload(stash, methodName, 0);
	if(!gv) return false;

	VirtualMethodCall c(smoke, method, args, obj, gv);
	// exception variable, just temporary
	temporary_virtual_function_success = true;
	c.next();
	bool ret = temporary_virtual_function_success;
	temporary_virtual_function_success = true;
	return ret;
    }
    char *className(Smoke::Index classId) {
	const char *className = smoke->className(classId);
	char *buf = new char[strlen(className) + 6];
	strcpy(buf, " Qt::");
	strcat(buf, className + 1);
	return buf;
    }
};

// ----------------   Helpers -------------------

SV *catArguments(SV** sp, int n)
{
    SV* r=newSVpvf("");
    for(int i = 0; i < n; i++) {
        if(i) sv_catpv(r, ", ");
        if(!SvOK(sp[i])) {
            sv_catpv(r, "undef");
        } else if(SvROK(sp[i])) {
            smokeperl_object *o = sv_obj_info(sp[i]);
            if(o)
                sv_catpv(r, o->smoke->className(o->classId));
            else
                sv_catsv(r, sp[i]);
        } else {
            bool isString = SvPOK(sp[i]);
            STRLEN len;
            char *s = SvPV(sp[i], len);
            if(isString) sv_catpv(r, "'");
            sv_catpvn(r, s, len > 10 ? 10 : len);
            if(len > 10) sv_catpv(r, "...");
            if(isString) sv_catpv(r, "'");
        }
    }
    return r;
}

Smoke::Index package_classid(const char *p)
{
     Smoke::Index *item = classcache->find(p);
     if(item)
         return *item;
     char *nisa = new char[strlen(p)+6];
     strcpy(nisa, p);
     strcat(nisa, "::ISA");
     AV* isa=get_av(nisa, true);
     delete[] nisa;
     for(int i=0; i<=av_len(isa); i++) {
         SV** np = av_fetch(isa, i, 0);
         if(np) {
             Smoke::Index ix = package_classid(SvPV_nolen(*np));
             if(ix) {
                 classcache->insert(p, new Smoke::Index(ix));
                 return ix;
             }
         }
     }
     return (Smoke::Index) 0;
}

char *get_SVt(SV *sv)
{
    char *r;
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
//                case SVt_PV:
//                case SVt_PVMG:
//                  r = "p";
                default:
                  r = "r";
            }
        }
	else
	    r = (char*)o->smoke->className(o->classId);
    }
    else
	r = "U";
    return r;
}

SV *prettyPrintMethod(Smoke::Index id) {
    SV *r = newSVpvf("");
    Smoke::Method &meth = qt_Smoke->methods[id];
    const char *tname = qt_Smoke->types[meth.ret].name;
    if(meth.flags & Smoke::mf_static) sv_catpv(r, "static ");
    sv_catpvf(r, "%s ", (tname ? tname:"void"));
    sv_catpvf(r, "%s::%s(", qt_Smoke->classes[meth.classId].className, qt_Smoke->methodNames[meth.name]);
    for(int i = 0; i < meth.numArgs; i++) {
        if(i) sv_catpv(r, ", ");
        tname = qt_Smoke->types[qt_Smoke->argumentList[meth.args+i]].name;
        sv_catpv(r, (tname ? tname:"void"));
    }
    sv_catpv(r, ")");
    if(meth.flags & Smoke::mf_const) sv_catpv(r, " const");
    return r;
}

// --------------- Unary Keywords && Attributes ------------------


// implements unary 'this'
XS(XS_this) {
    dXSARGS;
    ST(0) = sv_this;
    XSRETURN(1);
}

// implements unary attributes: 'foo' means 'this->{foo}'
XS(XS_attr) {
    dXSARGS;
    char *key = GvNAME(CvGV(cv));
    U32 klen = strlen(key);
    SV **svp = 0;
    if(SvROK(sv_this) && SvTYPE(SvRV(sv_this)) == SVt_PVHV) {
	HV *hv = (HV*)SvRV(sv_this);
	svp = hv_fetch(hv, key, klen, 1);
    }
    if(svp) {
	ST(0) = *svp;
	XSRETURN(1);
    }
    XSRETURN_UNDEF;
}

// implements unary SUPER attribute: 'SUPER' means ${(CopSTASH)::_INTERNAL_STATIC_}{SUPER}
XS(XS_super) {
    dXSARGS;
    char *key = "SUPER";
    U32 klen = strlen(key);
    SV **svp = 0;
    if(SvROK(sv_this) && SvTYPE(SvRV(sv_this)) == SVt_PVHV) {
	HV *cs = (HV*)CopSTASH(PL_curcop);
        if(!cs) XSRETURN_UNDEF;
        svp = hv_fetch(cs, "_INTERNAL_STATIC_", 17, 0);
        if(!svp) XSRETURN_UNDEF;
        cs = GvHV((GV*)*svp);
        if(!cs) XSRETURN_UNDEF;
        svp = hv_fetch(cs, "SUPER", 5, 0);
    }
    if(svp) {
	ST(0) = *svp;
	XSRETURN(1);
    }
    XSRETURN_UNDEF;
}

//---------- XS Autoload (for all functions except fully qualified statics & enums) ---------

static inline bool isQt(char *p) {
	return (p[0] == 'Q' && p[1] && p[1] == 't' && ((p[2] && p[2] == ':') || !p[2]));
}

bool avoid_fetchmethod = false;
XS(XS_AUTOLOAD) {
    // Err, XS autoload is borked. Lets try...
    dXSARGS;
    SV *sv = get_sv("Qt::AutoLoad::AUTOLOAD", TRUE);
    char *package = SvPV_nolen(sv);
    char *method = 0;
    for(char *s = package; *s ; s++)
	if(*s == ':') method = s;
    if(!method) XSRETURN_NO;
    *(method++ - 1) = 0;	// sorry for showing off. :)
    int withObject = (*package == ' ') ? 1 : 0;
    int isSuper = 0;
    if(withObject) {
        package++;
        if(*package == ' ') {
             isSuper = 1;
             char *super = new char[strlen(package) + 7];
             package++;
             strcpy(super, package);
             strcat(super, "::SUPER");
             package = super;
        }
    } else if( isQt(package) )
	avoid_fetchmethod = true;

    HV *stash = gv_stashpv(package, TRUE);

    if(do_debug && (do_debug & qtdb_autoload))
        warn("In XS Autoload for %s::%s()\n", package, method);

    // check for user-defined methods in the REAL stash; skip prefix
    GV *gv = 0;
    if(avoid_fetchmethod)
	avoid_fetchmethod = false;
    else
	gv = gv_fetchmethod_autoload(stash, method, 0);

    // If we've made it here, we need to set sv_this
    if(gv) {
        if(do_debug && (do_debug & qtdb_autoload))
            warn("\tfound in %s's Perl stash\n", package);

	// call the defined Perl method with new 'this'
	SV *old_this;
	if(withObject && !isSuper) {
	    old_this = sv_this;
	    sv_this = newSVsv(ST(0));
	}

	ENTER;
	SAVETMPS;
	PUSHMARK(SP - items + withObject);
	PUTBACK;
	int count = call_sv((SV*)GvCV(gv), G_SCALAR|G_EVAL);
	SPAGAIN;
	SV *ret = newSVsv(TOPs);
	SP -= count;
	PUTBACK;
	FREETMPS;
	LEAVE;

	if(withObject && !isSuper) {
	    SvREFCNT_dec(sv_this);
	    sv_this = old_this;
	}
        else if(isSuper)
            delete[] package;

        if(SvTRUE(ERRSV))
            croak(SvPV_nolen(ERRSV));
	ST(0) = sv_2mortal(ret);
	XSRETURN(1);
    }
    else if(!strcmp(method, "DESTROY")) {
        SV *old_this;
	if(withObject && !isSuper) {
	    old_this = sv_this;
	    sv_this = newSVsv(ST(0));
 	}
        smokeperl_object *o = sv_obj_info(sv_this);

	if(!(o && o->ptr && (o->allocated || getPointerObject(o->ptr)))) {
	    if(isSuper)
                delete[] package;
	    if(withObject && !isSuper) {
	        SvREFCNT_dec(sv_this);
	        sv_this = old_this;
	    }
            XSRETURN_YES;
        }
        const char *key = "has been hidden";
        U32 klen = 15;
        SV **svp = 0;
        if(SvROK(sv_this) && SvTYPE(SvRV(sv_this)) == SVt_PVHV) {
	    HV *hv = (HV*)SvRV(sv_this);
	    svp = hv_fetch(hv, key, klen, 0);
        }
        if(svp) {
	    if(isSuper)
                delete[] package;
            if(withObject && !isSuper) {
	        SvREFCNT_dec(sv_this);
	        sv_this = old_this;
	    }
	    XSRETURN_YES;
	}
        gv = gv_fetchmethod_autoload(stash, "ON_DESTROY", 0);
	if( !gv )
	    croak( "Couldn't find ON_DESTROY method for %s=%p\n", package, o->ptr);
	PUSHMARK(SP);
	call_sv((SV*)GvCV(gv), G_SCALAR|G_NOARGS);
	SPAGAIN;
	int ret = POPi;
	PUTBACK;
	if(withObject && !isSuper) {
	    SvREFCNT_dec(sv_this);
	    sv_this = old_this;
	}
	if( do_debug && ret && (do_debug & qtdb_gc) )
	    fprintf(stderr, "Increasing refcount in DESTROY for %s=%p (still has a parent)\n", package, o->ptr);
    } else {

        if( items > 18 )  XSRETURN_NO; // current max number of args in Qt is 13.

        // save the stack -- we'll need it
        SV **savestack = new SV*[items+1];
        SV *saveobj = ST(0);
        SV *old_this;

        Copy(SP - items + 1 + withObject, savestack, items-withObject, SV*);

        // Get the classid (eventually converting SUPER to the right Qt class)
        Smoke::Index cid = package_classid(package);
        // Look in the cache
        char *cname = (char*)qt_Smoke->className(cid);
        int lcname = strlen(cname);
        int lmethod = strlen(method);
        char mcid[256];
        strncpy(mcid, cname, lcname);
        char *ptr = mcid + lcname;
	*(ptr++) = ';';
        strncpy(ptr, method, lmethod);
	ptr += lmethod;
        for(int i=withObject ; i<items ; i++)
        {
            *(ptr++) = ';';
	    char *t = get_SVt(ST(i));
	    int tlen = strlen(t);
	    strncpy(ptr, t, tlen );
	    ptr += tlen;
        }
	*ptr = 0;
	Smoke::Index *rcid = methcache->find(mcid);

        if(rcid) {
            // Got a hit
            _current_method = *rcid;
            if(withObject && !isSuper) {
                old_this = sv_this;
                sv_this = newSVsv(ST(0));
            }
        }
        else {

            // Find the C++ method to call. I'll do that from Perl for now

            ENTER;
            SAVETMPS;
            PUSHMARK(SP - items + withObject);
            EXTEND(SP, 3);
            PUSHs(sv_2mortal(newSViv((IV)cid)));
            PUSHs(sv_2mortal(newSVpv(method, 0)));
            PUSHs(sv_2mortal(newSVpv(package, 0)));
            PUTBACK;
            if(withObject && !isSuper) {
                old_this = sv_this;
                sv_this = newSVsv(saveobj);
            }
            call_pv("Qt::_internal::do_autoload", G_DISCARD|G_EVAL);
            FREETMPS;
            LEAVE;

            // Restore sv_this on error, so that eval{ } works
            if(SvTRUE(ERRSV)) {
                if(withObject && !isSuper) {
                        SvREFCNT_dec(sv_this);
                        sv_this = old_this;
                }
                else if(isSuper)
                        delete[] package;
                delete[] savestack;
                croak(SvPV_nolen(ERRSV));
            }

            // Success. Cache result.
            methcache->insert(mcid, new Smoke::Index(_current_method));
        }
        // FIXME: I shouldn't have to set the current object
        {
                smokeperl_object *o = sv_obj_info(sv_this);
                if(o && o->ptr) {
                    _current_object = o->ptr;
                    _current_object_class = o->classId;
                } else {
                    _current_object = 0;
                }
        }
        // honor debugging channels
        if(do_debug && (do_debug & qtdb_calls)) {
            warn("Calling method\t%s\n", SvPV_nolen(sv_2mortal(prettyPrintMethod(_current_method))));
            if(do_debug & qtdb_verbose)
                warn("with arguments (%s)\n", SvPV_nolen(sv_2mortal(catArguments(savestack, items-withObject))));
        }
        MethodCall c(qt_Smoke, _current_method, savestack, items-withObject);
        c.next();
        if(savestack)
            delete[] savestack;

        if(withObject && !isSuper) {
                SvREFCNT_dec(sv_this);
                sv_this = old_this;
        }
        else if(isSuper)
                delete[] package;

        SV *ret = c.var();
        SvREFCNT_inc(ret);
        ST(0) = sv_2mortal(ret);
        XSRETURN(1);
    }
    if(isSuper)
        delete[] package;
    XSRETURN_YES;
}


//----------------- Sig/Slot ------------------


MocArgument *getmetainfo(GV *gv, const char *name, int &offset, int &index, int &argcnt) {
    char *signalname = GvNAME(gv);
    HV *stash = GvSTASH(gv);

    // $meta = $stash->{META}
    SV **svp = hv_fetch(stash, "META", 4, 0);
    if(!svp) return 0;
    HV *hv = GvHV((GV*)*svp);
    if(!hv) return 0;

    // $metaobject = $meta->{object}
    // aka. Class->staticMetaObject
    svp = hv_fetch(hv, "object", 6, 0);
    if(!svp) return 0;
    smokeperl_object *ometa = sv_obj_info(*svp);
    if(!ometa) return 0;
    QMetaObject *metaobject = (QMetaObject*)ometa->ptr;

    offset = metaobject->signalOffset();

    // $signals = $meta->{signal}
    U32 len = strlen(name);
    svp = hv_fetch(hv, name, len, 0);
    if(!svp) return 0;
    HV *signalshv = (HV*)SvRV(*svp);

    // $signal = $signals->{$signalname}
    len = strlen(signalname);
    svp = hv_fetch(signalshv, signalname, len, 0);
    if(!svp) return 0;
    HV *signalhv = (HV*)SvRV(*svp);

    // $index = $signal->{index}
    svp = hv_fetch(signalhv, "index", 5, 0);
    if(!svp) return 0;;
    index = SvIV(*svp);

    // $argcnt = $signal->{argcnt}
    svp = hv_fetch(signalhv, "argcnt", 6, 0);
    if(!svp) return 0;
    argcnt = SvIV(*svp);

    // $mocargs = $signal->{mocargs}
    svp = hv_fetch(signalhv, "mocargs", 7, 0);
    if(!svp) return 0;
    MocArgument *args = (MocArgument*)SvIV(*svp);

    return args;
}

MocArgument *getslotinfo(GV *gv, int id, char *&slotname, int &index, int &argcnt, bool isSignal = false) {
    HV *stash = GvSTASH(gv);

    // $meta = $stash->{META}
    SV **svp = hv_fetch(stash, "META", 4, 0);
    if(!svp) return 0;
    HV *hv = GvHV((GV*)*svp);
    if(!hv) return 0;

    // $metaobject = $meta->{object}
    // aka. Class->staticMetaObject
    svp = hv_fetch(hv, "object", 6, 0);
    if(!svp) return 0;
    smokeperl_object *ometa = sv_obj_info(*svp);
    if(!ometa) return 0;
    QMetaObject *metaobject = (QMetaObject*)ometa->ptr;

    int offset = isSignal ? metaobject->signalOffset() : metaobject->slotOffset();

    index = id - offset;   // where we at
    // FIXME: make slot inheritance work
    if(index < 0) return 0;
    // $signals = $meta->{signal}
    const char *key = isSignal ? "signals" : "slots";
    svp = hv_fetch(hv, key, strlen(key), 0);
    if(!svp) return 0;
    AV *signalsav = (AV*)SvRV(*svp);
    svp = av_fetch(signalsav, index, 0);
    if(!svp) return 0;
    HV *signalhv = (HV*)SvRV(*svp);
    // $argcnt = $signal->{argcnt}
    svp = hv_fetch(signalhv, "argcnt", 6, 0);
    if(!svp) return 0;
    argcnt = SvIV(*svp);
    // $mocargs = $signal->{mocargs}
    svp = hv_fetch(signalhv, "mocargs", 7, 0);
    if(!svp) return 0;
    MocArgument *args = (MocArgument*)SvIV(*svp);

    svp = hv_fetch(signalhv, "name", 4, 0);
    if(!svp) return 0;
    slotname = SvPV_nolen(*svp);

    return args;
}

XS(XS_signal) {
    dXSARGS;

    smokeperl_object *o = sv_obj_info(sv_this);
    QObject *qobj = (QObject*)o->smoke->cast(
	o->ptr,
	o->classId,
	o->smoke->idClass("QObject")
    );
    if(qobj->signalsBlocked()) XSRETURN_UNDEF;

    int offset;
    int index;
    int argcnt;
    MocArgument *args;

    args = getmetainfo(CvGV(cv), "signal", offset, index, argcnt);
    if(!args) XSRETURN_UNDEF;

    // Okay, we have the signal info. *whew*
    if(items < argcnt)
	croak("Insufficient arguments to emit signal");

    EmitSignal signal(qobj, offset + index, argcnt, args, &ST(0));
    signal.next();

    XSRETURN_UNDEF;
}

XS(XS_qt_invoke) {
    dXSARGS;
    // Arguments: int id, QUObject *o
    int id = SvIV(ST(0));
    QUObject *_o = (QUObject*)SvIV(SvRV(ST(1)));

    smokeperl_object *o = sv_obj_info(sv_this);
    QObject *qobj = (QObject*)o->smoke->cast(
	o->ptr,
	o->classId,
	o->smoke->idClass("QObject")
    );

    // Now, I need to find out if this means me
    int index;
    char *slotname;
    int argcnt;
    MocArgument *args;
    bool isSignal = !strcmp(GvNAME(CvGV(cv)), "qt_emit");
    args = getslotinfo(CvGV(cv), id, slotname, index, argcnt, isSignal);
    if(!args) {
	// throw an exception - evil style
	temporary_virtual_function_success = false;
	XSRETURN_UNDEF;
    }
    HV *stash = GvSTASH(CvGV(cv));
    GV *gv = gv_fetchmethod_autoload(stash, slotname, 0);
    if(!gv) XSRETURN_UNDEF;
    InvokeSlot slot(qobj, gv, argcnt, args, _o);
    slot.next();

    XSRETURN_UNDEF;
}

// -------------------       Tied types        ------------------------

MODULE = Qt   PACKAGE = Qt::_internal::QString
PROTOTYPES: DISABLE

SV*
FETCH(obj)
    SV* obj
    CODE:
    if (!SvROK(obj))
        croak("?");
    IV tmp = SvIV((SV*)SvRV(obj));
    QString *s = (QString*) tmp;
    RETVAL = newSV(0);
    if( s )
    {
        if(!(IN_BYTES))
        {
	    sv_setpv_mg(RETVAL, (const char *)s->utf8());
            SvUTF8_on(RETVAL);
        }
        else if(IN_LOCALE)
            sv_setpv_mg(RETVAL, (const char *)s->local8Bit());
        else
            sv_setpv_mg(RETVAL, (const char *)s->latin1());
    }
    else
        sv_setsv_mg(RETVAL, &PL_sv_undef);
    OUTPUT: 
    RETVAL

void
STORE(obj,what)
   SV* obj
   SV* what
   CODE:
    if (!SvROK(obj))
        croak("?");
    IV tmp = SvIV((SV*)SvRV(obj));
    QString *s = (QString*) tmp;
    s->truncate(0);
    if(SvOK(what)) {
        if(SvUTF8(what)) 
	    s->append(QString::fromUtf8(SvPV_nolen(what)));
        else if(IN_LOCALE)
            s->append(QString::fromLocal8Bit(SvPV_nolen(what)));
        else
            s->append(QString::fromLatin1(SvPV_nolen(what)));
    }  

void
DESTROY(obj)
    SV* obj
    CODE:
    if (!SvROK(obj))
        croak("?");
    IV tmp = SvIV((SV*)SvRV(obj));
    QString *s = (QString*) tmp;
    delete s;

MODULE = Qt   PACKAGE = Qt::_internal::QByteArray
PROTOTYPES: DISABLE

SV*
FETCH(obj)
    SV* obj
    CODE:
    if (!SvROK(obj))
        croak("?");
    IV tmp = SvIV((SV*)SvRV(obj));
    QByteArray *s = (QByteArray*) tmp;
    RETVAL = newSV(0);
    if( s )
    {
	sv_setpvn_mg(RETVAL, s->data(), s->size());
    }
    else
        sv_setsv_mg(RETVAL, &PL_sv_undef);
    OUTPUT: 
    RETVAL

void
STORE(obj,what)
   SV* obj
   SV* what
   CODE:
    if (!SvROK(obj))
        croak("?");
    IV tmp = SvIV((SV*)SvRV(obj));
    QByteArray *s = (QByteArray*) tmp;

    if(SvOK(what)) {
        STRLEN len;
	char* tmp2 = SvPV(what, len); 
        s->resize(len);
	Copy((void*)tmp2, (void*)s->data(), len, char);
    }  else
        s->truncate(0);

void
DESTROY(obj)
    SV* obj
    CODE:
    if (!SvROK(obj))
        croak("?");
    IV tmp = SvIV((SV*)SvRV(obj));
    QByteArray *s = (QByteArray*) tmp;
    delete s;

MODULE = Qt   PACKAGE = Qt::_internal::QRgbStar
PROTOTYPES: DISABLE

SV*
FETCH(obj)
    SV* obj
    CODE:
    if (!SvROK(obj))
        croak("?");
    IV tmp = SvIV((SV*)SvRV(obj));
    QRgb *s = (QRgb*) tmp;
    AV* ar = newAV();
    RETVAL = newRV_noinc((SV*)ar);
    for(int i=0; s[i] ; i++)
    {
	SV *item = newSViv((IV)s[i]);
	if(!av_store(ar, (I32)i, item))
	    SvREFCNT_dec( item );
    }
    OUTPUT: 
    RETVAL

void
STORE(obj,sv)
   SV* obj
   SV* sv
   CODE:
    if (!SvROK(obj))
        croak("?");
    IV tmp = SvIV((SV*)SvRV(obj));
    QRgb *s = (QRgb*) tmp;
    if(!SvROK(sv) || SvTYPE(SvRV(sv)) != SVt_PVAV ||
	av_len((AV*)SvRV(sv)) < 0) {
	 s = new QRgb[1];
	 s[0] = 0; 
	 sv_setref_pv(obj, "Qt::_internal::QRgbStar", (void*)s);
	 return;
    }
    AV *list = (AV*)SvRV(sv);
    int count = av_len(list);
    s = new QRgb[count + 2];
    int i;
    for(i = 0; i <= count; i++) {
	SV **item = av_fetch(list, i, 0);
	if(!item || !SvOK(*item)) {
	    s[i] = 0;
	    continue;
	}
	s[i] = SvIV(*item);
    }
    s[i] = 0;
    sv_setref_pv(obj, "Qt::_internal::QRgbStar", (void*)s); 

void
DESTROY(obj)
    SV* obj
    CODE:
    if (!SvROK(obj))
        croak("?");
    IV tmp = SvIV((SV*)SvRV(obj));
    QRgb *s = (QRgb*) tmp;
    delete[] s;

# --------------- XSUBS for Qt::_internal::* helpers  ----------------


MODULE = Qt   PACKAGE = Qt::_internal
PROTOTYPES: DISABLE

void
getMethStat()
    PPCODE:
    XPUSHs(sv_2mortal(newSViv((int)methcache->size())));
    XPUSHs(sv_2mortal(newSViv((int)methcache->count())));

void
getClassStat()
    PPCODE:
    XPUSHs(sv_2mortal(newSViv((int)classcache->size())));
    XPUSHs(sv_2mortal(newSViv((int)classcache->count())));

void
getIsa(classId)
    int classId
    PPCODE:
    Smoke::Index *parents =
	qt_Smoke->inheritanceList +
	qt_Smoke->classes[classId].parents;
    while(*parents)
	XPUSHs(sv_2mortal(newSVpv(qt_Smoke->classes[*parents++].className, 0)));

void
dontRecurse()
    CODE:
    avoid_fetchmethod = true;

void *
sv_to_ptr(sv)
    SV* sv

void *
allocateMocArguments(count)
    int count
    CODE:
    RETVAL = (void*)new MocArgument[count + 1];
    OUTPUT:
    RETVAL

void
setMocType(ptr, idx, name, static_type)
    void *ptr
    int idx
    char *name
    char *static_type
    CODE:
    Smoke::Index typeId = qt_Smoke->idType(name);
    if(!typeId) XSRETURN_NO;
    MocArgument *arg = (MocArgument*)ptr;
    arg[idx].st.set(qt_Smoke, typeId);
    if(!strcmp(static_type, "ptr"))
	arg[idx].argType = xmoc_ptr;
    else if(!strcmp(static_type, "bool"))
	arg[idx].argType = xmoc_bool;
    else if(!strcmp(static_type, "int"))
	arg[idx].argType = xmoc_int;
    else if(!strcmp(static_type, "double"))
	arg[idx].argType = xmoc_double;
    else if(!strcmp(static_type, "char*"))
	arg[idx].argType = xmoc_charstar;
    else if(!strcmp(static_type, "QString"))
	arg[idx].argType = xmoc_QString;
    XSRETURN_YES;

void
installsignal(name)
    char *name
    CODE:
    char *file = __FILE__;
    newXS(name, XS_signal, file);

void
installqt_invoke(name)
    char *name
    CODE:
    char *file = __FILE__;
    newXS(name, XS_qt_invoke, file);

void
setDebug(on)
    int on
    CODE:
    do_debug = on;

int
debug()
    CODE:
    RETVAL = do_debug;
    OUTPUT:
    RETVAL

char *
getTypeNameOfArg(method, idx)
    int method
    int idx
    CODE:
    Smoke::Method &m = qt_Smoke->methods[method];
    Smoke::Index *args = qt_Smoke->argumentList + m.args;
    RETVAL = (char*)qt_Smoke->types[args[idx]].name;
    OUTPUT:
    RETVAL

int
classIsa(className, base)
    char *className
    char *base
    CODE:
    RETVAL = isDerivedFrom(qt_Smoke, className, base, 0);
    OUTPUT:
    RETVAL

void
insert_pclassid(p, ix)
    char *p
    int ix
    CODE:
    classcache->insert(p, new Smoke::Index((Smoke::Index)ix));

int
find_pclassid(p)
    char *p
    CODE:
    Smoke::Index *r = classcache->find(p);
    if(r)
        RETVAL = (int)*r;
    else
        RETVAL = 0;
    OUTPUT:
    RETVAL

void
insert_mcid(mcid, ix)
    char *mcid
    int ix
    CODE:
    methcache->insert(mcid, new Smoke::Index((Smoke::Index)ix));

int
find_mcid(mcid)
    char *mcid
    CODE:
    Smoke::Index *r = methcache->find(mcid);
    if(r)
        RETVAL = (int)*r;
    else
        RETVAL = 0;
    OUTPUT:
    RETVAL

char *
getSVt(sv)
    SV *sv
    CODE:
    RETVAL=get_SVt(sv);
    OUTPUT:
    RETVAL

void *
make_QUParameter(name, type, extra, inout)
    char *name
    char *type
    SV *extra
    int inout
    CODE:
    QUParameter *p = new QUParameter;
    p->name = new char[strlen(name) + 1];
    strcpy((char*)p->name, name);
    if(!strcmp(type, "bool"))
	p->type = &static_QUType_bool;
    else if(!strcmp(type, "int"))
	p->type = &static_QUType_int;
    else if(!strcmp(type, "double"))
	p->type = &static_QUType_double;
    else if(!strcmp(type, "char*") || !strcmp(type, "const char*"))
	p->type = &static_QUType_charstar;
    else if(!strcmp(type, "QString") || !strcmp(type, "QString&") ||
	    !strcmp(type, "const QString") || !strcmp(type, "const QString&"))
	p->type = &static_QUType_QString;
    else
	p->type = &static_QUType_ptr;
    // Lacking support for several types. Evil.
    p->inOut = inout;
    p->typeExtra = 0;
    RETVAL = (void*)p;
    OUTPUT:
    RETVAL

void *
make_QMetaData(name, method)
    char *name
    void *method
    CODE:
    QMetaData *m = new QMetaData;		// will be deleted
    m->name = new char[strlen(name) + 1];
    strcpy((char*)m->name, name);
    m->method = (QUMethod*)method;
    m->access = QMetaData::Public;
    RETVAL = m;
    OUTPUT:
    RETVAL

void *
make_QUMethod(name, params)
    char *name
    SV *params
    CODE:
    QUMethod *m = new QUMethod;			// permanent memory allocation
    m->name = new char[strlen(name) + 1];	// this too
    strcpy((char*)m->name, name);
    m->count = 0;
    m->parameters = 0;
    if(SvOK(params) && SvRV(params)) {
	AV *av = (AV*)SvRV(params);
	m->count = av_len(av) + 1;
	if(m->count > 0) {
	    m->parameters = new QUParameter[m->count];
	    for(int i = 0; i < m->count; i++) {
		SV *sv = av_shift(av);
		if(!SvOK(sv))
		    croak("Invalid paramater for QUMethod\n");
		QUParameter *p = (QUParameter*)SvIV(sv);
		SvREFCNT_dec(sv);
		((QUParameter*)m->parameters)[i] = *p;
		delete p;
	    }
	} else
	    m->count = 0;
    }
    RETVAL = m;
    OUTPUT:
    RETVAL

void *
make_QMetaData_tbl(list)
    SV *list
    CODE:
    RETVAL = 0;
    if(SvOK(list) && SvRV(list)) {
	AV *av = (AV*)SvRV(list);
	int count = av_len(av) + 1;
	QMetaData *m = new QMetaData[count];
	for(int i = 0; i < count; i++) {
	    SV *sv = av_shift(av);
	    if(!SvOK(sv))
		croak("Invalid metadata\n");
	    QMetaData *old = (QMetaData*)SvIV(sv);
	    SvREFCNT_dec(sv);
	    m[i] = *old;
	    delete old;
	}
	RETVAL = (void*)m;
    }
    OUTPUT:
    RETVAL

SV *
make_metaObject(className, parent, slot_tbl, slot_count, signal_tbl, signal_count)
    char *className
    SV *parent
    void *slot_tbl
    int slot_count
    void *signal_tbl
    int signal_count
    CODE:
    smokeperl_object *po = sv_obj_info(parent);
    if(!po || !po->ptr) croak("Cannot create metaObject\n");
    QMetaObject *meta = QMetaObject::new_metaobject(
	className, (QMetaObject*)po->ptr,
	(const QMetaData*)slot_tbl, slot_count,	// slots
	(const QMetaData*)signal_tbl, signal_count,	// signals
	0, 0,	// properties
	0, 0,	// enums
	0, 0);

    // this object-creation code is so, so wrong here
    HV *hv = newHV();
    SV *obj = newRV_noinc((SV*)hv);

    smokeperl_object o;
    o.smoke = qt_Smoke;
    o.classId = qt_Smoke->idClass("QMetaObject");
    o.ptr = meta;
    o.allocated = true;
    sv_magic((SV*)hv, sv_qapp, '~', (char*)&o, sizeof(o));
    MAGIC *mg = mg_find((SV*)hv, '~');
    mg->mg_virtual = &vtbl_smoke;
    char *buf = qt_Smoke->binding->className(o.classId);
    sv_bless(obj, gv_stashpv(buf, TRUE));
    delete[] buf;
    RETVAL = obj;
    OUTPUT:
    RETVAL

void
dumpObjects()
    CODE:
    hv_iterinit(pointer_map);
    HE *e;
    while(e = hv_iternext(pointer_map)) {
	STRLEN len;
	SV *sv = HeVAL(e);
	printf("key = %s, refcnt = %d, weak = %d, ref? %d\n", HePV(e, len), SvREFCNT(sv), SvWEAKREF(sv), SvROK(sv)?1:0);
	if(SvRV(sv))
	    printf("REFCNT = %d\n", SvREFCNT(SvRV(sv)));
	//SvREFCNT_dec(HeVAL(e));
	//HeVAL(e) = &PL_sv_undef;
    }

void
dangle(obj)
    SV *obj
    CODE:
    if(SvRV(obj))
	SvREFCNT_inc(SvRV(obj));

void
setAllocated(obj, b)
    SV *obj
    bool b
    CODE:
    smokeperl_object *o = sv_obj_info(obj);
    if(o) {
	o->allocated = b;
    }

void
setqapp(obj)
    SV *obj
    CODE:
    if(!obj || !SvROK(obj))
        croak("Invalid Qt::Application object. Couldn't set Qt::app()\n");
    sv_qapp = SvRV(obj);

void
setThis(obj)
    SV *obj
    CODE:
    sv_setsv_mg(sv_this, obj);

void
deleteObject(obj)
    SV *obj
    CODE:
    smokeperl_object *o = sv_obj_info(obj);
    if(!o) { XSRETURN_EMPTY; }
    QObject *qobj = (QObject*)o->smoke->cast(o->ptr, o->classId, o->smoke->idClass("QObject"));
    delete qobj;

void
mapObject(obj)
    SV *obj
    CODE:
    smokeperl_object *o = sv_obj_info(obj);
    if(!o)
        XSRETURN_EMPTY;
    SmokeClass c( o->smoke, o->classId );
    if(!c.hasVirtual() ) {
	XSRETURN_EMPTY;
   }
    mapPointer(obj, o, pointer_map, o->classId, 0);

bool
isQObject(obj)
    SV *obj
    CODE:
    RETVAL = 0;
    smokeperl_object *o = sv_obj_info(obj);
    if(o && isQObject(o->smoke, o->classId))
	RETVAL = 1;
    OUTPUT:
    RETVAL

bool
isValidAllocatedPointer(obj)
    SV *obj
    CODE:
    RETVAL = 0;
    smokeperl_object *o = sv_obj_info(obj);
    if(o && o->ptr && o->allocated)
	RETVAL = 1;
    OUTPUT:
    RETVAL

SV*
findAllocatedObjectFor(obj)
    SV *obj
    CODE:
    RETVAL = &PL_sv_undef;
    smokeperl_object *o = sv_obj_info(obj);
    SV *ret;
    if(o && o->ptr && (ret = getPointerObject(o->ptr)))
        RETVAL = ret;
    OUTPUT:
    RETVAL

SV *
getGV(cv)
    SV *cv
    CODE:
    RETVAL = (SvROK(cv) && (SvTYPE(SvRV(cv))==SVt_PVCV) ?
              SvREFCNT_inc(CvGV((CV*)SvRV(cv))) : &PL_sv_undef);
    OUTPUT:
    RETVAL

int
idClass(name)
    char *name
    CODE:
    RETVAL = qt_Smoke->idClass(name);
    OUTPUT:
    RETVAL

int
idMethodName(name)
    char *name
    CODE:
    RETVAL = qt_Smoke->idMethodName(name);
    OUTPUT:
    RETVAL

int
idMethod(idclass, idmethodname)
    int idclass
    int idmethodname
    CODE:
    RETVAL = qt_Smoke->idMethod(idclass, idmethodname);
    OUTPUT:
    RETVAL

void
findMethod(c, name)
    char *c
    char *name
    PPCODE:
    Smoke::Index meth = qt_Smoke->findMethod(c, name);
//    printf("DAMNIT on %s::%s => %d\n", c, name, meth);
    if(!meth) {
	// empty list
    } else if(meth > 0) {
	Smoke::Index i = qt_Smoke->methodMaps[meth].method;
	if(!i) {		// shouldn't happen
	    croak("Corrupt method %s::%s", c, name);
	} else if(i > 0) {	// single match
	    PUSHs(sv_2mortal(newSViv(
		(IV)qt_Smoke->methodMaps[meth].method
	    )));
	} else {		// multiple match
	    i = -i;		// turn into ambiguousMethodList index
	    while(qt_Smoke->ambiguousMethodList[i]) {
		PUSHs(sv_2mortal(newSViv(
		    (IV)qt_Smoke->ambiguousMethodList[i]
		)));
		i++;
	    }
	}
    }

void
findMethodFromIds(idclass, idmethodname)
    int idclass
    int idmethodname
    PPCODE:
    Smoke::Index meth = qt_Smoke->findMethod(idclass, idmethodname);
    if(!meth) {
	// empty list
    } else if(meth > 0) {
	Smoke::Index i = qt_Smoke->methodMaps[meth].method;
	if(i >= 0) {	// single match
	    PUSHs(sv_2mortal(newSViv((IV)i)));
	} else {		// multiple match
	    i = -i;		// turn into ambiguousMethodList index
	    while(qt_Smoke->ambiguousMethodList[i]) {
		PUSHs(sv_2mortal(newSViv(
		    (IV)qt_Smoke->ambiguousMethodList[i]
		)));
		i++;
	    }
	}
    }

# findAllMethods(classid [, startingWith]) : returns { "mungedName" => [index in methods, ...], ... }

HV*
findAllMethods(classid, ...)
    SV* classid
    CODE:
    RETVAL=newHV();
    if(SvIOK(classid)) {
        Smoke::Index c = (Smoke::Index) SvIV(classid);
        char * pat = 0L;
        if(items > 1 && SvPOK(ST(1)))
            pat = SvPV_nolen(ST(1));
        Smoke::Index imax = qt_Smoke->numMethodMaps;
        Smoke::Index imin = 0, icur = -1, methmin = 0, methmax = 0;
        int icmp = -1;
        while(imax >= imin) {
            icur = (imin + imax) / 2;
            icmp = qt_Smoke->leg(qt_Smoke->methodMaps[icur].classId, c);
            if(!icmp) {
                Smoke::Index pos = icur;
                while(icur && qt_Smoke->methodMaps[icur-1].classId == c)
                    icur --;
                methmin = icur;
                icur = pos;
                while(icur < imax && qt_Smoke->methodMaps[icur+1].classId == c)
                    icur ++;
                methmax = icur;
                break;
            }
            if (icmp > 0)
		imax = icur - 1;
	    else
		imin = icur + 1;
        }
        if(!icmp) {
            for(Smoke::Index i=methmin ; i <= methmax ; i++) {
                Smoke::Index m = qt_Smoke->methodMaps[i].name;
                if(!pat || !strncmp(qt_Smoke->methodNames[m], pat, strlen(pat))) {
                    Smoke::Index ix= qt_Smoke->methodMaps[i].method;
                    AV* meths = newAV();
                    if(ix >= 0) {	// single match
                        av_push(meths, newSViv((IV)ix));
                    } else {		// multiple match
                        ix = -ix;		// turn into ambiguousMethodList index
                        while(qt_Smoke->ambiguousMethodList[ix]) {
                          av_push(meths, newSViv((IV)qt_Smoke->ambiguousMethodList[ix]));
                          ix++;
                        }
                    }
                    hv_store(RETVAL, qt_Smoke->methodNames[m],strlen(qt_Smoke->methodNames[m]),newRV_inc((SV*)meths),0);
                }
            }
        }
    }
    OUTPUT:
    RETVAL

SV *
dumpCandidates(rmeths)
    SV *rmeths
    CODE:
    if(SvROK(rmeths) && SvTYPE(SvRV(rmeths)) == SVt_PVAV) {
        AV *methods = (AV*)SvRV(rmeths);
        SV *errmsg = newSVpvf("");
        for(int i = 0; i <= av_len(methods); i++) {
                sv_catpv(errmsg, "\t");
                IV id = SvIV(*(av_fetch(methods, i, 0)));
                Smoke::Method &meth = qt_Smoke->methods[id];
                const char *tname = qt_Smoke->types[meth.ret].name;
                if(meth.flags & Smoke::mf_static) sv_catpv(errmsg, "static ");
                sv_catpvf(errmsg, "%s ", (tname ? tname:"void"));
                sv_catpvf(errmsg, "%s::%s(", qt_Smoke->classes[meth.classId].className, qt_Smoke->methodNames[meth.name]);
                for(int i = 0; i < meth.numArgs; i++) {
                        if(i) sv_catpv(errmsg, ", ");
                        tname = qt_Smoke->types[qt_Smoke->argumentList[meth.args+i]].name;
                        sv_catpv(errmsg, (tname ? tname:"void"));
                }
                sv_catpv(errmsg, ")");
                if(meth.flags & Smoke::mf_const) sv_catpv(errmsg, " const");
                sv_catpv(errmsg, "\n");
        }
        RETVAL=errmsg;
    }
    else
        RETVAL=newSVpvf("");
    OUTPUT:
    RETVAL

SV *
catArguments(r_args)
    SV* r_args
    CODE:
    RETVAL=newSVpvf("");
    if(SvROK(r_args) && SvTYPE(SvRV(r_args)) == SVt_PVAV) {
        AV* args=(AV*)SvRV(r_args);
        for(int i = 0; i <= av_len(args); i++) {
            SV **arg=av_fetch(args, i, 0);
	    if(i) sv_catpv(RETVAL, ", ");
	    if(!arg || !SvOK(*arg)) {
		sv_catpv(RETVAL, "undef");
	    } else if(SvROK(*arg)) {
		smokeperl_object *o = sv_obj_info(*arg);
		if(o)
		    sv_catpv(RETVAL, o->smoke->className(o->classId));
		else
		    sv_catsv(RETVAL, *arg);
	    } else {
		bool isString = SvPOK(*arg);
		STRLEN len;
		char *s = SvPV(*arg, len);
		if(isString) sv_catpv(RETVAL, "'");
		sv_catpvn(RETVAL, s, len > 10 ? 10 : len);
		if(len > 10) sv_catpv(RETVAL, "...");
		if(isString) sv_catpv(RETVAL, "'");
	    }
	}
    }
    OUTPUT:
    RETVAL

SV *
callMethod(...)
    PPCODE:
    if(_current_method) {
	MethodCall c(qt_Smoke, _current_method, &ST(0), items);
	c.next();
	SV *ret = c.var();
	SvREFCNT_inc(ret);
	PUSHs(sv_2mortal(ret));
    } else
	PUSHs(sv_newmortal());

bool
isObject(obj)
    SV *obj
    CODE:
    RETVAL = sv_to_ptr(obj) ? TRUE : FALSE;
    OUTPUT:
    RETVAL

void
setCurrentMethod(meth)
    int meth
    CODE:
    // FIXME: damn, this is lame, and it doesn't handle ambiguous methods
    _current_method = meth;  //qt_Smoke->methodMaps[meth].method;

SV *
getClassList()
    CODE:
    AV *av = newAV();
    for(int i = 1; i <= qt_Smoke->numClasses; i++) {
//printf("%s => %d\n", qt_Smoke->classes[i].className, i);
	av_push(av, newSVpv(qt_Smoke->classes[i].className, 0));
//	hv_store(hv, qt_Smoke->classes[i].className, 0, newSViv(i), 0);
    }
    RETVAL = newRV((SV*)av);
    OUTPUT:
    RETVAL

void
installthis(package)
    char *package
    CODE:
    if(!package) XSRETURN_EMPTY;
    char *name = new char[strlen(package) + 7];
    char *file = __FILE__;
    strcpy(name, package);
    strcat(name, "::this");
    // *{ $name } = sub () : lvalue;
    CV *thissub = newXS(name, XS_this, file);
    sv_setpv((SV*)thissub, "");    // sub this () : lvalue;
    delete[] name;

void
installattribute(package, name)
    char *package
    char *name
    CODE:
    if(!package || !name) XSRETURN_EMPTY;
    char *attr = new char[strlen(package) + strlen(name) + 3];
    sprintf(attr, "%s::%s", package, name);
    char *file = __FILE__;
    // *{ $attr } = sub () : lvalue;
    CV *attrsub = newXS(attr, XS_attr, file);
    sv_setpv((SV*)attrsub, "");
    CvLVALUE_on(attrsub);
    CvNODEBUG_on(attrsub);
    delete[] attr;

void
installsuper(package)
    char *package
    CODE:
    if(!package) XSRETURN_EMPTY;
    char *attr = new char[strlen(package) + 8];
    sprintf(attr, "%s::SUPER", package);
    char *file = __FILE__;
    CV *attrsub = newXS(attr, XS_super, file);
    sv_setpv((SV*)attrsub, "");
    delete[] attr;

void
installautoload(package)
    char *package
    CODE:
    if(!package) XSRETURN_EMPTY;
    char *autoload = new char[strlen(package) + 11];
    strcpy(autoload, package);
    strcat(autoload, "::_UTOLOAD");
    char *file = __FILE__;
    // *{ $package."::AUTOLOAD" } = XS_AUTOLOAD
    newXS(autoload, XS_AUTOLOAD, file);
    delete[] autoload;

# ----------------- XSUBS for Qt:: -----------------

MODULE = Qt   PACKAGE = Qt

SV *
this()
    CODE:
    RETVAL = newSVsv(sv_this);
    OUTPUT:
    RETVAL

SV *
app()
    CODE:
    RETVAL = newRV_inc(sv_qapp);
    OUTPUT:
    RETVAL

SV *
version()
    CODE:
    RETVAL = newSVpv(QT_VERSION_STR,0);
    OUTPUT:
    RETVAL

BOOT:
    init_qt_Smoke();
    qt_Smoke->binding = new QtSmokeBinding(qt_Smoke);
    install_handlers(Qt_handlers);
    pointer_map = newHV();
    sv_this = newSV(0);
    methcache = new QAsciiDict<Smoke::Index>(1187);
    classcache = new QAsciiDict<Smoke::Index>(827);
    methcache->setAutoDelete(1);
    classcache->setAutoDelete(1);
