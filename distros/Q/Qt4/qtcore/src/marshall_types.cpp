#include <QHash>
#include <QMap>
#include <QVector>
#include <QMetaObject>
#include <QMetaMethod>
#include <QPalette>

#include "smoke.h"
#include "marshall_types.h"
#include "smokeperl.h" // for smokeperl_object
#include "smokehelp.h" // for SmokeType and SmokeClass
#include "handlers.h" // for getMarshallType
#include "QtCore4.h" // for extern sv_this
#include "util.h" // for caller()

extern Smoke* qtcore_Smoke;

void
smokeStackToQt4Stack(Smoke::Stack stack, void ** o, int start, int end, QList<MocArgument*> args)
{
    for (int i = start, j = 0; i < end; ++i, ++j) {
        Smoke::StackItem *si = stack + j;
        switch(args[i]->argType) {
            case xmoc_bool:
                o[j] = &si->s_bool;
                break;
            case xmoc_int:
                o[j] = &si->s_int;
                break;
            case xmoc_uint:
                o[j] = &si->s_uint;
                break;
            case xmoc_long:
                o[j] = &si->s_long;
                break;
            case xmoc_ulong:
                o[j] = &si->s_ulong;
                break;
            case xmoc_double:
                o[j] = &si->s_double;
                break;
            case xmoc_charstar:
                o[j] = &si->s_voidp;
                break;
            case xmoc_QString:
                o[j] = si->s_voidp;
                break;
            default: {
                const SmokeType &t = args[i]->st;
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
                    case Smoke::t_enum: {
                        // allocate a new enum value
                        //Smoke::EnumFn fn = SmokeClass(t).enumFn();
                        Smoke::Class* _c = t.smoke()->classes + t.classId();
                        Smoke::EnumFn fn = _c->enumFn;
                        if (!fn) {
                            croak("Unknown enumeration %s\n", t.name());
                            p = new int((int)si->s_enum);
                            break;
                        }
                        Smoke::Index id = t.typeId();
                        (*fn)(Smoke::EnumNew, id, p, si->s_enum);
                        (*fn)(Smoke::EnumFromLong, id, p, si->s_enum);
                        // FIXME: MEMORY LEAK
                        break;
                    }
                    case Smoke::t_class:
                    case Smoke::t_voidp:
                        if (strchr(t.name(), '*') != 0) {
                            p = &si->s_voidp;
                        } else {
                            p = si->s_voidp;
                        }
                        break;
                    default:
                        p = 0;
                        break;
                }
                o[j] = p;
            }
        }
    }
}

void
smokeStackFromQt4Stack(Smoke::Stack stack, void ** _o, int start, int end, QList<MocArgument*> args)
{
    for (int i = start, j = 0; i < end; ++i, ++j) {
        void *o = _o[j];
        switch(args[i]->argType) {
            case xmoc_bool:
                stack[j].s_bool = *(bool*)o;
                break;
            case xmoc_int:
                stack[j].s_int = *(int*)o;
                break;
            case xmoc_uint:
                stack[j].s_uint = *(uint*)o;
                break;
            case xmoc_long:
                stack[j].s_long = *(long*)o;
                break;
            case xmoc_ulong:
                stack[j].s_ulong = *(ulong*)o;
                break;
            case xmoc_double:
                stack[j].s_double = *(double*)o;
                break;
            case xmoc_charstar:
                stack[j].s_voidp = o;
                break;
            case xmoc_QString:
                stack[j].s_voidp = o;
                break;
            default: { // case xmoc_ptr:
                const SmokeType &t = args[i]->st;
                void *p = o;
                switch(t.elem()) {
                    case Smoke::t_bool:
                        stack[j].s_bool = *(bool*)o;
                        break;
                    case Smoke::t_char:
                        stack[j].s_char = *(char*)o;
                        break;
                    case Smoke::t_uchar:
                        stack[j].s_uchar = *(unsigned char*)o;
                        break;
                    case Smoke::t_short:
                        stack[j].s_short = *(short*)p;
                        break;
                    case Smoke::t_ushort:
                        stack[j].s_ushort = *(unsigned short*)p;
                        break;
                    case Smoke::t_int:
                        stack[j].s_int = *(int*)p;
                        break;
                    case Smoke::t_uint:
                        stack[j].s_uint = *(unsigned int*)p;
                        break;
                    case Smoke::t_long:
                        stack[j].s_long = *(long*)p;
                        break;
                    case Smoke::t_ulong:
                        stack[j].s_ulong = *(unsigned long*)p;
                        break;
                    case Smoke::t_float:
                        stack[j].s_float = *(float*)p;
                        break;
                    case Smoke::t_double:
                        stack[j].s_double = *(double*)p;
                        break;
                    case Smoke::t_enum:
                        {
                            //Smoke::EnumFn fn = SmokeClass(t).enumFn();
                            Smoke::Class* _c = t.smoke()->classes + t.classId();
                            Smoke::EnumFn fn = _c->enumFn;
                            if (!fn) {
                                croak("Unknown enumeration %s\n", t.name());
                                stack[j].s_enum = **(int**)p;
                                break;
                            }
                            Smoke::Index id = t.typeId();
                            (*fn)(Smoke::EnumToLong, id, p, stack[j].s_enum);
                        }
                        break;
                    case Smoke::t_class:
                    case Smoke::t_voidp:
                        if (strchr(t.name(), '*') != 0) {
                            stack[j].s_voidp = *(void **)p;
                        } else {
                            stack[j].s_voidp = p;
                        }
                        break;
                }
            }
        }
    }
}

namespace PerlQt4 {

    MethodReturnValueBase::MethodReturnValueBase(Smoke *smoke, Smoke::Index methodIndex, Smoke::Stack stack) :
      _smoke(smoke), _methodIndex(methodIndex), _stack(stack) {
        _type = SmokeType(_smoke, method().ret);
    }

    const Smoke::Method &MethodReturnValueBase::method() {
        return _smoke->methods[_methodIndex];
    }

    Smoke::StackItem &MethodReturnValueBase::item() {
        return _stack[0];
    }

    Smoke *MethodReturnValueBase::smoke() {
        return _smoke;
    }

    SmokeType MethodReturnValueBase::type() {
        return _type;
    }

    void MethodReturnValueBase::next() {
    }

    bool MethodReturnValueBase::cleanup() {
        return false;
    }

    void MethodReturnValueBase::unsupported() {
        COP* callercop = caller(0);
        croak("Cannot handle '%s' as return-type of %s::%s at %s line %lu\n",
            type().name(),
            _smoke->className(method().classId),
            _smoke->methodNames[method().name],
            GvNAME(CopFILEGV(callercop))+2,
            CopLINE(callercop));
    }

    SV* MethodReturnValueBase::var() {
        return _retval;
    }

    //------------------------------------------------

    VirtualMethodReturnValue::VirtualMethodReturnValue(Smoke *smoke, Smoke::Index methodIndex, Smoke::Stack stack, SV *retval) :
      MethodReturnValueBase(smoke, methodIndex, stack) {
        _retval = retval;
        Marshall::HandlerFn fn = getMarshallFn(type());
        (*fn)(this);
    }
    
    Marshall::Action VirtualMethodReturnValue::action() {
        return Marshall::FromSV;
    }

    //------------------------------------------------

    MethodReturnValue::MethodReturnValue(Smoke *smoke, Smoke::Index methodIndex, Smoke::Stack stack) :
      MethodReturnValueBase(smoke, methodIndex, stack)  {
        _retval = newSV(0);
        Marshall::HandlerFn fn = getMarshallFn(type());
        (*fn)(this);
    }

    MethodReturnValue::MethodReturnValue(Smoke *smoke, Smoke::Stack stack, SmokeType type) :
      MethodReturnValueBase(smoke, 0, stack) {
        _retval = newSV(0);
        _type = type;
        Marshall::HandlerFn fn = getMarshallFn(this->type());
        (*fn)(this);
    }

    // We're passing an SV back to perl
    Marshall::Action MethodReturnValue::action() {
        return Marshall::ToSV;
    }

    //------------------------------------------------

    SlotReturnValue::SlotReturnValue(void ** o, SV * result, QList<MocArgument*> replyType) :
      _replyType(replyType), _result(result) {
        _stack = new Smoke::StackItem[1];
        Marshall::HandlerFn fn = getMarshallFn(type());
        (*fn)(this);

        QByteArray t(type().name());
        t.replace("const ", "");
        t.replace("&", "");

        if (perlqt_modules[smoke()].slot_returnvalue) {
            Smoke::ModuleIndex classId = smoke()->idClass(t.constData(), true);
            if (!perlqt_modules[smoke()].slot_returnvalue(classId, o, _stack)) {
                // module did not handle this type, do the default
                smokeStackToQt4Stack(_stack, o, 0, 1, _replyType);
            }
        }
        else {
            smokeStackToQt4Stack(_stack, o, 0, 1, _replyType);
        }
    }

    Smoke::StackItem &SlotReturnValue::item() {
        return _stack[0];
    }

    Smoke *SlotReturnValue::smoke() {
        return type().smoke();
    }

    SmokeType SlotReturnValue::type() {
        return _replyType[0]->st;
    }

    Marshall::Action SlotReturnValue::action() {
         return Marshall::FromSV;
    }

    void SlotReturnValue::next() {}

    bool SlotReturnValue::cleanup() {
        return false;
    }

    void SlotReturnValue::unsupported() {
        croak("Cannot handle '%s' as return-type of slot", //%s::%s for slot return value",
            type().name()
            //smoke()->className(method().classId),
            //smoke()->methodNames[method().name]);
        );
    }

    SV* SlotReturnValue::var() {
        return _result;
    }

    SlotReturnValue::~SlotReturnValue() {
        delete[] _stack;
    }

    //------------------------------------------------

    MethodCallBase::MethodCallBase(Smoke *smoke, Smoke::Index meth) :
        _smoke(smoke), _method(meth), _cur(-1), _called(false), _sp(0)  
    {  
    }

    MethodCallBase::MethodCallBase(Smoke *smoke, Smoke::Index meth, Smoke::Stack stack) :
        _smoke(smoke), _method(meth), _stack(stack), _cur(-1), _called(false), _sp(0) 
    {  
    }

    Smoke *MethodCallBase::smoke() { 
        return _smoke; 
    }

    SmokeType MethodCallBase::type() { 
        return SmokeType(_smoke, _args[_cur]); 
    }

    Smoke::StackItem &MethodCallBase::item() { 
        return _stack[_cur + 1]; 
    }

    const Smoke::Method &MethodCallBase::method() { 
        return _smoke->methods[_method]; 
    }

    void MethodCallBase::next() {
        int oldcur = _cur;
        _cur++;
        while( !_called && _cur < items() ) {
            Marshall::HandlerFn fn = getMarshallFn(type());

            // The handler will call this function recursively.  The control
            // flow looks like: 
            // MethodCallBase::next -> TypeHandler fn -> recurse back to next()
            // until all variables are marshalled -> callMethod -> TypeHandler
            // fn to clean up any variables they create
            (*fn)(this);
            _cur++;
        }

        callMethod();
        _cur = oldcur;
    }

    void MethodCallBase::unsupported() {
        COP* callercop = caller(0);
        croak("Cannot handle '%s' as argument of virtual method %s::%s"
            "at %s line %lu\n",
            type().name(),
            _smoke->className(method().classId),
            _smoke->methodNames[method().name],
            GvNAME(CopFILEGV(callercop))+2,
            CopLINE(callercop));
    }

    const char* MethodCallBase::classname() {
        return _smoke->className(method().classId);
    }

    //------------------------------------------------

    VirtualMethodCall::VirtualMethodCall(Smoke *smoke, Smoke::Index meth, Smoke::Stack stack, SV *obj, GV *gv) :
      MethodCallBase(smoke,meth,stack), _gv(gv){
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        EXTEND(SP, items());
        _savethis = sv_this;
        sv_this = newSVsv(obj);
        _sp = SP + 1;
        for(int i = 0; i < items(); i++)
            _sp[i] = sv_newmortal();
        _args = _smoke->argumentList + method().args;
    }

    VirtualMethodCall::~VirtualMethodCall() {
        SvREFCNT_dec(sv_this);
        sv_this = _savethis;
    }

    Marshall::Action VirtualMethodCall::action() {
        return Marshall::ToSV;
    }

    SV *VirtualMethodCall::var() {
        return _sp[_cur];
    }

    int VirtualMethodCall::items() {
        return method().numArgs;
    }

    void VirtualMethodCall::callMethod() {
        if (_called) return;
        _called = true;

        // This is the stack pointer we'll pass to the perl call
        dSP;
        // This defines how many arguments we're sending to the perl sub
        SP = _sp + items() - 1;
        PUTBACK;
        I32 callFlags = G_SCALAR;
        if ( SvTRUE( get_sv("Qt::_internal::isEmbedded", FALSE) ) ) {
            callFlags |= G_EVAL;
        }
        // Call the perl sub
        call_sv((SV*)GvCV(_gv), callFlags);
        if( SvTRUE(ERRSV) ) {
            STRLEN n_a;
            fprintf( stderr, "Error in Perl plugin: $@: %s\n", SvPVx(ERRSV, n_a));
            PUTBACK;
            FREETMPS;
            LEAVE;
            return;
        }
        // Get the stack the perl sub returned
        SPAGAIN;
        // Marshall the return value back to c++, using the top of the stack
        VirtualMethodReturnValue r(_smoke, _method, _stack, POPs);
        if ( r.type().isClass() ) {
            const char* typeOfInput = get_SVt(r.var());
            if (strlen(typeOfInput) == 1) {
                switch( *typeOfInput ) {
                    case 's':
                        croak( "Expected return value of type %s, but got a "
                               "string", r.type().name() );
                        break;
                    case 'i':
                    case 'n':
                        croak( "Expected return value of type %s, but got a "
                               "numeric value", r.type().name() );
                        break;
                    case 'u':
                    case 'U':
                        if ( !r.type().flags() & Smoke::tf_ptr )
                            croak( "Expected return value of type %s, but got an "
                                   "undefined value", r.type().name() );
                }
            }
            else {
                smokeperl_object* o = sv_obj_info(r.var());
                if ( ( !o || !o->ptr ) && !(r.type().flags() & Smoke::tf_ptr) ) {
                    croak( "Expected return of type %s, but got an undefined value",
                        r.type().smoke()->classes[r.type().classId()].className
                    );
                }
                Smoke::ModuleIndex type( o->smoke, o->classId );
                Smoke::ModuleIndex baseType;
                Smoke::Class returnType = r.type().smoke()->classes[r.type().classId()];
                if ( returnType.external ) {
                    const char* returnCxxClassname = returnType.className;
                    baseType = Smoke::classMap[returnCxxClassname];
                }
                else {
                    baseType = Smoke::ModuleIndex( r.type().smoke(), r.type().classId() );
                }

                if (!Smoke::isDerivedFrom( type, baseType )) {
                    croak( "Expected return of type %s, but got type %s",
                        r.type().smoke()->classes[r.type().classId()].className,
                        o->smoke->classes[o->classId].className
                    );
                }
            }
        }
        PUTBACK;
        FREETMPS;
        LEAVE;

    }

    bool VirtualMethodCall::cleanup() {
        return false;
    }

    //------------------------------------------------

    MethodCall::MethodCall(Smoke *smoke, Smoke::Index method, smokeperl_object *call_this, SV **sp, int items):
      MethodCallBase(smoke,method), _this(call_this), _sp(sp), _items(items) {
        if ( !(this->method().flags & (Smoke::mf_static|Smoke::mf_ctor)) && _this->ptr == 0 ) {
            COP* callercop = caller(0);
            croak( "%s::%s(): Non-static method called with no \"this\" value "
                "at %s line %lu\n",
                _smoke->className(this->method().classId),
                _smoke->methodNames[this->method().name],
                GvNAME(CopFILEGV(callercop))+2,
                CopLINE(callercop) );
        }
        _stack = new Smoke::StackItem[items + 1];
        _args = _smoke->argumentList + _smoke->methods[_method].args;
        _retval = newSV(0);
    }

    MethodCall::~MethodCall() {
        delete[] _stack;
    }

    Marshall::Action MethodCall::action() {
        return Marshall::FromSV;
    }

    SV *MethodCall::var() {
        if(_cur < 0)
            return _retval;
        return *(_sp + _cur);
    }

    int MethodCall::items() {
        return _items;
    }

    bool MethodCall::cleanup() {
        return true;
    }

    const char *MethodCall::classname() {
        return MethodCallBase::classname();
    }

    //------------------------------------------------

    MarshallSingleArg::MarshallSingleArg(Smoke *smoke, SV* sv, SmokeType type) :
      MethodCallBase(smoke, 0) {
        _type = type;
        _sv = sv;
        _stack = new Smoke::StackItem[1];
        Marshall::HandlerFn fn = getMarshallFn(this->type());
        _cur = 0;
        (*fn)(this);
    }

    MarshallSingleArg::~MarshallSingleArg() {
        delete[] _stack;
    }

    // We're passing an SV from perl to c++
    Marshall::Action MarshallSingleArg::action() {
        return Marshall::FromSV;
    }

    SmokeType MarshallSingleArg::type() {
        return this->_type;
    }

    SV *MarshallSingleArg::var() {
        return _sv;
    }

    int MarshallSingleArg::items() {
        return 1;
    }

    bool MarshallSingleArg::cleanup() {
        return false;
    }

    const char *MarshallSingleArg::classname() {
        return 0;
    }

    Smoke::StackItem &MarshallSingleArg::item() {
        return _stack[0];
    }
    //------------------------------------------------

    // The steps are:
    // Copy Qt4 stack to Smoke Stack
    // use next() to marshall the smoke stack
    // callMethod()
    // The rest is modeled after the VirtualMethodCall
    InvokeSlot::InvokeSlot(SV* call_this, char* methodname, QList<MocArgument*> args, void** a) :
      _args(args), _cur(-1), _called(false), _this(call_this), _a(a) {

        // _args[0] represents what would be the return value, which isn't an
        // actual argument.  Subtract 1 to account for this.
        _items = _args.count() - 1;
        _stack = new Smoke::StackItem[_items];
        // Create this on the heap.  Just saying _methodname = methodname only
        // leaves enough space for 1 char.
        _methodname = new char[strlen(methodname)+1];
        strcpy(_methodname, methodname);
        _sp = new SV*[_items];
        for(int i = 0; i < _items; ++i)
            _sp[i] = sv_newmortal();
        copyArguments();
    }

    InvokeSlot::~InvokeSlot() {
        delete[] _stack;
        delete[] _methodname;
    }

    Smoke *InvokeSlot::smoke() {
        return type().smoke();
    }

    Marshall::Action InvokeSlot::action() {
        return Marshall::ToSV;
    }

    const MocArgument& InvokeSlot::arg() {
        return *(_args[_cur + 1]);
    }

    SmokeType InvokeSlot::type() {
        return arg().st;
    }

    Smoke::StackItem &InvokeSlot::item() {
        return _stack[_cur];
    }

    SV* InvokeSlot::var() {
        return _sp[_cur];
    }

    void InvokeSlot::callMethod() {
        if (_called) return;
        _called = true;
        //Call the perl sub
        //Copy the way the VirtualMethodCall does it
        HV *stash = SvSTASH(SvRV(_this));
        if(*HvNAME(stash) == ' ' ) // if withObject, look for a diff stash
            stash = gv_stashpv(HvNAME(stash) + 1, TRUE);

        GV *gv = gv_fetchmethod_autoload(stash, _methodname, 0);
        if(!gv) {
            fprintf( stderr, "Found no method named %s to call in slot\n", _methodname );
            return;
        }

#ifdef PERLQTDEBUG
        if(do_debug && (do_debug & qtdb_slots)) {
            fprintf( stderr, "In slot call %s::%s\n", HvNAME(stash), _methodname );
            if(do_debug & qtdb_verbose) {
                fprintf(stderr, "with arguments (%s)\n", SvPV_nolen(sv_2mortal(catArguments(_sp, _items))));
            }
        }
#endif
        
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        EXTEND(SP, _items);
        for(int i=0;i<_items;++i){
            PUSHs(_sp[i]);
        }
        PUTBACK;
        int count = call_sv((SV*)GvCV(gv), _args[0]->argType == xmoc_void ? G_VOID : G_SCALAR);
        if ( count > 0 && _args[0]->argType != xmoc_void ) {
            SlotReturnValue r(_a, POPs, _args);
        }
        FREETMPS;
        LEAVE;
    }

    void InvokeSlot::next() {
        int oldcur = _cur;
        ++_cur;
        while( !_called && _cur < _items ) {
            Marshall::HandlerFn fn = getMarshallFn(type());
            (*fn)(this);
            ++_cur;
        }

        callMethod();
        _cur = oldcur;
    }

    void InvokeSlot::unsupported() {
        COP* callercop = caller(0);
        croak("Cannot handle '%s' as argument of slot call"
            "at %s line %lu\n",
            type().name(),
            GvNAME(CopFILEGV(callercop))+2,
            CopLINE(callercop));
    }

    bool InvokeSlot::cleanup() {
        return false;
    }

    void InvokeSlot::copyArguments() {
        smokeStackFromQt4Stack( _stack, _a + 1, 1, _items + 1, _args );
    }

    //------------------------------------------------

    EmitSignal::EmitSignal(QObject *obj, const QMetaObject *meta, int id, int items, QList<MocArgument*> args, SV** sp, SV* retval) :
      _args(args), _cur(-1), _called(false), _items(items), _obj(obj), _meta(meta), _id(id), _retval(retval) {
        _sp = sp;
        _stack = new Smoke::StackItem[_items];
    }

    Marshall::Action EmitSignal::action() {
        return Marshall::FromSV;
    }

    const MocArgument& EmitSignal::arg() {
        return *(_args[_cur + 1]);
    }

    SmokeType EmitSignal::type() {
        return arg().st;
    }

    Smoke::StackItem &EmitSignal::item() {
        return _stack[_cur];
    }

    SV* EmitSignal::var() {
        return _sp[_cur];
    }

    Smoke *EmitSignal::smoke() {
        return type().smoke();
    }

    void EmitSignal::callMethod() {
        if (_called) return;
        _called = true;

        // Create the stack to send to the slots
        // +1 to _items to accomidate the return value
        void** o = new void*[_items+1];

        // o+1 because o[0] is the return value. _items+1 because we have to
        // accomidate for the offset of o[0] already being used
        smokeStackToQt4Stack(_stack, o + 1, 1, _items + 1, _args);
        // The 0 index stores the return value
        void* ptr;
        o[0] = &ptr;
        prepareReturnValue(o);

        _meta->activate(_obj, _id, o);
    }

    void EmitSignal::unsupported() {
        croak("Cannot handle '%s' as argument of slot call",
              type().name() );
    }

    void EmitSignal::next() {
        int oldcur = _cur;
        ++_cur;

        while(_cur < _items) {
            Marshall::HandlerFn fn = getMarshallFn(type());
            (*fn)(this);
            ++_cur;
        }

        callMethod();
        _cur = oldcur;
    }

    bool EmitSignal::cleanup() {
        return false;
    }

    void EmitSignal::prepareReturnValue(void** o){
        if (_args[0]->argType == xmoc_ptr) {
            QByteArray type(_args[0]->st.name());
            type.replace("const ", "");
            if (!type.endsWith('*')) {  // a real pointer type, so a simple void* will do
                if (type.endsWith('&')) {
                    type.resize(type.size() - 1);
                }
                if (type.startsWith("QList")) {
                    o[0] = new QList<void*>;
                } else if (type.startsWith("QVector")) {
                    o[0] = new QVector<void*>;
                } else if (type.startsWith("QHash")) {
                    o[0] = new QHash<void*, void*>;
                } else if (type.startsWith("QMap")) {
                    o[0] = new QMap<void*, void*>;
                //} else if (type == "QDBusVariant") {
                    //o[0] = new QDBusVariant;
                } else {
                    Smoke::ModuleIndex ci = qtcore_Smoke->findClass(type);
                    if (ci.index != 0) {
                        Smoke::ModuleIndex mi = ci.smoke->findMethod(type, type);
                        if (mi.index) {
                            Smoke::Class& c = ci.smoke->classes[ci.index];
                            Smoke::Method& meth = mi.smoke->methods[mi.smoke->methodMaps[mi.index].method];
                            Smoke::StackItem _stack[1];
                            c.classFn(meth.method, 0, _stack);
                            o[0] = _stack[0].s_voidp;
                        }
                    }
                }
            }
        } else if (_args[0]->argType == xmoc_QString) {
            o[0] = new QString;
        }
    }
} // End namespace PerlQt4
