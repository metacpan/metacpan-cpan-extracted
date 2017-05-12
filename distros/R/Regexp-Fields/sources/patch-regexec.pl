
patch <<'__', after => qr(with the POSIX routines of the same names);
#ifdef RE_FIELDS
#  define PERL_EXT
#  define PERL_EXT_RE_BUILD
#  ifdef PERL_EXT_RE_DEBUG
#    undef PERL_EXT_RE_DEBUG
#  endif
#endif
__

patch <<'__',  after => qr(\Q#include "regcomp.h");
#ifdef RE_FIELDS
#  include "rx_lend.h"
#endif
__

patch <<'__', before => qr(\Q/* Be paranoid... */);
#ifdef RE_FIELDS_MAGIC
    rx_regexec_start(aTHX_ prog, flags);
#endif
__

patch <<'__', after => qr(\Qif (UCHARAT(prog->program) != REG_MAGIC)), 0;
#ifdef RE_FIELDS
#undef Perl_regexec_flags
 	Perl_regexec_flags(aTHX_ prog, stringarg, strend, strbeg, minend, sv, data, flags);
#define Perl_regexec_flags my_regexec
#else
__

patch <<'__', after => qr(Perl_croak), 0;
#endif
__

patch <<'__', before => qr(return 1);
#ifdef RE_FIELDS_MAGIC
    rx_regexec_match(aTHX_ prog, flags);
#endif
__

patch <<'__', before => qr(return 0);
#ifdef RE_FIELDS_MAGIC
    rx_regexec_fail(aTHX_ prog, flags);
#endif
__


1;
