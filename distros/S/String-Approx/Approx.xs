#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "patchlevel.h"
#ifdef __cplusplus
}
#endif

#include "apse.h"

#if PATCHLEVEL < 5
# define PL_na na
#endif

MODULE = String::Approx         PACKAGE = String::Approx                

PROTOTYPES: DISABLE

apse_t*
new(CLASS, pattern, ...)
        char*           CLASS
        SV*             pattern
    CODE:
        apse_t*         ap;
        apse_size_t     edit_distance;
        IV pattern_size = sv_len(pattern);
        if (items == 2)
                edit_distance = ((pattern_size-1)/10)+1;
        else if (items == 3)
                edit_distance = (apse_size_t)SvIV(ST(2));
        else {
                warn("Usage: new(pattern[, edit_distance])\n");
                XSRETURN_UNDEF;
        }
        ap = apse_create((unsigned char *)SvPV(pattern, PL_na),
                         pattern_size, edit_distance);
        if (ap) {
                RETVAL = ap;
        } else {
                warn("unable to allocate");
                XSRETURN_UNDEF;
        }
    OUTPUT:
        RETVAL

void
DESTROY(ap)
        apse_t*         ap
    CODE:
        apse_destroy(ap);

apse_bool_t
match(ap, text)
        apse_t*         ap
        SV*             text
    CODE:
        RETVAL = apse_match(ap,
                            (unsigned char *)SvPV(text, PL_na),
                            sv_len(text));
    OUTPUT:
        RETVAL

apse_bool_t
match_next(ap, text)
        apse_t*         ap
        SV*             text
    CODE:
        RETVAL = apse_match_next(ap,
                                 (unsigned char *)SvPV(text, PL_na),
                                 sv_len(text));
    OUTPUT:
        RETVAL

apse_ssize_t
index(ap, text)
        apse_t*         ap
        SV*             text
    CODE:
        RETVAL = apse_index(ap,
                            (unsigned char *)SvPV(text, PL_na),
                            sv_len(text));
    OUTPUT:
        RETVAL

void
slice(ap, text)
        apse_t*         ap
        SV*             text
    PREINIT:
        apse_size_t     match_begin;
        apse_size_t     match_size;
    PPCODE:
	if (ap->use_minimal_distance) {
	  apse_slice(ap,
		     (unsigned char *)SvPV(text, PL_na),
		     (apse_size_t)sv_len(text),
		     &match_begin,
		     &match_size);
	  EXTEND(sp, 3);
	  PUSHs(sv_2mortal(newSViv(match_begin)));
	  PUSHs(sv_2mortal(newSViv(match_size)));
	  PUSHs(sv_2mortal(newSViv(ap->edit_distance)));
	} else if (apse_slice(ap,
			      (unsigned char *)SvPV(text, PL_na),
			      (apse_size_t)sv_len(text),
			      &match_begin,
			      &match_size)) {
	  EXTEND(sp, 2);
	  PUSHs(sv_2mortal(newSViv(match_begin)));
	  PUSHs(sv_2mortal(newSViv(match_size)));
        }

void
slice_next(ap, text)
        apse_t*         ap
        SV*             text
    PREINIT:
        apse_size_t     match_begin;
        apse_size_t     match_size;
    PPCODE:
        if (apse_slice_next(ap,
                            (unsigned char *)SvPV(text, PL_na),
                            sv_len(text),
                            &match_begin,
                            &match_size)) {
                EXTEND(sp, 2);
                PUSHs(sv_2mortal(newSViv(match_begin)));
                PUSHs(sv_2mortal(newSViv(match_size)));
		if (ap->use_minimal_distance) {
		    EXTEND(sp, 1);
		    PUSHs(sv_2mortal(newSViv(ap->edit_distance)));
		}
        }

void
set_greedy(ap)
        apse_t*         ap
    CODE:
        apse_set_greedy(ap, 1);

apse_bool_t
set_caseignore_slice(ap, ...)
        apse_t* ap
    PREINIT:
        apse_size_t     offset;
        apse_size_t     size;
        apse_bool_t     ignore;
    CODE:
        offset = items < 2 ? 0 : (apse_size_t)SvIV(ST(1));
        size   = items < 3 ? ap->pattern_size : (apse_size_t)SvIV(ST(2));
        ignore = items < 4 ? 1 : (apse_bool_t)SvIV(ST(3));
        RETVAL = apse_set_caseignore_slice(ap, offset, size, ignore);
    OUTPUT:
        RETVAL

apse_bool_t
set_insertions(ap, insertions)
        apse_t*         ap
        apse_size_t     insertions = SvUV($arg);
    CODE:
        RETVAL = apse_set_insertions(ap, insertions);
    OUTPUT:
        RETVAL

apse_bool_t
set_deletions(ap, deletions)
        apse_t*         ap
        apse_size_t     deletions = SvUV($arg);
    CODE:
        RETVAL = apse_set_deletions(ap, deletions);
    OUTPUT:
        RETVAL

apse_bool_t
set_substitutions(ap, substitutions)
        apse_t*         ap
        apse_size_t     substitutions = SvUV($arg);
    CODE:
        RETVAL = apse_set_substitutions(ap, substitutions);
    OUTPUT:
        RETVAL

apse_bool_t
set_edit_distance(ap, edit_distance)
        apse_t*         ap
        apse_size_t     edit_distance = SvUV($arg);
    CODE:
        RETVAL = apse_set_edit_distance(ap, edit_distance);
    OUTPUT:
        RETVAL

apse_size_t
get_edit_distance(ap)
        apse_t*         ap
    CODE:
        ST(0) = sv_newmortal();
        sv_setiv(ST(0), apse_get_edit_distance(ap));

apse_bool_t
set_text_initial_position(ap, text_initial_position)
        apse_t*         ap
        apse_size_t     text_initial_position = SvUV($arg);
    CODE:
        RETVAL = apse_set_text_initial_position(ap, text_initial_position);
    OUTPUT:
        RETVAL

apse_bool_t
set_text_final_position(ap, text_final_position)
        apse_t*         ap
        apse_size_t     text_final_position = SvUV($arg);
    CODE:
        RETVAL = apse_set_text_final_position(ap, text_final_position);
    OUTPUT:
        RETVAL

apse_bool_t
set_text_position_range(ap, text_position_range)
        apse_t*         ap
        apse_size_t     text_position_range = SvUV($arg);
    CODE:
        RETVAL = apse_set_text_position_range(ap, text_position_range);
    OUTPUT:
        RETVAL

void
set_minimal_distance(ap, b)
        apse_t*         ap
	apse_bool_t	b
    CODE:
        apse_set_minimal_distance(ap, b);
