typedef struct {
    bool            cr;
    unsigned int    eol;
    unsigned int    mixed;
    unsigned int    seen;
} PerlIOEOL_Baton;

typedef struct {
    PerlIOBuf       base;
    PerlIOEOL_Baton read;
    PerlIOEOL_Baton write;
    STDCHAR         *name;
} PerlIOEOL;

enum {
    EOL_Mixed_OK,
    EOL_Mixed_Warn,
    EOL_Mixed_Fatal
};

#define EOL_CR     015
#define EOL_LF     012
#define EOL_CRLF   015 + 012

#ifdef PERLIO_USING_CRLF
#  define EOL_NATIVE EOL_CRLF
#else
#  ifdef MACOS_TRADITIONAL
#    define EOL_NATIVE EOL_CR
#  else
#    define EOL_NATIVE EOL_LF
#  endif
#endif

#define EOL_LoopBegin \
    for (i = start; i < end; i++) {

#define EOL_LoopEnd \
        start = i + 1; \
    }

#define EOL_LoopForMixed( baton, do_break, do_lf ) \
    EOL_LoopBegin; \
    EOL_CheckForMixedCRLF( baton.seen, do_break, NOOP, do_lf, NOOP );

#define EOL_CheckForMixedCRLF( seen, do_break, do_cr, do_lf, do_crlf ) \
    switch (*i) { \
        case EOL_LF: \
            EOL_Seen( seen, EOL_LF, do_break ); do_lf; \
        case EOL_CR: \
	    if (i == end - 1) { \
                do_cr; \
	    } \
	    else if ( i[1] != EOL_LF ) { \
                EOL_Seen( seen, EOL_CR, do_break ); \
            } \
            else { \
                EOL_Seen( seen, EOL_CRLF, do_break ); \
                do_crlf; \
            } \
            break; \
        default: \
            continue; \
    }

#define EOL_LoopForCR \
    EOL_LoopBegin; \
    if (*i != EOL_CR) continue;

#define EOL_LoopForCRorLF \
    EOL_LoopBegin; \
    if ( (*i != EOL_CR) && (*i != EOL_LF) ) continue;

#define EOL_CheckForCRLF(baton) \
    if (i == end - 1) { \
        baton.cr = 1; \
    } \
    else if (i[1] == EOL_LF) { \
        i++; \
    }

#define EOL_AssignEOL(sym, baton) \
    if ( strnEQ( sym, "crlf", 4 ) )         { baton.eol = EOL_CRLF; } \
    else if ( strnEQ( sym, "cr", 2 ) )      { baton.eol = EOL_CR; } \
    else if ( strnEQ( sym, "lf", 2 ) )      { baton.eol = EOL_LF; } \
    else if ( strnEQ( sym, "native", 6 ) )  { baton.eol = EOL_NATIVE; } \
    else { \
        Perl_die(aTHX_ "Unknown eol '%s'; must pass CRLF, CR or LF or Native to :eol().", sym); \
    } \
    if (strchr( sym, '!' ))         { baton.mixed = EOL_Mixed_Fatal; } \
    else if (strchr( sym, '?' ))    { baton.mixed = EOL_Mixed_Warn; } \
    else                            { baton.mixed = EOL_Mixed_OK; }

#define EOL_Dispatch(baton, run_cr, run_lf, run_crlf) \
    switch ( baton.eol ) { \
        case EOL_LF: \
            EOL_Loop( baton, EOL_LoopForCR, run_lf, continue ); break; \
        case EOL_CRLF: \
            EOL_Loop( baton, EOL_LoopForCRorLF, run_crlf, break ); break; \
        case EOL_CR: \
            EOL_Loop( baton, EOL_LoopForCRorLF, run_cr, break ); break; \
    }

#define EOL_StartUpdate(baton) \
    if (baton.cr && *start == EOL_LF) { start++; } \
    baton.cr = 0;

#define EOL_Break \
    RETVAL = (i + len - end); break;

#define EOL_Break_Error(do_error) \
    if (s->name == NULL) { \
        do_error(aTHX_ "Mixed newlines"); \
    } \
    else { \
        do_error(aTHX_ "Mixed newlines found in \"%s\"", s->name); \
    }

#define EOL_Seen(seen, sym, do_break) \
    if (seen && (seen != sym)) { do_break; } \
    seen = sym;

#define EOL_Loop( baton, run_check, run_loop, do_lf ) \
    switch ( baton.mixed ) { \
        case EOL_Mixed_OK: \
            run_check; run_loop; EOL_LoopEnd; break; \
        case EOL_Mixed_Fatal: \
            EOL_LoopForMixed( baton, EOL_Break_Error(Perl_die), do_lf ); run_loop; EOL_LoopEnd; break; \
        case EOL_Mixed_Warn: \
            EOL_LoopForMixed( baton, EOL_Break_Error(Perl_warn), do_lf ); run_loop; EOL_LoopEnd; \
    }

/* vim: set filetype=perl: */
