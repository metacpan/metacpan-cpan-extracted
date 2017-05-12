#ifndef RX_FIELDS_H
#define RX_FIELDS_H

START_EXTERN_C

EXT regexp*  my_regcomp (pTHX_ char*, char*, PMOP*);
EXT I32      my_regexec (pTHX_ regexp*, char*, char*, char*, I32, SV*, void*, U32);
EXT void     my_regfree (pTHX_ regexp*);
EXT char*    my_re_intuit_start (pTHX_ regexp*, SV*, char*, char*, U32, struct re_scream_pos_data_s*);
EXT SV*      my_re_intuit_string (pTHX_ regexp *);

#define RE_FIELDS_HINT "Regexp::Fields"
#define RXh_MY       0x001
#define RXh_COPY     0x002
#define RXf_MATCHED  0x100

#define MY_CXT_KEY    "Regexp::Fields::key"

typedef struct {
    GV *match_gv;
    HV *empty_hv;
} my_cxt_t;

/* regcomp.h: */
struct reg_data {
    U32 count;
    U8 *what;
    void* data[1];
};

typedef struct {
    U32 flags;
    HV *names;
} rx_reg_data;

#define RxCHECK(rx)    (rx && rx->data && rx->data->what[0] == 'x')
#define RxDATA(rx)     ((rx_reg_data*) rx->data->data[0])
#define RxNAMES(rx)    (RxDATA(rx)->names)
#define RxHINTMY(rx)   (RxDATA(rx)->flags & RXh_MY)
#define RxMATCHED(rx)  (RxDATA(rx)->flags & RXf_MATCHED)

#ifdef RE_FIELDS_MAGIC
# define SSPUSHANY(x)	(PL_savestack[PL_savestack_ix++] = x)
# define SSPOPANY	(PL_savestack[--PL_savestack_ix])
#endif

#ifndef PERL_UNUSED_VAR
# define PERL_UNUSED_VAR(x)
#endif

#if (PERL_VERSION == 8 && PERL_SUBVERSION >= 1) || PERL_VERSION > 8
# define RX_PAD_ADD_NAME
# ifndef pad_check_dup
#  define pad_check_dup(x,y,z)	Perl_pad_check_dup(aTHX_ x,y,z);
# endif
# ifndef pad_add_name
#   define pad_add_name(a,b,c,d)	Perl_pad_add_name(aTHX_ a,b,c,d);
# endif
#else
# ifndef pad_allocmy
#   define pad_allocmy(x)	Perl_pad_alloc(aTHX_ x);
# endif
#endif

#ifndef intro_my
#  define intro_my()	Perl_intro_my(aTHX);
#endif

#ifdef RE_FIELDS_REXC

/* from regcomp.c: */

typedef struct RExC_state_t {
    U32		flags;			/* are we folding, multilining? */
    char	*precomp;		/* uncompiled string. */
    regexp	*rx;
    char	*start;			/* Start of input for compile */
    char	*end;			/* End of input for compile */
    char	*parse;			/* Input-scan pointer. */
    I32		whilem_seen;		/* number of WHILEM in this expr */
    regnode	*emit_start;		/* Start of emitted-code area */
    regnode	*emit;			/* Code-emit pointer; &regdummy = don't = compiling */
    I32		naughty;		/* How bad is this pattern? */
    I32		sawback;		/* Did we see \1, ...? */
    U32		seen;
    I32		size;			/* Code size. */
    I32		npar;			/* () count. */
    I32		extralen;
    I32		seen_zerolen;
    I32		seen_evals;
    I32		utf8;
#if ADD_TO_REGEXEC
    char 	*starttry;		/* -Dr: where regtry was called. */
#define RExC_starttry	(pRExC_state->starttry)
#endif
} RExC_state_t;

#define RExC_flags	(pRExC_state->flags)
#define RExC_precomp	(pRExC_state->precomp)
#define RExC_rx		(pRExC_state->rx)
#define RExC_start	(pRExC_state->start)
#define RExC_end	(pRExC_state->end)
#define RExC_parse	(pRExC_state->parse)
#define RExC_whilem_seen	(pRExC_state->whilem_seen)
#define RExC_offsets	(pRExC_state->rx->offsets) /* I am not like the others */
#define RExC_emit	(pRExC_state->emit)
#define RExC_emit_start	(pRExC_state->emit_start)
#define RExC_naughty	(pRExC_state->naughty)
#define RExC_sawback	(pRExC_state->sawback)
#define RExC_seen	(pRExC_state->seen)
#define RExC_size	(pRExC_state->size)
#define RExC_npar	(pRExC_state->npar)
#define RExC_extralen	(pRExC_state->extralen)
#define RExC_seen_zerolen	(pRExC_state->seen_zerolen)
#define RExC_seen_evals	(pRExC_state->seen_evals)
#define RExC_utf8	(pRExC_state->utf8)

#endif


END_EXTERN_C

#endif /* RX_FIELDS_H */
