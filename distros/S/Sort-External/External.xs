#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#define SORTEX_UTF8_FLAG    0x1
#define SORTEX_TAINTED_FLAG 0x2

/* Memory requirement for a basic string SV.  The total cost for the SV is 
 * SvLEN(sv) + OVERHEAD.  For SVs which hold more than strings, the overhead
 * will be more, but it's too fiddly, slow, and error-prone to attempt an
 * accurate count.
 */
#define OVERHEAD (sizeof(SV) + sizeof(struct xpv))

typedef struct SortExternal {
    SV     *sortsub;
    SV     *working_dir;
    IV      cache_size;
    IV      mem_threshold;
    SV     *tempfile_fh;    /* Sortfile. */
    PerlIO *fh;
    AV     *item_cache; /* Storage area used by both feed and fetch. */
    AV     *runs;
    IV      mem_bytes;  /* Tally of memory consumed by item_cache. */
    IV      fetch_tick;
} SortExternal;

typedef struct SortExRun {
    SV     *tempfile_fh;
    PerlIO *fh;
    AV     *buffarray;
    Off_t   start;
    Off_t   pos;
    Off_t   end;
} SortExRun;

SortExternal*
SortEx_new(SV *working_dir, SV *sortsub, IV cache_size, IV mem_threshold, 
           SV *tempfile_fh) 
{
    SortExternal *self;
    Newx(self, 1, SortExternal);
    self->working_dir = SvOK(working_dir) ? SvREFCNT_inc(working_dir) : NULL;
    self->sortsub     = SvOK(sortsub )    ? SvREFCNT_inc(sortsub)     : NULL;
    self->cache_size    = cache_size;
    self->mem_threshold = mem_threshold;
    self->tempfile_fh   = newSVsv(tempfile_fh);
    self->fh            = IoIFP( sv_2io(tempfile_fh) );
    self->item_cache    = newAV();
    self->runs          = newAV();
    self->mem_bytes     = 0;
    self->fetch_tick    = 0;

    return self;
}

void
SortEx_destroy(SortExternal *self)
{
    if (self->working_dir) SvREFCNT_dec((SV*)self->working_dir);
    if (self->sortsub)     SvREFCNT_dec((SV*)self->sortsub);
    SvREFCNT_dec(self->tempfile_fh);
    SvREFCNT_dec((SV*)self->item_cache);
    SvREFCNT_dec((SV*)self->runs);
    Safefree(self);
}

SortExRun*
SortExRun_new(SV *tempfile_fh, Off_t start, Off_t end)
{
    SortExRun *self;
    Newx(self, 1, SortExRun);
    self->tempfile_fh  = newSVsv(tempfile_fh);
    self->fh           = IoIFP( sv_2io(self->tempfile_fh) );
    self->buffarray    = newAV();
    self->start        = start;
    self->end          = end;
    self->pos          = start;

    return self;
}

void
SortExRun_destroy(SortExRun *self)
{
    SvREFCNT_dec(self->tempfile_fh);
    SvREFCNT_dec(self->buffarray);
    Safefree(self);
}

/* Take every scalar in the supplied array and print its stringified form to
 * the temporary sortfile, prepending the string length encoded as a
 * compressed integer.
 */
void
SortEx_print_to_sortfile(SortExternal *self, AV *input_av, PerlIO *fh)
{
    int i, max;
    
    for (i = 0, max = av_len(input_av); i <= max; i++) {
        int check; 
        SV **sv_ptr  = av_fetch(input_av, i, 0);

        if (sv_ptr == NULL) {
            continue;
        }
        else {
            SV         *scratch_sv  = *sv_ptr;
            STRLEN      len;
            char       *string      = SvPV(scratch_sv, len);
            UV          aUV         = len;
            int         type        = SvTYPE(scratch_sv);
            char        flags       = 0;
            char        num_buf[5];
            char *const buf_end     = num_buf + 5;
            char       *encoded_len = buf_end;

            /* Throw an error if the item isn't a plain old scalar. */
            if (type > SVt_PVMG || type == SVt_RV) {
                croak("can't handle anything other than plain scalars");
            }
            
            /* Encode length of scalar as a BER compressed integer. */
            do {
                *--encoded_len = (char)((aUV & 0x7f) | 0x80);
                aUV >>= 7;
            } while (aUV);
            *(buf_end - 1) &= 0x7f;  

            /* Record utf8 and taint status. */
            if (SvUTF8(scratch_sv))    flags |= SORTEX_UTF8_FLAG;
            if (SvTAINTED(scratch_sv)) flags |= SORTEX_TAINTED_FLAG;

            /* Print len, string, and flags. */
            check = PerlIO_write(fh, encoded_len, (buf_end - encoded_len));
            if (check < 0) croak("PerlIO error: errno %d", errno);
            check = PerlIO_write(fh, string, len);
            if (check != (int)len) {
                croak("PerlIO error: tried to write %"UVuf" bytes, wrote %d",
                    (UV)len, check);
            }
            check = PerlIO_write(fh, &flags, 1);
            if (check != 1) croak("PerlIO error: errno %d", errno);
        }
    }
}

/* Recover items from disk.
 */
IV
SortExRun_refill_buffer(SortExRun *self)
{
    /* Extract filehandle and buffer array from object. */   
    PerlIO *const  fh           = self->fh;
    AV *const      buffarray_av = self->buffarray;
    int            num_items    = 0;
    Off_t          limit        = self->end - self->pos < 32768
                                ? self->end
                                : self->pos + 32768;

    PerlIO_seek(fh, self->pos, 0);
    while (self->pos < limit) {
        UV  item_length = 0;
        int check;

        /* Retrieve and decode len. */
        while (1) {
            U8 digit;
            check = PerlIO_read(fh, (char*)&digit, 1);
            self->pos++;
            if (check < 0) croak("PerlIO failed: %s", strerror(errno));
            item_length = (item_length << 7) | (digit & 0x7f);
            if (digit < 0x80) break; 
        }

        {
            /* Recover the stringified scalar from disk. */
            SV   *item_sv = newSV(item_length + 1);
            char  flags;

            SvCUR_set(item_sv, item_length);
            SvPOK_on(item_sv);
            check = PerlIO_read(fh, SvPVX(item_sv), item_length);
            if (check < (int)item_length) {
                croak("PerlIO error: read %d bytes, expected %"UVuf" bytes", 
                    check, (UV)item_length);
            }
            self->pos += check;
            *(SvEND(item_sv)) = '\0'; /* Null-terminate. */

            /* Restore UTF8 and taint flags. */
            check = PerlIO_read(fh, &flags, 1);
            self->pos++;
            if (check < 1) croak("PerlIO failed: %s", strerror(errno));
            if (flags & SORTEX_UTF8_FLAG)    SvUTF8_on(item_sv);
            if (flags & SORTEX_TAINTED_FLAG) SvTAINTED_on(item_sv);

            /* Add to the buffarray. */
            av_push(buffarray_av, item_sv);

            /* Track how much we've read so far. */
            num_items++;
        }
    }

    return num_items;
}

MODULE = Sort::External     PACKAGE = Sort::External

PROTOTYPES: DISABLE

SV*
_new(class_name, working_dir, sortsub, cache_size, mem_threshold, tempfile_fh) 
    char *class_name;
    SV *working_dir;
    SV *sortsub;
    IV cache_size;
    IV mem_threshold;
    SV *tempfile_fh;
CODE:
{
    SortExternal *self = SortEx_new(working_dir, sortsub, cache_size, 
        mem_threshold, tempfile_fh);
    RETVAL = newSV(0);
    sv_setref_pv(RETVAL, class_name, (void*)self);
}
OUTPUT: RETVAL

void
DESTROY(self)
    SortExternal *self;
PPCODE:
    SortEx_destroy(self);

void
feed(self, ...)
    SortExternal *self;
PPCODE:
{
    AV *const item_cache = self->item_cache;
    I32 start    = av_len(item_cache) + 1;
    I32 new_size = start + items - 1;
    IV  space    = (OVERHEAD + sizeof(SV*)) * (items - 1);
    I32 i;
    int need_to_flush = 0;

    /* Push arguments onto cache array. */
    av_extend(self->item_cache, new_size);
    for (i = 1; i < items; i++) {
        SV *const element = ST(i);
        SV *const copy    = newSVsv(element);
        av_push(item_cache, copy);

        /* Calculate a rough estimate of the memory occupied by the arguments:
         * sum the allocated string lengths, plus 15 bytes per scalar as
         * overhead.  Also, sv_len() has a side-effect of stringifying the SV.
         */
        space += sv_len(copy);
    }
    self->mem_bytes += space;

    if (self->cache_size > 0) {
        /* Use the number of cache elements as a flush-trigger. */
        if (av_len(self->item_cache) + 1 >= self->cache_size) 
            need_to_flush = 1;
    }
    else if (self->mem_bytes > self->mem_threshold) {
        /* Use memory consumption as a flush-trigger. */
        need_to_flush = 1;
    }
    if (need_to_flush) {
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs( ST(0) );
        call_method("_write_item_cache_to_tempfile", G_VOID|G_DISCARD);
        PUTBACK;
        FREETMPS;
        LEAVE;
    }
}

void
fetch(self)
    SortExternal *self;
PPCODE:
{
    if (self->fetch_tick > av_len(self->item_cache)) {
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs( ST(0) );
        call_method("_gatekeeper", G_VOID|G_DISCARD);
        PUTBACK;
        FREETMPS;
        LEAVE;
    }

    if (self->fetch_tick > av_len(self->item_cache)) {
        /* If empty, return false in both scalar and list context. */
        XSRETURN(0);
    }
    else {
        SV *elem = av_delete(self->item_cache, self->fetch_tick, 0);
        self->fetch_tick++;
        ST(0) = elem;
        XSRETURN(1);
    }
}

SV*
_get_something(self)
    SortExternal *self;
ALIAS:
    _get_sortsub       = 1
    _get_item_cache    = 2
    _get_runs          = 3
    _get_tempfile_fh   = 4
    _get_working_dir   = 5
CODE:
{
    switch(ix) {
        case 1: RETVAL = self->sortsub 
                       ? newSVsv(self->sortsub) 
                       : newSV(0);
                break;

        case 2: RETVAL = newRV_inc((SV*)self->item_cache);
                break;

        case 3: RETVAL = newRV_inc((SV*)self->runs);
                break;

        case 4: RETVAL = newSVsv(self->tempfile_fh);
                break;

        case 5: RETVAL = newSVsv(self->working_dir);
                break;

        default:
            croak("unrecognized alias number %d", ix);
    }
}
OUTPUT: RETVAL
    
void
_set_mem_bytes(self, mem_bytes)
    SortExternal *self;
    IV mem_bytes;
PPCODE:
    self->mem_bytes = mem_bytes;

void
_set_fetch_tick(self, fetch_tick)
    SortExternal *self;
    IV fetch_tick;
PPCODE:
    self->fetch_tick = fetch_tick;

void
_set_temp_fh(self, tempfile_fh)
    SortExternal *self;
    SV *tempfile_fh;
PPCODE:
    SvREFCNT_dec(self->tempfile_fh);
    self->tempfile_fh   = newSVsv(tempfile_fh);
    self->fh            = IoIFP( sv_2io(tempfile_fh) );

void
_print_to_sortfile(self, input_av, fh)
    SortExternal *self;
    AV *input_av;
    PerlIO *fh;
PPCODE:
    SortEx_print_to_sortfile(self, input_av, fh);

void
_utf8_on(sv)
    SV *sv;
PPCODE:
    /* Testing only. */
    SvUTF8_on(sv);

MODULE = Sort::External   PACKAGE = Sort::External::SortExRun

SortExRun*
_new(class_sv, tempfile_fh, start, end)
    SV *class_sv;
    SV *tempfile_fh;
    NV  start;
    NV  end;
CODE:
    RETVAL = SortExRun_new(tempfile_fh, start, end);
    (void)class_sv; /* Silence "unused var" compiler warning. */
OUTPUT: RETVAL

void
DESTROY(self)
    SortExRun *self;
PPCODE:
    SortExRun_destroy(self);

SV*
_get_buffarray(self)
    SortExRun *self;
CODE:
    RETVAL = newRV_inc((SV*)self->buffarray);
OUTPUT: RETVAL

void
_set_buffarray(self, buffarray);
    SortExRun *self;
    AV *buffarray;
PPCODE:
    SvREFCNT_dec((SV*)self->buffarray);
    self->buffarray = (AV*)SvREFCNT_inc((SV*)buffarray);

IV
_refill_buffer(self)
    SortExRun *self;
CODE:
    RETVAL = SortExRun_refill_buffer(self);
OUTPUT: RETVAL

