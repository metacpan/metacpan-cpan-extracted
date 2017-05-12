#include "smokeperl.h"

class SmokePerlQt : public SmokePerl {
public:
    SmokePerlQt();
    virtual ~SmokePerlQt();

    void registerSmoke(const char *name, Smoke *smoke);
    Smoke *getSmoke(const char *name);

    void registerHandlers(TypeHandler *h);

    SmokeObject newObject(void *p, const SmokeClass &c);
    SmokeObject wrapObject(void *p, const SmokeClass &c);
    SmokeObject getObject(void *p);
    SmokeObject getObject(SV *sv);

private:
    HV *_registered_smoke;
    HV *_registered_handlers;
    HV *_remembered_pointers;

    void rememberPointer(SmokeObject &o, const SmokeClass &c, bool remember, void *lastptr = 0);
    void rememberPointer(SmokeObject &o);
    void forgetPointer(SmokeObject &o);
    SmokeObject createObject(void *p, const SmokeClass &c);

    const char *getSmokeName(Smoke *smoke) {
	static const char none[] = "";
	HE *he;

	hv_iterinit(_registered_smoke);
	while(he = hv_iternext(_registered_smoke)) {
	    SV *sv = hv_iterval(_registered_smoke, he);
	    if((Smoke*)SvIV(sv) == smoke) {
		I32 toss;
		return hv_iterkey(he, &toss);
	    }
	}
	return none;
    }

    HV *package(const SmokeClass &c) {
	// for now, we cheat on the class names by assuming they're all Qt::
	if(!strcmp(c.className(), "Qt"))
	    return gv_stashpv(c.className(), TRUE);

	SV *name = newSVpv("Qt::", 0);
	sv_catpv(name, c.className() + 1);
	HV *stash = gv_stashpv(SvPV_nolen(name), TRUE);
	SvREFCNT_dec(name);

	return stash;
    }
};


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

extern SV *sv_this;
extern void *_current_object;
extern Smoke::Index _current_object_class;
extern int object_count;
extern bool temporary_virtual_function_success;
extern struct mgvtbl vtbl_smoke;

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
	int count = call_sv((SV*)_gv, G_SCALAR);
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
	    _sp[_cur] = sv_newmortal();
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

class SmokeBindingQt : public SmokeBinding {
    SmokePerlQt *_smokeperl;
public:
    SmokeBindingQt(Smoke *s, SmokePerlQt *smokeperl) :
	SmokeBinding(s), _smokeperl(smokeperl) {}
    void deleted(Smoke::Index classId, void *ptr) {
	if(do_debug) printf("%p->~%s()\n", ptr, smoke->className(classId));
	object_count--;
	if(do_debug) printf("Remaining objects: %d\n", object_count);
	SV *obj = getPointerObject(ptr);
	smokeperl_object *o = sv_obj_info(obj);
	if(!o || !o->ptr) {
	    return;
	}
	unmapPointer(o, o->classId, 0);
	o->ptr = 0;
    }
    bool callMethod(Smoke::Index method, void *ptr, Smoke::Stack args, bool isAbstract) {
	SV *obj = getPointerObject(ptr);
	smokeperl_object *o = sv_obj_info(obj);
	if(do_debug) printf("virtual %p->%s::%s() called\n", ptr,
	    smoke->classes[smoke->methods[method].classId].className,
	    smoke->methodNames[smoke->methods[method].name]
        );

	if(!o) {
	    if(!PL_dirty)   // if not in global destruction
		warn("Cannot find object for virtual method");
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

SmokePerlQt::SmokePerlQt() {
    _registered_smoke = newHV();
    _registered_handlers = newHV();
    _remembered_pointers = newHV();
}

SmokePerlQt::~SmokePerlQt() {
    SvREFCNT_dec((SV*)_registered_smoke);
    SvREFCNT_dec((SV*)_registered_handlers);
    SvREFCNT_dec((SV*)_remembered_pointers);
}

void SmokePerlQt::registerSmoke(const char *name, Smoke *smoke) {
    hv_store(_registered_smoke, name, strlen(name), newSViv((IV)smoke), 0);

    // This will also need to handle the per-class initialization
    smoke->binding = new SmokeBindingQt(smoke, this);
}

Smoke *SmokePerlQt::getSmoke(const char *name) {
    SV **svp = hv_fetch(_registered_smoke, name, strlen(name), 0);
    if(svp && SvOK(*svp))
	return (Smoke*)SvIV(*svp);
    return 0;
}

void SmokePerlQt::registerHandlers(TypeHandler *h) {
    while(h->name) {
	hv_store(_registered_handlers, h->name, strlen(h->name), newSViv((IV)h->fn), 0);
	h++;
    }
}

SmokeObject SmokePerlQt::createObject(void *p, const SmokeClass &c) {
    HV *hv = newHV();
    SV *obj = newRV_noinc((SV*)hv);

    Smoke_MAGIC m(p, c);
    sv_magic((SV*)hv, (SV*)newAV(), '~', (char*)&m, sizeof(m));
    MAGIC *mg = mg_find((SV*)hv, '~');
    mg->mg_virtual = &vtbl_smoke;

    sv_bless(obj, package(c));

    SmokeObject o(obj, (Smoke_MAGIC*)mg->mg_ptr);
    SvREFCNT_dec(obj);

    if(c.hasVirtual())
	rememberPointer(o);

    return o;
}

SmokeObject SmokePerlQt::newObject(void *p, const SmokeClass &c) {
    SmokeObject o = createObject(p, c);

    if(c.isVirtual())
	rememberPointer(o);
    o.setAllocated(true);

    return o;
}

SmokeObject SmokePerlQt::wrapObject(void *p, const SmokeClass &c) {
    SmokeObject o = createObject(p, c);
    return o;
}

void SmokePerlQt::rememberPointer(SmokeObject &o, const SmokeClass &c, bool remember, void *lastptr) {
    void *ptr = o.cast(c);
    if(ptr != lastptr) {
	SV *keysv = newSViv((IV)o.ptr());    
	STRLEN klen;
	char *key = SvPV(keysv, klen);

	if(remember)
	    hv_store(_remembered_pointers, key, klen,
		     sv_rvweaken(newSVsv(o.var())), 0);
	else
	    hv_delete(_remembered_pointers, key, klen, G_DISCARD);

	SvREFCNT_dec(keysv);
    }
    for(Smoke::Index *i = c.smoke()->inheritanceList + c.c().parents;
	*i;
	i++)
	rememberPointer(o, SmokeClass(c.smoke(), *i), remember, ptr);
}

void SmokePerlQt::rememberPointer(SmokeObject &o) {
    rememberPointer(o, o.c(), true);
}

void SmokePerlQt::forgetPointer(SmokeObject &o) {
    rememberPointer(o, o.c(), false);
}

SmokeObject SmokePerlQt::getObject(SV *sv) {
    MAGIC *mg = mg_find(SvRV(sv), '~');
    Smoke_MAGIC *m = (Smoke_MAGIC*)mg->mg_ptr;
    return SmokeObject(sv, m);
}

SmokeObject SmokePerlQt::getObject(void *p) {
    SV *keysv = newSViv((IV)p);
    STRLEN klen;
    char *key = SvPV(keysv, klen);
    SV **svp = hv_fetch(_remembered_pointers, key, klen, 0);
    if(svp && SvROK(*svp))
	return getObject(sv_2mortal(newRV(SvRV(*svp))));   // paranoid copy of a weak ref
    return SmokeObject(&PL_sv_undef, 0);
}

