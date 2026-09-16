# The C ABI's Perl-visible ends: the table's address, its version, and the
# selftest that walks it.

MODULE = Struct::Codec    PACKAGE = Struct::Codec

# Unsigned, not IV: where the loader maps this object decides the sign bit, and
# a 32-bit perl above 0x7fffffff would hand back a negative from PTR2IV.
UV
_abi_ptr()
    CODE:
        RETVAL = PTR2UV(&SC_ABI);
    OUTPUT:
        RETVAL

IV
_abi_version()
    CODE:
        RETVAL = SC_ABI.abi_version;
    OUTPUT:
        RETVAL

# (step, bytes, data): 0 when every entry answered as its declaration says,
# otherwise the number of the check that did not - so a failure names itself
# rather than sending somebody to read the whole table. The bytes and the
# structure the C side built come back too, so a Perl test can compare the
# table's encoding with the Perl surface's for the same data.
void
_abi_selftest()
    PREINIT:
        int step = 0;
        SV *data = NULL;
        SV *bytes;
    PPCODE:
        bytes = sc_abi_selftest(aTHX_ &step, &data);
        EXTEND(SP, 3);
        mPUSHi(step);
        PUSHs(bytes ? sv_2mortal(bytes) : &PL_sv_undef);
        PUSHs(data  ? sv_2mortal(data)  : &PL_sv_undef);
