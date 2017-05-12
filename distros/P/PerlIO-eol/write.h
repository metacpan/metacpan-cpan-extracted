#define WriteInsert(sym, len) \
    if (PerlIOBuf_write(aTHX_ f, sym, len) < len) \
        return i - (STDCHAR*)vbuf;

#define WriteOutBuffer \
    WriteInsert( start, (i - start) );

#define WriteCheckForCRLF \
    EOL_CheckForCRLF( s->write );

#define WriteCheckForCRandCRLF \
    if (*i == EOL_CR) { WriteCheckForCRLF };

#define WriteWithCRLF \
    WriteOutBuffer; \
    WriteInsert( "\015\012", 2 ); \
    WriteCheckForCRandCRLF;

#define WriteWithLF \
    WriteOutBuffer; \
    WriteInsert( "\012", 1 ); \
    WriteCheckForCRLF;

#define WriteWithCR \
    WriteOutBuffer; \
    WriteInsert( "\015", 1 ); \
    WriteCheckForCRandCRLF;

/* vim: set filetype=perl: */
