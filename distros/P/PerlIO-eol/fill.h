#define FillCopyBuffer \
    Copy(start, ptr, i - start, STDCHAR); \
    ptr += i - start;

#define FillInitializeBufferCopy \
    if (buf == NULL) { \
        New('b', buf, (i - start) + ((end - i + 1) * 2), STDCHAR); \
        ptr = buf; \
    } \
    FillCopyBuffer;

#define FillInitializeBuffer \
    if (buf == NULL) { \
        ptr = buf = b->buf; \
    } \
    FillCopyBuffer;

#define FillCheckForCRLF \
    EOL_CheckForCRLF( s->read );

#define FillCheckForCRandCRLF \
    if (*i == EOL_CR) { FillCheckForCRLF };

#define FillInsertCR \
    *ptr++ = EOL_CR;

#define FillInsertLF \
    *ptr++ = EOL_LF;

#define FillWithCRLF \
    FillInitializeBufferCopy; \
    FillInsertCR; \
    FillInsertLF; \
    FillCheckForCRandCRLF;

#define FillWithLF \
    FillInitializeBuffer; \
    FillInsertLF; \
    FillCheckForCRLF;

#define FillWithCR \
    FillInitializeBuffer; \
    FillInsertCR; \
    FillCheckForCRandCRLF;

/* vim: set filetype=perl: */
