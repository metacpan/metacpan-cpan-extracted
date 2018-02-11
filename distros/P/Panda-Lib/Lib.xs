#include <xs/xs.h>
#include <stdint.h>
#include <panda/lib.h>
#include <xs/lib/cmp.h>
#include <xs/lib/clone.h>
#include <xs/lib/merge.h>
#include <panda/string.h>
#include <panda/log.h>
#include <xs/lib/XSCallbackDispatcher.h>
#include <xs/lib/NativeCallbackDispatcher.h>

using namespace panda::lib;
using namespace panda;
using namespace xs::lib;
using xs::SvIntrPtr;

MODULE = Panda::Lib                PACKAGE = Panda::Lib
PROTOTYPES: DISABLE

uint64_t hash64 (SV* source) : ALIAS(string_hash=1) {
    STRLEN len;
    const char* str = SvPV(source, len);
    RETVAL = hash64(str, len);
    PERL_UNUSED_VAR(ix);
}

uint32_t hash32 (SV* source) : ALIAS(string_hash32=1) {
    STRLEN len;
    const char* str = SvPV(source, len);
    RETVAL = hash32(str, len);
    PERL_UNUSED_VAR(ix);
}

uint64_t hash_murmur64a (SV* source) {
    STRLEN len;
    const char* str = SvPV(source, len);
    RETVAL = hash_murmur64a(str, len);
}

uint32_t hash_jenkins_one_at_a_time (SV* source) {
    STRLEN len;
    const char* str = SvPV(source, len);
    RETVAL = hash_jenkins_one_at_a_time(str, len);
}

SV* crypt_xor (SV* source_string, SV* key_string) {
    STRLEN slen, klen;
    char* str = SvPV(source_string, slen);
    char* key = SvPV(key_string, klen);
    RETVAL = newSV(slen+1);
    SvPOK_on(RETVAL);
    SvCUR_set(RETVAL, slen);
    crypt_xor(str, slen, key, klen, SvPVX(RETVAL));
}

SV* hash_merge (HV* dest, HV* source, int flags = 0) {
    HV* result = hash_merge(aTHX_ dest, source, flags);
    if (result == dest) { // hash not changed - return the same RV for speed
        RETVAL = ST(0);
        SvREFCNT_inc_simple_void_NN(RETVAL);
    }
    else RETVAL = newRV_noinc((SV*)result);
}

SV* merge (SV* dest, SV* source, int flags = 0) {
    RETVAL = merge(aTHX_ dest, source, flags);
    if (RETVAL == dest) SvREFCNT_inc_simple_void_NN(RETVAL);
}

SV* lclone (SV* source) {
    RETVAL = clone(aTHX_ source, false);
}

SV* fclone (SV* source) {
    RETVAL = clone(aTHX_ source, true);
}

SV* clone (SV* source, bool cross = false) {
    RETVAL = clone(aTHX_ source, cross);
}

bool compare (SV* first, SV* second) {
    RETVAL = sv_compare(aTHX_ first, second);
}

void set_native_logger(CV* cb) {
    xs::SvIntrPtr cb_ptr(cb);
    struct CatchLogger : panda::logger::ILogger {
        xs::SvIntrPtr cb;
    
        virtual void log(panda::logger::Level l, panda::logger::CodePoint cp, const std::string& s) override {
            dTHX;
            auto cp_str = cp.to_string();
            SV* args[] = {newSViv(l), newSVpv(cp_str.c_str(), cp_str.size()), newSVpv(s.c_str(), s.size())};
            xs::call_sub_void(aTHX_ cb.get<CV>(), args, 3);
        }
    };
    auto log = new CatchLogger;
    log->cb = cb_ptr;
    panda::Log::logger().reset(log);
}

INCLUDE: CallbackDispatcher.xsi

INCLUDE: NativeCallbackDispatcher.xsi
