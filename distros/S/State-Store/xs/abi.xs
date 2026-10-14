# The C ABI's Perl-visible ends: the table's address, its version, and the
# selftest that walks it.

MODULE = State::Store    PACKAGE = State::Store

# Unsigned, not IV: where the loader maps this object decides the sign bit.
UV
_abi_ptr()
    CODE:
        RETVAL = PTR2UV(&STORE_ABI);
    OUTPUT:
        RETVAL

IV
_abi_version()
    CODE:
        RETVAL = STORE_ABI.abi_version;
    OUTPUT:
        RETVAL

# The number of the check that failed, or 0, and then the store it built.
void
_abi_selftest()
    PREINIT:
        SV *st = NULL;
        int step;
    PPCODE:
        step = store_abi_selftest(aTHX_ &st);
        EXTEND(SP, 2);
        PUSHs(sv_2mortal(newSViv(step)));
        PUSHs(st ? sv_2mortal(st) : &PL_sv_undef);
