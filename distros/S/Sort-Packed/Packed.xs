/* -*- Mode: C -*- */

#define PERL_NO_GET_CONTEXT 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "merge.h"

#define BYTE_ORDER_BE 0
#define BYTE_ORDER_LE 1
#define BYTE_ORDER_LAST BYTE_ORDER_LE

#define TYPE_UNSIGNED 0
#define TYPE_SIGNED 1
#define TYPE_FLOAT 2
#define TYPE_FLOAT_X86 3
#define TYPE_LAST TYPE_FLOAT_X86

#define CUTOFF 16

/*
static void
dump_keys(pTHX_ char *name, unsigned char *pv, UV nelems, UV record_size, UV offset) {
    int i;
    fprintf(stderr, "%s\n", name);
    for (i = 0; i < nelems; i++) {
        int j;
        fprintf(stderr, "%04x:", i);
        for (j = offset; j < record_size; j++) {
            fprintf(stderr, " %02x", *(pv + i * record_size + j));
        }
        fprintf(stderr, "\n");
    }
    fprintf(stderr, "\n");
}

dump_pos(pTHX_ UV *pos) {
    int i, last = 0;
    fprintf(stderr, "\n\npos:");
    for (i=0; i < 256; i++) {
        if (pos[i] != last) 
            fprintf(stderr, "%02x: %d, ", i, pos[i] - last);
        last = pos[i];
    }
    fprintf(stderr, "\n");
}
*/

static void
my_radixsort(unsigned char *pv, UV nelems, UV record_size, UV offset) {
    if (nelems > CUTOFF) {
        UV count[256];
        UV pos[256];
        UV i, last, offset1;
        unsigned char *ptr, *end;

        /* dump_keys(aTHX_ "in", pv, nelems, record_size, offset); */

        for (i = 0; i < 256; i++)
            count[i] = 0;
        ptr = pv + offset;
        end = ptr + nelems * record_size;
        while (ptr < end) {
            count[*ptr]++;
            ptr += record_size;
        }
        
        if (offset + 1 == record_size) {
            ptr = pv + offset;
            for (i = 0; i < 256; i++) {
                UV j = count[i];
                while (j--) {
                    *ptr = i;
                    ptr += record_size;
                }
            }
        }
        else {
            pos[0] = 0;
            for (i = 0; i < 255; i++)
                pos[i + 1] = pos[i] + count[i];
            
            for (i = 0; i < 255; i++) {
                unsigned char *current = pv + offset + pos[i] * record_size;
                unsigned char *top = current + count[i] * record_size;
                while (current < top) {
                    if (*current == i) {
                        pos[*current] ++;
                        current += record_size;
                    }
                    else {
                        unsigned char dest_char = *current;
                        unsigned char *dest = pv + offset + pos[dest_char] * record_size;
                        int k = record_size - offset;
                        while (0 < k-- ) {
                            unsigned char tmp = current[k];
                            current[k] = dest[k];
                            dest[k] = tmp;
                        }
                        pos[dest_char]++;
                        count[dest_char]--;
                    }
                }
            }
            
            /* dump_keys(aTHX_ "out", pv, nelems, record_size, offset); */
            
            offset1 = offset + 1;
            if (offset1 < record_size) {
                pos[255] += count[255];
                for (last = i = 0; i < 256; last = pos[i++]) {
                    UV count = pos[i] - last;
                    if (count > 1)
                        my_radixsort(pv + last * record_size, count, record_size, offset1);
                }
            }
        }
    }
    else {
        UV i;
        for (i = 1; i < nelems; i++) {
            unsigned char *current = pv + i * record_size;
            UV min = 0, max = i;
            while (min < max) {
                UV pivot = (min + max) / 2;
                unsigned char *pivot_ptr = pv + pivot * record_size;
                UV j;
                /* fprintf(stderr, "min: %d, max: %d, pivot: %d\n", min, max, pivot); */
                for (j = offset; j < record_size; j++) {
                    if (pivot_ptr[j] < current[j]) {
                        min = pivot + 1;
                        goto continue_while_loop;
                    }
                    if (pivot_ptr[j] > current[j]) {
                        max = pivot;
                        goto continue_while_loop;
                    }
                }
                max = pivot;
                break;
            continue_while_loop:
                ;
            }
            /* fprintf(stderr, "rsize: %d, offset: %d, i: %d, max: %d\n",
                    record_size, offset, i, max);
                    dump_keys(aTHX_ "before", pv, i + 1, record_size, offset); */
            if (max < i) {
                UV j;
                for (j = offset; j < record_size; j++) {
                    unsigned char *end = pv + max * record_size + j;
                    unsigned char *ptr = pv + i * record_size + j;
                    unsigned char tmp = *ptr;
                    while (ptr > end) {
                        unsigned char *next = ptr - record_size;
                        *ptr = *next;
                        ptr = next;
                        /* dump_keys(aTHX_ "between", pv, i + 1, record_size, offset); */
                    }
                    *ptr = tmp;
                }
            }
            /* dump_keys(aTHX_ "after", pv, i + 1, record_size, offset); */
        }
    }
}

static void
reverse_packed(unsigned char *ptr, IV len, IV record_size) {
    if (record_size % sizeof(unsigned int) == 0) {
        int *start, *end;
        record_size /= sizeof(int);
        start = (int *)ptr;
        end = start + (len - 1) * record_size;
        if (record_size == 1) {
            while (start < end) {
                int tmp = *start;
                *(start++) = *end;
                *(end--) = tmp;
            }
        }
        else {
            while (start < end) {
                int i;
                for (i = 0; i < record_size; i++) {
                    int tmp = *start;
                    *(start++) = *end;
                    *(end++) = tmp;
                }
                end -= record_size * 2;
            }
        }
    }
    else {
        char *start = (char *)ptr;
        char *end = start + (len - 1) * record_size;
        while (start < end) {
            int i;
            for (i = 0; i < record_size; i++) {
                char tmp = *start;
                *(start++) = *end;
                *(end++) = tmp;
            }
            end -= record_size * 2;
        }
    }
}

static void
shuffle_packed(pTHX_ unsigned char *ptr, IV len, IV record_size) {
    if (len > 0) {
        while (--len) {
            IV i = (len + 1) * Drand01();
            IV j;
            for (j = 0; j < record_size; j++) {
                unsigned char *ptr_a = ptr + len * record_size;
                unsigned char *ptr_b = ptr + i * record_size;
                unsigned char tmp = ptr_a[j];
                ptr_a[j] = ptr_b[j];
                ptr_b[j] = tmp;
            }
        }
    }
}

static void
pre_sort(unsigned char *pv, UV nelems, UV value_size, UV value_type, UV byte_order) {
/*     fprintf(stderr, "pre_sort pv: %p, nelems: %d, value_size: %d, value_type: %d, byte_order: %d\n", */
/*             pv, nelems, value_size, value_type, byte_order); */
    if (byte_order || value_type) {
        unsigned char *ptr = pv;
        unsigned char *end = ptr + nelems * value_size;
        UV value_size_1 = ( ( value_type == TYPE_FLOAT_X86
                              && (value_size == 12 || value_size == 16) )
                            ? 9
                            : value_size - 1 );
        while (ptr < end) {
            if (byte_order) {
                unsigned char tmp;
                unsigned char *from = ptr;
                unsigned char *to = ptr + value_size_1;
                while (from < to) {
                    tmp = *from;
                    *(from++) = *to;
                    *(to--) = tmp;
                }
            }
            if (value_type) {
                if (value_type == TYPE_SIGNED) 
                    *ptr ^= 0x80;
                else { /* TYPE_FLOAT */
                    if (*ptr & 0x80) {
                        unsigned char *from = ptr + value_size_1;
                        while (from >= ptr)
                            *(from--) ^= 0xff;
                    }
                    else {
                        *ptr |= 0x80;
                    }
                }
            }
            ptr += value_size;
        }
    }
}

static void
post_sort(unsigned char *pv, UV nelems, UV value_size, UV value_type, UV byte_order) {
/*     fprintf(stderr, "post_sort pv: %p, nelems: %d, value_size: %d, value_type: %d, byte_order: %d\n", */
/*             pv, nelems, value_size, value_type, byte_order); */
    if (byte_order || value_type) {
        unsigned char *ptr = pv;
        unsigned char *end = ptr + nelems * value_size;
        UV value_size_1 = ( ( value_type == TYPE_FLOAT_X86
                              && (value_size == 12 || value_size == 16) )
                            ? 9
                            : value_size - 1 );
        while (ptr < end) {
            if (value_type) {
                if (value_type == TYPE_SIGNED) 
                    *ptr ^= 0x80;
                else { /* TYPE_FLOAT */
                    if (*ptr & 0x80)
                        *ptr &= 0x7f;
                    else {
                        unsigned char *from = ptr + value_size_1;
                        while (from >= ptr)
                            *(from--) ^= 0xff;
                    }
                }
            }
            if (byte_order) {
                unsigned char tmp;
                unsigned char *from = ptr;
                unsigned char *to = ptr + value_size_1;
                while (from < to) {
                    tmp = *from;
                    *(from++) = *to;
                    *(to--) = tmp;
                }
            }
            ptr += value_size;
        }
    }
}

typedef struct _cmp_extra {
    UV key_size;
    SV *cmp;
    SV *a, *b;
} my_extra;

static int
custom_cmp(pTHX_
           const unsigned char *a, const unsigned char *b,
           const my_extra *extra) {
    dSP;
    int r = 0;
    ENTER;
    SAVETMPS;
    /* fprintf(stderr, "custom_cmp a: %p, b: %p, $a: %p, $b: %p\n", a, b, extra->a, extra->b); */
    sv_setpvn(extra->a, (const char *)a, extra->key_size);
    sv_setpvn(extra->b, (const char *)b, extra->key_size);
    PUSHMARK(SP);
    PUTBACK;
    call_sv(extra->cmp, G_SCALAR);
    SPAGAIN;
    r = POPi;
    PUTBACK;
    FREETMPS;
    LEAVE;
    return r;
}

static int
custom_cmp_inv(pTHX_
           const unsigned char *a, const unsigned char *b,
           const my_extra *extra) {
    return custom_cmp(aTHX_ b, a, extra);
}

static int 
uchar_cmp(pTHX_
          const unsigned char *a, const unsigned char *b,
          const my_extra *extra) {
    UV i = extra->key_size;
    while (i--) {
        if (*a != *b)
            return (*a < *b) ? -1 : 1;
        a++; b++;
    }
    return 0;
}

static int 
uchar_cmp_inv(pTHX_
          const unsigned char *a, const unsigned char *b,
          const my_extra *extra) {
    UV i = extra->key_size;
    while (i--) {
        if (*a != *b)
            return (*a < *b) ? 1 : -1;
        a++; b++;
    }
    return 0;
}

static void
expand(unsigned char *from, UV nelems, UV rs, UV ers, unsigned char *to) {
    UV i = nelems;
    while (i-- > 0) {
        UV j = rs;
        while (j-- > 0) *(to++) = *(from++);
        j = ers - rs;
        while (j-- > 0) *(to++) = 0;
    }
}

static void
unexpand(unsigned char *from, UV nelems, UV rs, UV ers, unsigned char *to) {
    UV i = nelems;
    while (i-- > 0) {
        UV j = rs;
        while (j-- > 0) *(to++) = *(from++);
        from += ers - rs;
    }
}


MODULE = Sort::Packed		PACKAGE = Sort::Packed		

void
_radixsort_packed(vector, dir, value_size, value_type, byte_order, rep)
   SV *vector
   IV dir
   UV value_size
   UV value_type
   UV byte_order
   UV rep
CODE:
    STRLEN len;
    unsigned char *pv = (unsigned char *)SvPV_force(vector, len);
    UV record_size = value_size * rep;
    UV nelems;
    /* Perl_warn(aTHX_ "vector: %p, dir: %d, vsize: %d, vtype: %d bo: %d, rep: %d",
       vector, dir, value_size, value_type, byte_order, rep); */
    if (value_size == 0 || rep == 0 || dir == 0 ||
        byte_order > BYTE_ORDER_LAST || value_type > TYPE_LAST)
        Perl_croak(aTHX_ "internal error, bad value");
    if (len % record_size != 0)
        Perl_croak(aTHX_ "vector length %d is not a multiple of record size %d", len, record_size);
    nelems = len / record_size;
    if (nelems > 1) {
        pre_sort(pv, nelems * rep, value_size, value_type, byte_order);
        my_radixsort(pv, nelems, record_size, 0);
        post_sort(pv, nelems * rep, value_size, value_type, byte_order);
        if (dir < 0)
            reverse_packed(pv, nelems, record_size);
    }

void
_mergesort_packed(vector, cmp, dir, value_size, value_type, byte_order, rep)
    SV *vector
    SV *cmp
    IV dir
    UV value_size
    UV value_type
    UV byte_order
    UV rep
CODE:
    STRLEN len;
    unsigned char *pv = (unsigned char *)SvPV_force(vector, len);
    UV record_size = value_size * rep;
    UV expanded_record_size = record_size;
    UV nelems;
    my_extra extra;
    my_cmp_t ccmp;
    if (value_size == 0 || rep == 0 || dir == 0 ||
        byte_order > BYTE_ORDER_LAST || value_type > TYPE_LAST)
        Perl_croak(aTHX_ "internal error, bad value");
    if (len % record_size != 0)
        Perl_croak(aTHX_ "vector length %d is not a multiple of record size %d", len, record_size);
    nelems = len / record_size;
    if (nelems > 1) {
        extra.key_size = record_size;
        /* dump_keys(aTHX_ "in", pv, nelems, record_size, 0); */
        if (SvOK(cmp)) {
            GV *gv;
            SV *cv = SvRV(cmp);
            HV *stash = CvSTASH(cv);
            if (!stash)
                Perl_croak(aTHX_ "internal error: null stash");
            if (SvTYPE(cv) != SVt_PVCV)
                Perl_croak(aTHX_ "reference to comparison function expected");
            if (!hv_fetch(stash, "a", 1, TRUE))
                Perl_croak(aTHX_ "unexpected null gv pointer");
            gv = *(GV**)hv_fetch(stash, "a", 1, TRUE);
            if (SvTYPE(gv) != SVt_PVGV)
                gv_init(gv, stash, "a", 1, TRUE);
            SAVESPTR(GvSV(gv));
            extra.a = GvSV(gv) = sv_2mortal(newSV(extra.key_size + 1));
            gv = *(GV**)hv_fetch(stash, "b", 1, TRUE);
            if (SvTYPE(gv) != SVt_PVGV)
                gv_init(gv, stash, "b", 1, TRUE);
            SAVESPTR(GvSV(gv));
            extra.b = GvSV(gv) = sv_2mortal(newSV(extra.key_size + 1));
            ccmp = (my_cmp_t)(dir > 0 ? &custom_cmp : &custom_cmp_inv);
            extra.cmp = cmp;
        }
        else {
            ccmp = (my_cmp_t)(dir > 0 ? &uchar_cmp : &uchar_cmp_inv);
            extra.cmp = 0;
            pre_sort(pv, nelems * rep, value_size, value_type, byte_order);
        }
        if (record_size < PSIZE / 2) {
            expanded_record_size = PSIZE / 2;
            pv = (unsigned char *)SvPVX(sv_2mortal(newSV(nelems * expanded_record_size)));
            /* Newx(pv, nelems * expanded_record_size, unsigned char); */
            expand((unsigned char *)SvPV_nolen(vector), nelems,
                   record_size, expanded_record_size,
                   pv);
        }
        PUTBACK;
        my_mergesort(aTHX_ pv, nelems, expanded_record_size, ccmp, &extra);
        SPAGAIN;
        if (expanded_record_size != record_size) {
            unexpand(pv, nelems,
                     record_size, expanded_record_size,
                     (unsigned char *)SvPV_nolen(vector));
            pv = (unsigned char *)SvPV_nolen(vector);
        }
        if (!extra.cmp)
            post_sort(pv, nelems * rep, value_size, value_type, byte_order);
        /* dump_keys(aTHX_ "out", pv, nelems, record_size, 0); */
    }
        

void
_reverse_packed(vector, record_size)
    SV *vector
    IV record_size
CODE:
    STRLEN len;
    char *pv = SvPV_force(vector, len);
    UV nelems;
    if (record_size <= 0)
        Perl_croak(aTHX_ "bad record size %d", record_size);
    if (len % record_size != 0)
        Perl_croak(aTHX_ "vector length %d is not a multiple of record nelems %d", len, record_size);
    nelems = len / record_size;
    reverse_packed((unsigned char *)pv, nelems, record_size);

void
_shuffle_packed(vector, record_size)
     SV *vector
     IV record_size
CODE:
     STRLEN len;
     char *pv = SvPV_force(vector, len);
     UV nelems;
     if (record_size <= 0)
         Perl_croak(aTHX_ "bad record size %d", record_size);
     if (len % record_size != 0)
         Perl_croak(aTHX_ "vector length %d is not a multiple of record nelems %d", len, record_size);
     nelems = len / record_size;
     shuffle_packed(aTHX_ (unsigned char *)pv, nelems, record_size);
     
