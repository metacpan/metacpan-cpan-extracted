/* vi: set ft=c : */
#if HAVE_PERL_VERSION(5,31,7)
#else

#define OP_ISA 396

static bool sv_isa_sv(SV *lhs, SV *rhs) {
    return true;
}

#endif
