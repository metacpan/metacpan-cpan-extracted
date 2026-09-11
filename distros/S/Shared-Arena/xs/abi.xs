# The C ABI's Perl-visible ends: the table's address, its version, and the
# selftest that walks it.

MODULE = Shared::Arena    PACKAGE = Shared::Arena

# Unsigned, not IV: where the loader maps this object decides the sign bit, and
# a 32-bit perl above 0x7fffffff would hand back a negative from PTR2IV.
UV
_abi_ptr()
    CODE:
        RETVAL = PTR2UV(&SA_ABI);
    OUTPUT:
        RETVAL

IV
_abi_version()
    CODE:
        RETVAL = SA_ABI.abi_version;
    OUTPUT:
        RETVAL

# 0 when every entry answered as its declaration says, otherwise the number of
# the check that did not - so a failure names itself rather than sending
# somebody to read the whole table.
IV
_abi_selftest()
    CODE:
        RETVAL = (IV)sa_abi_selftest();
    OUTPUT:
        RETVAL
