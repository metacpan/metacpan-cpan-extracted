#ifndef __TRY_CATCH_HINTS__
#define __TRY_CATCH_HINTS__

#include <perl.h>

#define get_cop_hint_value(cop, key_sv) \
        cop_hints_fetch_sv((cop), (key_sv), 0, 0)

#define is_syntax_enabled() \
        SvTRUE( get_cop_hint_value(PL_curcop, hintkey_enabled_sv) )

#endif /* __TRY_CATCH_HINTS__ */
