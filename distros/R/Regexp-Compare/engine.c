#include "engine.h"
#include "regnodes.h"
#include "regcomp.h"
#include <stdio.h>
#include <string.h>
#include <assert.h>

#if PERL_API_REVISION != 5
#error This module is only for Perl 5
#else
#if PERL_API_VERSION == 26
/* nothing special */
#else
#if PERL_API_VERSION == 28
#define RC_ANYOFM
#else
#if PERL_API_VERSION == 30
#define RC_ANYOFM
#define RC_NANYOFM
#define RC_EXACT_ONLY8
#define RC_UNCOND_CHARCLASS
#define RC_ANYOF_OFFSET
#define RC_SHORT_BITMAP
#define RC_UNSIGNED_COUNT
#else
#error Unsupported PERL_API_VERSION
#endif
#endif
#endif
#endif

#define SIZEOF_ARRAY(a) (sizeof(a) / sizeof(a[0]))

#define TOLOWER(c) ((((c) >= 'A') && ((c) <= 'Z')) ? ((c) - 'A' + 'a') : (c))

#define LETTER_COUNT ('z' - 'a' + 1)

#ifndef RC_UNSIGNED_COUNT
#define INFINITE_COUNT 32767
#else
#define INFINITE_COUNT 0xffff
#endif

#define ALNUM_BLOCK 0x0001
#define SPACE_BLOCK 0x0002
#define ALPHA_BLOCK 0x0004
#define NUMBER_BLOCK 0x0008
#define UPPER_BLOCK 0x0010
#define LOWER_BLOCK 0x0020
#define HEX_DIGIT_BLOCK 0x0040
#define HORIZONTAL_SPACE_BLOCK 0x0080
#define VERTICAL_SPACE_BLOCK 0x0100

#define MIRROR_SHIFT 16
#define NOT_ALNUM_BLOCK (ALNUM_BLOCK << MIRROR_SHIFT)
#define NOT_SPACE_BLOCK (SPACE_BLOCK << MIRROR_SHIFT)
#define NOT_ALPHA_BLOCK (ALPHA_BLOCK << MIRROR_SHIFT)
#define NOT_NUMBER_BLOCK (NUMBER_BLOCK << MIRROR_SHIFT)
#define NOT_UPPER_BLOCK (UPPER_BLOCK << MIRROR_SHIFT)
#define NOT_LOWER_BLOCK (LOWER_BLOCK << MIRROR_SHIFT)
#define NOT_HEX_DIGIT_BLOCK (HEX_DIGIT_BLOCK << MIRROR_SHIFT)
#define NOT_HORIZONTAL_SPACE_BLOCK (HORIZONTAL_SPACE_BLOCK << MIRROR_SHIFT)
#define NOT_VERTICAL_SPACE_BLOCK (VERTICAL_SPACE_BLOCK << MIRROR_SHIFT)

#define EVERY_BLOCK 0x01ff01ff

#define FORCED_BYTE 0x01
#define FORCED_CHAR 0x02
#define FORCED_MISMATCH (FORCED_BYTE | FORCED_CHAR)

#define MIRROR_BLOCK(b) ((((b) & 0xffff) << MIRROR_SHIFT) | ((b) >> MIRROR_SHIFT))

/* Regexp terms are normally regnodes, except for EXACT (and EXACTF)
   nodes, which can bundle many characters, which we have to compare
   separately. Occasionally, we also need access to extra regexp
   data. */
typedef struct
{
    regexp *origin;
    regnode *rn;
    int spent;
} Arrow;

#define GET_LITERAL(a) (((char *)((a)->rn + 1)) + (a)->spent)

#define GET_OFFSET(rn) ((rn)->next_off ? (rn)->next_off : get_synth_offset(rn))

#ifndef RC_UNSIGNED_COUNT
typedef I16 CurlyCount;
#else
typedef U16 CurlyCount;
#endif

/* Most functions below have this signature. The first parameter is a
   flag set after the comparison actually matched something, second
   parameter points into the first ("left") regexp passed into
   rc_compare, the third into the second ("right") regexp. Return
   value is 1 for match, 0 no match, -1 error (with the lowest-level
   failing function setting rc_error before returning it). */
typedef int (*FCompare)(int, Arrow *, Arrow *);

/* Place of a char in regexp bitmap. */
typedef struct
{
    int offs;
    unsigned char mask;
} BitFlag;

/* Set of chars and its complement formatted for convenient
   matching. */
typedef struct
{
  char *expl;
  int expl_size;
  char lookup[256];
  char nlookup[256];
  unsigned char bitmap[ANYOF_BITMAP_SIZE];
  unsigned char nbitmap[ANYOF_BITMAP_SIZE];
} ByteClass;

char *rc_error = 0;

unsigned char forced_byte[ANYOF_BITMAP_SIZE];

/* since Perl 5.18, \s matches vertical tab - see
 * https://www.effectiveperlprogramming.com/2013/06/the-vertical-tab-is-part-of-s-in-perl-5-18/
 * , or "Pattern White Space" in perlre */
static char whitespace_expl[] = { ' ', '\f', '\n', '\r', '\t', '\v' };

static ByteClass whitespace;

static char horizontal_whitespace_expl[] = { '\t', ' ' };

static ByteClass horizontal_whitespace;

static char vertical_whitespace_expl[] = { '\r', '\v', '\f', '\n' };

static ByteClass vertical_whitespace;

static char digit_expl[10];

static ByteClass digit;

static char xdigit_expl[10 + 2 * 6];

static ByteClass xdigit;

static char ndot_expl[] = { '\n' };

static ByteClass ndot;

static char alphanumeric_expl[11 + 2 * LETTER_COUNT];

static ByteClass word_bc;

static ByteClass alnum_bc;

static char alpha_expl[2 * LETTER_COUNT];

static ByteClass alpha_bc;

static char lower_expl[LETTER_COUNT];

static ByteClass lower_bc;

static char upper_expl[LETTER_COUNT];

static ByteClass upper_bc;

/* true flags for ALNUM and its subsets, 0 otherwise */
static unsigned char alphanumeric_classes[REGNODE_MAX];

/* true flags for NALNUM and its subsets, 0 otherwise */
static unsigned char non_alphanumeric_classes[REGNODE_MAX];

static unsigned char word_posix_regclasses[_CC_VERTSPACE + 1];

static unsigned char non_word_posix_regclasses[_CC_VERTSPACE + 1];

static unsigned char newline_posix_regclasses[_CC_VERTSPACE + 1];

/* Simplified hierarchy of character classes; ignoring the difference
   between classes (i.e. IsAlnum & IsWord), which we probably
   shouldn't - it is a documented bug, though... */
static char *regclass_names[] = { "Digit", "IsAlnum", "IsSpacePerl",
                                  "IsHorizSpace", "IsVertSpace",
                                  "IsWord", "IsXPosixAlnum", "IsXPosixXDigit",
                                  "IsAlpha", "IsXPosixAlpha",
                                  "IsDigit", "IsLower", "IsUpper",
                                  "IsXDigit", "SpacePerl", "VertSpace",
                                  "Word", "XPosixDigit",
                                  "XPosixWord", "XPosixAlpha", "XPosixAlnum",
                                  "XPosixXDigit" };

static U32 regclass_blocks[] = { NUMBER_BLOCK, ALNUM_BLOCK, SPACE_BLOCK,
                                 HORIZONTAL_SPACE_BLOCK,
                                 VERTICAL_SPACE_BLOCK, ALNUM_BLOCK,
                                 ALNUM_BLOCK, HEX_DIGIT_BLOCK, ALPHA_BLOCK,
                                 ALPHA_BLOCK, NUMBER_BLOCK, LOWER_BLOCK,
                                 UPPER_BLOCK, HEX_DIGIT_BLOCK, SPACE_BLOCK,
                                 VERTICAL_SPACE_BLOCK, ALNUM_BLOCK,
                                 NUMBER_BLOCK, ALNUM_BLOCK, ALPHA_BLOCK,
                                 ALNUM_BLOCK, HEX_DIGIT_BLOCK};

static U32 regclass_superset[] = { NOT_SPACE_BLOCK,
                                   NOT_ALPHA_BLOCK, NOT_NUMBER_BLOCK,
                                   ALNUM_BLOCK, ALNUM_BLOCK,
                                   ALPHA_BLOCK, ALPHA_BLOCK, HEX_DIGIT_BLOCK,
                                   SPACE_BLOCK, NOT_NUMBER_BLOCK,
                                   NOT_HEX_DIGIT_BLOCK };
static U32 regclass_subset[] = { ALNUM_BLOCK,
                                 NOT_ALNUM_BLOCK, NOT_ALNUM_BLOCK,
                                 ALPHA_BLOCK, NUMBER_BLOCK,
                                 UPPER_BLOCK, LOWER_BLOCK, NUMBER_BLOCK,
                                 HORIZONTAL_SPACE_BLOCK,
                                 VERTICAL_SPACE_BLOCK, VERTICAL_SPACE_BLOCK };

static U32 posix_regclass_blocks[_CC_VERTSPACE + 1] = {
    ALNUM_BLOCK /* _CC_WORDCHAR == 0 */,
    NUMBER_BLOCK /* _CC_DIGIT == 1 */,
    ALPHA_BLOCK /* _CC_ALPHA == 2 */,
    LOWER_BLOCK /* _CC_LOWER == 3 */,
    UPPER_BLOCK /* _CC_UPPER == 4 */,
    0,
    0,
    ALNUM_BLOCK /* _CC_ALPHANUMERIC == 7 */,
    0,
    0,
    SPACE_BLOCK /* _CC_SPACE == 10 */,
    HORIZONTAL_SPACE_BLOCK /* _CC_BLANK == 11, and according to perlrecharclass "\p{Blank}" and "\p{HorizSpace}" are synonyms. */,
    HEX_DIGIT_BLOCK /* _CC_XDIGIT == 12 */
}; /* _CC_VERTSPACE set in rc_init because it has different values between perl 5.20 and 5.22 */

static unsigned char *posix_regclass_bitmaps[_CC_VERTSPACE + 1] = {
    word_bc.bitmap,
    digit.bitmap,
    alpha_bc.bitmap,
    lower_bc.bitmap,
    upper_bc.bitmap,
    0,
    0,
    alnum_bc.bitmap,
    0,
    0,
    whitespace.bitmap,
    horizontal_whitespace.bitmap,
    xdigit.bitmap
};

static unsigned char *posix_regclass_nbitmaps[_CC_VERTSPACE + 1] = {
    word_bc.nbitmap,
    digit.nbitmap,
    0,
    0,
    0,
    0,
    0,
    alnum_bc.nbitmap,
    0,
    0,
    whitespace.nbitmap,
    horizontal_whitespace.nbitmap,
    xdigit.nbitmap
};

static unsigned char trivial_nodes[REGNODE_MAX];

static FCompare dispatch[REGNODE_MAX][REGNODE_MAX];

static int compare(int anchored, Arrow *a1, Arrow *a2);
static int compare_right_branch(int anchored, Arrow *a1, Arrow *a2);
static int compare_right_curly(int anchored, Arrow *a1, Arrow *a2);

static void init_bit_flag(BitFlag *bf, int c)
{
    assert(c >= 0);

    bf->offs = c / 8;
    bf->mask = 1 << (c % 8);
}

static void init_forced_byte()
{
    char forced_byte_expl[] = { 'a', 'b', 'c', 'e', 'f', 'x' };
    BitFlag bf;
    int i;

    memset(forced_byte, 0, sizeof(forced_byte));

    for (i = 0; i < sizeof(forced_byte_expl); ++i)
    {
        init_bit_flag(&bf, (unsigned char)forced_byte_expl[i]);
        forced_byte[bf.offs] |= bf.mask;
    }

    for (i = 0; i < 8; ++i)
    {
        init_bit_flag(&bf, (unsigned char)('0' + i));
        forced_byte[bf.offs] |= bf.mask;
    }
}

static void init_byte_class(ByteClass *bc, char *expl, int expl_size)
{
    BitFlag bf;
    int i;

    bc->expl = expl;
    bc->expl_size = expl_size;

    memset(bc->lookup, 0, sizeof(bc->lookup));
    memset(bc->nlookup, 1, sizeof(bc->nlookup));
    memset(bc->bitmap, 0, sizeof(bc->bitmap));
    memset(bc->nbitmap, 0xff, sizeof(bc->nbitmap));

    for (i = 0; i < expl_size; ++i)
    {
        bc->lookup[(unsigned char)expl[i]] = 1;
        bc->nlookup[(unsigned char)expl[i]] = 0;

        init_bit_flag(&bf, (unsigned char)expl[i]);
        bc->bitmap[bf.offs] |= bf.mask;
        bc->nbitmap[bf.offs] &= ~bf.mask;
    }
}

static void init_unfolded(char *unf, char c)
{
    *unf = TOLOWER(c);
    unf[1] = ((*unf >= 'a') && (*unf <= 'z')) ? *unf - 'a' + 'A' : *unf;
}

static U32 extend_mask(U32 mask)
{
    U32 prev_mask;
    int i, j;

    /* extra cycle is inefficient but makes superset & subset
       definitions order-independent */
    prev_mask = 0;
    while (mask != prev_mask)
    {
        prev_mask = mask;
        for (i = 0; i < 2; ++i)
        {
            for (j = 0; j < SIZEOF_ARRAY(regclass_superset); ++j)
            {
                U32 b = regclass_superset[j];
                U32 s = regclass_subset[j];
                if (i)
                {
                    U32 t;

                    t = MIRROR_BLOCK(b);
                    b = MIRROR_BLOCK(s);
                    s = t;
                }

                if (mask & b)
                {
                    mask |= s;
                }
            }
        }
    }

    return mask;
}

static int convert_desc_to_map(char *desc, int invert, U32 *map)
{
    int i;
    U32 mask = 0;
    char *p;

    /* fprintf(stderr, "enter convert_desc_to_map(%s, %d\n", desc, invert); */

    p = strstr(desc, "utf8::");
    /* make sure *(p - 1) is valid */
    if (p == desc)
    {
        rc_error = "no inversion flag before character class description";
        return -1;
    }

    while (p)
    {
        char sign = *(p - 1);
        for (i = 0; i < SIZEOF_ARRAY(regclass_names); ++i)
        {
            if (!strncmp(p + 6, regclass_names[i], strlen(regclass_names[i])))
            {
                if (sign == '+')
                {
                    if (mask & (regclass_blocks[i] << MIRROR_SHIFT))
                    {
                        *map = invert ? 0 : EVERY_BLOCK;
                        return 1;
                    }

                    mask |= regclass_blocks[i];
                }
                else if (sign == '!')
                {
                    if (mask & regclass_blocks[i])
                    {
                        *map = invert ? 0 : EVERY_BLOCK;
                        return 1;
                    }

                    mask |= (regclass_blocks[i] << MIRROR_SHIFT);
                }
                else
                {
                    rc_error = "unknown inversion flag before character class description";
                    return -1;
                }
            }
        }

        p = strstr(p + 6, "utf8::");
    }

    /* fprintf(stderr, "parsed 0x%x\n", (unsigned)mask); */

    if ((mask & ALPHA_BLOCK) && (mask & NUMBER_BLOCK))
    {
        mask |= ALNUM_BLOCK;
    }

    if (invert)
    {
        mask = MIRROR_BLOCK(mask);
    }

    if ((mask & ALPHA_BLOCK) && (mask & NUMBER_BLOCK))
    {
        mask |= ALNUM_BLOCK;
    }

    *map = extend_mask(mask);
    return 1;
}

/* invlist methods are static inside regcomp.c, so we must copy them... */
static bool *get_invlist_offset_addr(SV *invlist)
{
    return &(((XINVLIST*) SvANY(invlist))->is_offset);
}

static UV get_invlist_len(SV *invlist)
{
    return (SvCUR(invlist) == 0)
           ? 0
           : (SvCUR(invlist) / sizeof(UV)) - *get_invlist_offset_addr(invlist);
}

static UV *invlist_array(SV *invlist)
{
    return ((UV *) SvPVX(invlist) + *get_invlist_offset_addr(invlist));
}

/* #define DEBUG_dump_invlist */

static int convert_invlist_to_map(SV *invlist, int invert, U32 *map)
{
    /*
       Not quite what's in charclass_invlists.h - we skip the header
       as well as all ASCII values.
       Note that changes to the arrays may require changing the switch
       below.
    */
    static UV perl_space_invlist[] = { 128,
#if PERL_API_VERSION == 26
#include "XPerlSpace.26"
#else
#if PERL_API_VERSION == 28
#include "XPerlSpace.26"
#else
#if PERL_API_VERSION == 30
#include "XPerlSpace.30"
#else
#error unexpected PERL_API_VERSION
#endif
#endif
#endif
    };

#ifdef RC_UNCOND_CHARCLASS
    static UV perl_space_short_invlist[] = { 256,
#include "XPerlSpace.30a"
    };
#endif

    static UV horizontal_space_invlist[] = { 128, 160, 161, 5760, 5761,
        6158, 6159, 8192, 8203, 8239, 8240, 8287, 8288, 12288, 12289 };

    static UV vertical_space_invlist[] = { 128, 133, 134, 8232, 8234 };

    static UV xposix_digit_invlist[] = { 128,
#include "XPosixDigit.22"
    };

    static UV xposix_alnum_invlist[] = { 128,
#if PERL_API_VERSION == 26
#include "XPosixAlnum.26"
#else
#if PERL_API_VERSION == 28
#include "XPosixAlnum.28"
#else
#if PERL_API_VERSION == 30
#include "XPosixAlnum.30"
#else
#error unexpected PERL_API_VERSION
#endif
#endif
#endif
    };

    static UV xposix_alpha_invlist[] = { 128,
#if PERL_API_VERSION == 26
#include "XPosixAlpha.26"
#else
#if PERL_API_VERSION == 28
#include "XPosixAlpha.28"
#else
#if PERL_API_VERSION == 30
#include "XPosixAlpha.28"
#else
#error unexpected PERL_API_VERSION
#endif
#endif
#endif
    };

    static UV xposix_word_invlist[] = { 128,
#include "XPosixWord.22"
    };

    static UV xposix_xdigit_invlist[] = { 128, 65296, 65306, 65313,
        65319, 65345, 65351 };

#ifdef DEBUG_dump_invlist
    U16 i;
    char div[3];
#endif

    UV *ila;
    UV ill;
    U32 mask = 0;

#ifdef DEBUG_dump_invlist
    fprintf(stderr, "enter convert_invlist_to_map(..., %d, ...)\n", invert);
#endif

    ill = get_invlist_len(invlist);
#ifdef DEBUG_dump_invlist
    fprintf(stderr, "ill = %lu\n", ill);
#endif
    ila = ill ? invlist_array(invlist) : 0;

    switch (ill)
    {
    case SIZEOF_ARRAY(perl_space_invlist):
        if (!memcmp(ila, perl_space_invlist, sizeof(perl_space_invlist)))
        {
#ifdef DEBUG_dump_invlist
            fprintf(stderr, "NOT_SPACE_BLOCK\n");
#endif
            mask = NOT_SPACE_BLOCK;
        }

        break;

    case SIZEOF_ARRAY(perl_space_invlist) - 1:
        if (!memcmp(ila, perl_space_invlist + 1,
            sizeof(perl_space_invlist) - sizeof(perl_space_invlist[0])))
        {
#ifdef DEBUG_dump_invlist
            fprintf(stderr, "SPACE_BLOCK\n");
#endif
            mask = SPACE_BLOCK;
        }

        break;

#ifdef RC_UNCOND_CHARCLASS
    case SIZEOF_ARRAY(perl_space_short_invlist):
        if (!memcmp(ila, perl_space_short_invlist, sizeof(perl_space_short_invlist)))
        {
#ifdef DEBUG_dump_invlist
            fprintf(stderr, "NOT_SPACE_BLOCK\n");
#endif
            mask = NOT_SPACE_BLOCK;
        }

        break;
#endif

    case SIZEOF_ARRAY(horizontal_space_invlist):
        if (!memcmp(ila, horizontal_space_invlist, sizeof(horizontal_space_invlist)))
        {
#ifdef DEBUG_dump_invlist
            fprintf(stderr, "NOT_HORIZONTAL_SPACE_BLOCK\n");
#endif
            mask = NOT_HORIZONTAL_SPACE_BLOCK;
        }

        break;

    case SIZEOF_ARRAY(horizontal_space_invlist) - 1:
        if (!memcmp(ila, horizontal_space_invlist + 1,
            sizeof(horizontal_space_invlist) - sizeof(horizontal_space_invlist[0])))
        {
#ifdef DEBUG_dump_invlist
            fprintf(stderr, "HORIZONTAL_SPACE_BLOCK\n");
#endif
            mask = HORIZONTAL_SPACE_BLOCK;
        }

        break;

    case SIZEOF_ARRAY(vertical_space_invlist):
        if (!memcmp(ila, vertical_space_invlist, sizeof(vertical_space_invlist)))
        {
#ifdef DEBUG_dump_invlist
            fprintf(stderr, "NOT_VERTICAL_SPACE_BLOCK\n");
#endif
            mask = NOT_VERTICAL_SPACE_BLOCK;
        }

        break;

    case SIZEOF_ARRAY(vertical_space_invlist) - 1:
        if (!memcmp(ila, vertical_space_invlist + 1,
            sizeof(vertical_space_invlist) - sizeof(vertical_space_invlist[0])))
        {
#ifdef DEBUG_dump_invlist
            fprintf(stderr, "VERTICAL_SPACE_BLOCK\n");
#endif
            mask = VERTICAL_SPACE_BLOCK;
        }

        break;

    case SIZEOF_ARRAY(xposix_digit_invlist):
        if (!memcmp(ila, xposix_digit_invlist, sizeof(xposix_digit_invlist)))
        {
#ifdef DEBUG_dump_invlist
            fprintf(stderr, "NOT_NUMBER_BLOCK\n");
#endif
            mask = NOT_NUMBER_BLOCK;
        }

        break;

    case SIZEOF_ARRAY(xposix_digit_invlist) - 1:
        if (!memcmp(ila, xposix_digit_invlist + 1,
            sizeof(xposix_digit_invlist) - sizeof(xposix_digit_invlist[0])))
        {
#ifdef DEBUG_dump_invlist
            fprintf(stderr, "NUMBER_BLOCK\n");
#endif
            mask = NUMBER_BLOCK;
        }

        break;

    case SIZEOF_ARRAY(xposix_alnum_invlist):
        if (!memcmp(ila, xposix_alnum_invlist, sizeof(xposix_alnum_invlist)))
        {
#ifdef DEBUG_dump_invlist
            fprintf(stderr, "NOT_ALNUM_BLOCK\n");
#endif
            mask = NOT_ALNUM_BLOCK;
        }

        break;

    case SIZEOF_ARRAY(xposix_alnum_invlist) - 1:
        if (!memcmp(ila, xposix_alnum_invlist + 1,
            sizeof(xposix_alnum_invlist) - sizeof(xposix_alnum_invlist[0])))
        {
#ifdef DEBUG_dump_invlist
            fprintf(stderr, "ALNUM_BLOCK\n");
#endif
            mask = ALNUM_BLOCK;
        }

        break;

    case SIZEOF_ARRAY(xposix_alpha_invlist):
        if (!memcmp(ila, xposix_alpha_invlist, sizeof(xposix_alpha_invlist)))
        {
#ifdef DEBUG_dump_invlist
            fprintf(stderr, "NOT_ALPHA_BLOCK\n");
#endif
            mask = NOT_ALPHA_BLOCK;
        }

        break;

    case SIZEOF_ARRAY(xposix_alpha_invlist) - 1:
        if (!memcmp(ila, xposix_alpha_invlist + 1,
            sizeof(xposix_alpha_invlist) - sizeof(xposix_alpha_invlist[0])))
        {
#ifdef DEBUG_dump_invlist
            fprintf(stderr, "ALPHA_BLOCK\n");
#endif
            mask = ALPHA_BLOCK;
        }

        break;

    case SIZEOF_ARRAY(xposix_word_invlist):
        if (!memcmp(ila, xposix_word_invlist, sizeof(xposix_word_invlist)))
        {
#ifdef DEBUG_dump_invlist
            fprintf(stderr, "NOT_ALPHA_BLOCK\n");
#endif
            mask = NOT_ALPHA_BLOCK;
        }

        break;

    case SIZEOF_ARRAY(xposix_word_invlist) - 1:
        if (!memcmp(ila, xposix_word_invlist + 1,
            sizeof(xposix_word_invlist) - sizeof(xposix_word_invlist[0])))
        {
#ifdef DEBUG_dump_invlist
            fprintf(stderr, "ALPHA_BLOCK\n");
#endif
            mask = ALPHA_BLOCK;
        }

        break;

    case SIZEOF_ARRAY(xposix_xdigit_invlist):
        if (!memcmp(ila, xposix_xdigit_invlist, sizeof(xposix_xdigit_invlist)))
        {
#ifdef DEBUG_dump_invlist
            fprintf(stderr, "NOT_NUMBER_BLOCK\n");
#endif
            mask = NOT_NUMBER_BLOCK;
        }

        break;

    case SIZEOF_ARRAY(xposix_xdigit_invlist) - 1:
        if (!memcmp(ila, xposix_xdigit_invlist + 1,
            sizeof(xposix_xdigit_invlist) - sizeof(xposix_xdigit_invlist[0])))
        {
#ifdef DEBUG_dump_invlist
            fprintf(stderr, "NUMBER_BLOCK\n");
#endif
            mask = NUMBER_BLOCK;
        }

        break;
    }

    if (mask)
    {
        if (invert)
        {
            mask = MIRROR_BLOCK(mask);
        }

        *map = extend_mask(mask);
        return 1;
    }

#ifdef DEBUG_dump_invlist
    div[0] = 0;
    div[2] = 0;
    for (i = 0; i < ill; ++i)
    {
        fprintf(stderr, "%s0x%x", div, (int)(ila[i]));
        div[0] = ',';
        div[1] = '\n';
    }

    fprintf(stderr, "\n");
#endif

    return 0;
}

static int convert_regclass_map(Arrow *a, U32 *map)
{
    regexp_internal *pr;
    U32 n;
    struct reg_data *rdata;

    /* fprintf(stderr, "enter convert_regclass_map\n"); */

    assert((a->rn->type == ANYOF) || (a->rn->type == ANYOFD));

    /* basically copied from regexec.c:regclass_swash */
    n = ARG_LOC(a->rn);
    pr = RXi_GET(a->origin);
    if (!pr) /* this should have been tested by find_internal during
                initialization, but just in case... */
    {
        rc_error = "regexp_internal not found";
        return -1;
    }

    rdata = pr->data;

    if ((n < rdata->count) &&
        (rdata->what[n] == 's')) {
        SV *rv = (SV *)(rdata->data[n]);
        AV *av = (AV *)SvRV(rv);
        SV **ary = AvARRAY(av);
        SV *si = *ary;

#ifdef RC_UNCOND_CHARCLASS
        /* from get_regclass_nonbitmap_data of perl 5.30.0: invlist is
           in ary[0] */
        return convert_invlist_to_map(si,
                    !!(a->rn->flags & ANYOF_INVERT),
                    map);
#else
        if (si && (si != &PL_sv_undef))
        {
            /* From regcomp.c:regclass: the 0th element stores the
               character class description in its textual form. It isn't
               very clear what exactly the textual form is, but we hope
               it's 0-terminated. */
          return convert_desc_to_map(SvPV_nolen(*ary),
              !!(a->rn->flags & ANYOF_INVERT),
              map);
        }
/* FIXME: in perl 5.18, crashes for inverted classes */
        else
        {
            /* in perl 5.16, the textual form doesn't necessarily exist... */
            if (av_len(av) >= 3)
            {
                SV *invlist = ary[3];

                if (SvUV(ary[4])) /* invlist_has_user_defined_property */
                {
                    /* fprintf(stderr, "invlist has user defined property\n"); */
                    return 0;
                }

                return convert_invlist_to_map(invlist,
                    !!(a->rn->flags & ANYOF_INVERT),
                    map);
            }

            /* fprintf(stderr, "regclass invlist not found\n"); */
            return 0;
        }
#endif
    }

    rc_error = "regclass not found";
    return -1;
}

/* lifted from Perl__get_regclass_nonbitmap_data */
static SV *get_invlist_sv(Arrow *a)
{
    RXi_GET_DECL(a->origin, progi);
    struct reg_data *data = progi->data;

    assert((a->rn->type == ANYOF) || (a->rn->type == ANYOFD));

    if (data && data->count)
    {
        const U32 n = ARG(a->rn);

        if (data->what[n] == 's')
        {
            SV * const rv = MUTABLE_SV(data->data[n]);
            AV * const av = MUTABLE_AV(SvRV(rv));
            SV **const ary = AvARRAY(av);

#ifdef RC_UNCOND_CHARCLASS
            return *ary;
#else
            if (av_tindex(av) >= 3)
            {
                return ary[3];
            }
#endif
        }
    }

    return 0;
}

/* returns 1 OK (map set), 0 map not recognized/representable, -1
   unexpected input (rc_error set) */
static int convert_map(Arrow *a, U32 *map)
{
    /* fprintf(stderr, "enter convert_map\n"); */

    assert((a->rn->type == ANYOF) || (a->rn->type == ANYOFD));
    assert(map);

    if (ANYOF_FLAGS(a->rn) & (ANYOF_SHARED_d_UPPER_LATIN1_UTF8_STRING_MATCHES_non_d_RUNTIME_USER_PROP
#ifdef RC_UNCOND_CHARCLASS
            | ANYOF_INVERT
#endif
            ))
    {
        return convert_regclass_map(a, map);
    }
    else
    {
        /* fprintf(stderr, "zero map\n"); */
        *map = 0;
        return 1;
    }
}

/* returns 1 OK (map set), 0 map not recognized/representable */
static int convert_class_narrow(Arrow *a, U32 *map)
{
    /* fprintf(stderr, "enter convert_class_narrow\n"); */

    assert(map);

    if (a->rn->flags >= SIZEOF_ARRAY(posix_regclass_blocks))
    {
        /* fprintf(stderr, "unknown class %d\n", a->rn->flags); */
        return 0;
    }

    U32 mask = posix_regclass_blocks[a->rn->flags];
    if (!mask)
    {
        /* fprintf(stderr, "class %d ignored\n", a->rn->flags); */
        return 0;
    }

    *map = mask;
    return 1;
}

#ifdef RC_ANYOFM
/* Adapted from regcomp.c:get_ANYOFM_contents. b must point to
   ANYOF_BITMAP_SIZE bytes. Returns 1 OK (b set), 0 matches something
   above the bitmap. */
static int convert_anyofm_to_bitmap(Arrow *a, unsigned char *b)
{
    regnode *n = a->rn;
    U8 lowest = (U8)ARG(n);
    unsigned count = 0;
    unsigned needed = 1U << PL_bitcount[(U8)~FLAGS(n)];
    unsigned i;
    BitFlag bf;

    memset(b, 0, ANYOF_BITMAP_SIZE);
    for (i = lowest; i <= 0xFF; i++)
    {
        if ((i & FLAGS(n)) == ARG(n))
        {
            init_bit_flag(&bf, i);
            b[bf.offs] |= bf.mask;

            if (++count >= needed)
            {
                return 1;
            }
        }
    }

    return 0;
}
#endif

/* returns 1 OK (map set), 0 map not recognized/representable */
static int convert_class(Arrow *a, U32 *map)
{
    if (!convert_class_narrow(a, map))
    {
        return 0;
    }

    *map = extend_mask(*map);
    return 1;
}

static int convert_negative_class(Arrow *a, U32 *map)
{
    U32 mask;

    if (!convert_class_narrow(a, &mask))
    {
        return 0;
    }

    *map = extend_mask(MIRROR_BLOCK(mask));
    return 1;
}

static int get_assertion_offset(regnode *p)
{
    int offs;

    offs = ARG_LOC(p);
    if (offs <= 2)
    {
        rc_error = "Assertion offset too small";
        return -1;
    }

    return offs;
}

static int get_synth_offset(regnode *p)
{
    assert(!p->next_off);

    if (((p->type == EXACT) || (p->type == EXACTF) || (p->type == EXACTFU)) &&
        (p->flags == 1))
    {
        return 2;
    }
    else if (trivial_nodes[p->type] ||
             (p->type == REG_ANY) || (p->type == SANY) ||
             (p->type == POSIXD) || (p->type == NPOSIXD) ||
             (p->type == POSIXU) || (p->type == NPOSIXU) ||
             (p->type == POSIXA) || (p->type == NPOSIXA) ||
             (p->type == LNBREAK))
    {
        return 1;
    }
    else if ((p->type == ANYOF) || (p->type == ANYOFD))
    {
        /* other flags obviously exist, but they haven't been seen yet
           and it isn't clear what they mean */
        unsigned int unknown = p->flags & ~(ANYOF_INVERT |
            ANYOF_MATCHES_ALL_ABOVE_BITMAP | ANYOF_SHARED_d_UPPER_LATIN1_UTF8_STRING_MATCHES_non_d_RUNTIME_USER_PROP | ANYOF_SHARED_d_UPPER_LATIN1_UTF8_STRING_MATCHES_non_d_RUNTIME_USER_PROP);
        if (unknown)
        {
            /* p[10] seems always 0 on Linux, but 0xfbfaf9f8 seen on
               Windows; for '[\\w\\-_.]+\\.', both 0 and 0x20202020
               observed in p[11] - wonder what those are... */
            rc_error = "Unknown bitmap format";
            return -1;
        }

#ifndef RC_ANYOF_OFFSET
        return 11;
#else
        return 10;
#endif
    }
#ifdef RC_ANYOFM
    else if (p->type == ANYOFM)
    {
        return 2;
    }
#endif
#ifdef RC_NANYOFM
    else if (p->type == NANYOFM)
    {
        return 2;
    }
#endif
    else if ((p->type == IFMATCH) || (p->type == UNLESSM) ||
        (p->type == SUSPEND))
    {
        return get_assertion_offset(p);
    }

    /* fprintf(stderr, "type %d\n", p->type); */
    rc_error = "Offset not set";
    return -1;
}

static int get_size(regnode *rn)
{
    int offs;
    regnode *e = rn;

    while (e->type != END)
    {
        offs = GET_OFFSET(e);
        if (offs <= 0)
        {
            return -1;
        }

        e += offs;
    }

    return e - rn + 1;
}

/* #define DEBUG_dump_data */

static regnode *find_internal(regexp *pt)
{
    regexp_internal *pr;
    regnode *p;
#ifdef DEBUG_dump_data
    struct reg_data *rdata;
    int n;
#endif

    assert(pt);

/* ActivePerl Build 1001 doesn't export PL_core_reg_engine, so
   the test, however useful, wouldn't link... */
#if !defined(ACTIVEPERL_PRODUCT)
    if (pt->engine && (pt->engine != &PL_core_reg_engine))
    {
        rc_error = "Alternative regexp engine not supported";
        return 0;
    }
#endif

    pr = RXi_GET(pt);
    if (!pr)
    {
        rc_error = "Internal regexp not set";
        return 0;
    }

    p = pr->program;
    if (!p)
    {
        rc_error = "Compiled regexp not set";
        return 0;
    }

    if (!((p->flags == REG_MAGIC) &&
        (p->next_off == 0)))
    {
        /* fprintf(stderr, "%d %d %d\n", p->flags, p->type, p->next_off); */
        rc_error = "Invalid regexp signature";
        return 0;
    }

#ifdef DEBUG_dump_data
    rdata = pr->data;
    if (rdata)
    {
        fprintf(stderr, "regexp data count = %d\n", (int)(rdata->count));
        for (n = 0; n < rdata->count; ++n)
        {
            fprintf(stderr, "\twhat[%d] = %c\n", n, rdata->what[n]);
        }
    }
    else
    {
        fprintf(stderr, "no regexp data\n");
    }
#endif

    return p + 1;
}

static unsigned char parse_hex_digit(char d)
{
    unsigned char rv;

    d = tolower(d);

    if (('0' <= d) && (d <= '9'))
    {
        rv = d - '0';
    }
    else
    {
        rv = 10 + (d - 'a');
    }

    return rv;
}

static unsigned char parse_hex_byte(const char *first)
{
    return 16 * parse_hex_digit(*first) +
        parse_hex_digit(first[1]);
}

static unsigned get_forced_semantics(REGEXP *pt)
{
    const char *precomp = RX_PRECOMP(pt);
    U32 prelen = RX_PRELEN(pt);
    int quoted = 0;
    int matched;
    unsigned forced = 0;
    U32 i;
    BitFlag bf;
    char c;

    /* fprintf(stderr, "precomp = %*s\n", (int)prelen, precomp); */

    for (i = 0; i < prelen; ++i)
    {
        c = precomp[i];

        if (c == '.')
        {
            /* a dot does match Unicode character - the problem is
               that character might take up multiple bytes, and we
               don't want to match just one of them... */
            forced |= FORCED_BYTE;
        }

        if (!quoted)
        {
            /* technically, the backslash might be in a comment, but
               parsing that is too much hassle */
            if (c == '\\')
            {
                quoted = 1;
            }
        }
        else
        {
            matched = 0;

            if (c == 'N')
            {
                /* we have special cases only for \r & \n... */
                if ((i + 8 < prelen) &&
                    !memcmp(precomp + i + 1, "{U+00", 5) &&
                    isxdigit(precomp[i + 6]) && isxdigit(precomp[i + 7]) &&
                    (precomp[i + 8] == '}'))
                {
                    unsigned char x = parse_hex_byte(precomp + i + 6);
                    if ((x != '\r') && (x != '\n'))
                    {
                        forced |= FORCED_CHAR;
                    }

                    i += 8;
                }
                else if ((i + 1 < prelen) &&
                    (precomp[i + 1] == '{'))
                {
                    forced |= FORCED_CHAR;
                }

                /* otherwise it's not an escape, but the inverse of \n
                   - we aren't interested in that */

                matched = 1;
            }
            else if (c == 'x')
            {
                if ((i + 2 < prelen) &&
                    isxdigit(precomp[i + 1]) && isxdigit(precomp[i + 2]))
                {
                    unsigned char x = parse_hex_byte(precomp + i + 1);
                    if ((x != '\r') && (x != '\n'))
                    {
                        forced |= FORCED_BYTE;
                    }

                    matched = 1;
                    i += 2;
                }
            }

            /* ...and we aren't bothering to parse octal numbers
               and \x{n+} at all... */

            if (!matched)
            {
                init_bit_flag(&bf, (unsigned char)c);
                if (forced_byte[bf.offs] & bf.mask)
                {
                    forced |= FORCED_BYTE;
                }
            }

            quoted = 0;
        }
    }

    return forced;
}

static regnode *alloc_alt(regnode *p, int sz)
{
    regnode *alt;

    alt = (regnode *)malloc(sizeof(regnode) * sz);
    if (!alt)
    {
        rc_error = "Could not allocate memory for regexp copy";
        return 0;
    }

    memcpy(alt, p, sizeof(regnode) * sz);

    return alt;
}

static regnode *alloc_terminated(regnode *p, int sz)
{
    regnode *alt;
    int last;

    /* fprintf(stderr, "enter alloc_terminated(, %d\n", sz); */

    assert(sz > 0);
    alt = alloc_alt(p, sz);
    if (!alt)
    {
        return 0;
    }

    last = alt[sz - 1].type;
    /* fprintf(stderr, "type: %d\n", last); */
    if ((last >= REGNODE_MAX) || !trivial_nodes[last])
    {
        rc_error = "Alternative doesn't end like subexpression";
        return 0;
    }

    alt[sz - 1].type = END;
    return alt;
}

static int bump_exact(Arrow *a)
{
    int offs;

    assert((a->rn->type == EXACT) || (a->rn->type == EXACTF) || (a->rn->type == EXACTFU)
#ifdef RC_EXACT_ONLY8
           || (a->rn->type == EXACT_ONLY8)
#endif
        );

    offs = GET_OFFSET(a->rn);
    if (offs <= 0)
    {
        return -1;
    }

#ifdef RC_EXACT_ONLY8
    if (a->rn->type == EXACT_ONLY8)
    {
        while (*(((unsigned char *)((a)->rn + 1)) + (a)->spent) & 0x80)
        {
            ++(a->spent);
        }
    }
#endif

    if (++(a->spent) >= a->rn->flags)
    {
        a->spent = 0;
        a->rn += offs;
    }

    return 1;
}

static int bump_regular(Arrow *a)
{
    int offs;

    assert(a->rn->type != END);
    assert(a->rn->type != EXACT);
    assert(a->rn->type != EXACTF);
    assert(!a->spent);

    offs = GET_OFFSET(a->rn);
    if (offs <= 0)
    {
        return -1;
    }

    a->rn += offs;
    return 1;
}

static int bump_with_check(Arrow *a)
{
    if (a->rn->type == END)
    {
        return 0;
    }
    else if ((a->rn->type == EXACT) || (a->rn->type == EXACTF) || (a->rn->type == EXACTFU)
#ifdef RC_EXACT_ONLY8
             || (a->rn->type == EXACT_ONLY8)
#endif
        )
    {
        return bump_exact(a);
    }
    else
    {
        return bump_regular(a);
    }
}

static int get_jump_offset(regnode *p)
{
    int offs;
    regnode *q;

    assert(p->type != END);

    offs = GET_OFFSET(p);
    if (offs <= 0)
    {
        return -1;
    }

    q = p + offs;
    while (trivial_nodes[q->type])
    {
        offs = GET_OFFSET(q);
        if (offs <= 0)
        {
            return -1;
        }

        q += offs;
    }

    return q - p;
}

REGEXP *rc_regcomp(SV *rs)
{
    REGEXP *rx;

    if (!rs)
    {
        croak("No regexp to compare");
    }

    rx = pregcomp(rs, 0);
    if (!rx)
    {
        croak("Cannot compile regexp");
    }

    return rx;
}

void rc_regfree(REGEXP *rx)
{
    if (rx)
    {
        pregfree(rx);
    }
}

static int compare_mismatch(int anchored, Arrow *a1, Arrow *a2)
{
    int rv;

    /* fprintf(stderr, "enter compare_mismatch(%d...)\n", anchored); */

    if (anchored)
    {
        return 0;
    }
    else
    {
        rv = bump_with_check(a1);
        if (rv <= 0)
        {
            return rv;
        }

        return compare(0, a1, a2);
    }
}

static int compare_tails(int anchored, Arrow *a1, Arrow *a2)
{
    Arrow tail1, tail2;
    int rv;

    /* is it worth using StructCopy? */
    tail1 = *a1;
    rv = bump_with_check(&tail1);
    if (rv <= 0)
    {
        return rv;
    }

    tail2 = *a2;
    rv = bump_with_check(&tail2);
    if (rv <= 0)
    {
        return rv;
    }

    rv = compare(1, &tail1, &tail2);
    if (rv < 0)
    {
        return rv;
    }

    if (!rv)
    {
        rv = compare_mismatch(anchored, a1, a2);
    }
    else
    {
        *a1 = tail1;
        *a2 = tail2;
    }

    return rv;
}

static int compare_left_tail(int anchored, Arrow *a1, Arrow *a2)
{
    Arrow tail1;
    int rv;

    tail1 = *a1;
    rv = bump_with_check(&tail1);
    if (rv <= 0)
    {
        return rv;
    }

    return compare(anchored, &tail1, a2);
}

static int compare_after_assertion(int anchored, Arrow *a1, Arrow *a2)
{
    Arrow tail1;
    int offs;

    assert((a1->rn->type == IFMATCH) || (a1->rn->type == UNLESSM));

    offs = get_assertion_offset(a1->rn);
    if (offs < 0)
    {
        return offs;
    }

    tail1.origin = a1->origin;
    tail1.rn = a1->rn + offs;
    tail1.spent = 0;
    return compare(anchored, &tail1, a2);
}

static int compare_positive_assertions(int anchored, Arrow *a1, Arrow *a2)
{
    regnode *p1, *alt1, *p2, *alt2;
    int rv, sz1, sz2;
    Arrow left, right;

    p1 = a1->rn;
    p2 = a2->rn;
    assert(p1->type == IFMATCH);
    assert(p2->type == IFMATCH);

    sz1 = get_assertion_offset(p1);
    if (sz1 < 0)
    {
        return -1;
    }

    sz2 = get_assertion_offset(p2);
    if (sz2 < 0)
    {
        return -1;
    }

    alt1 = alloc_terminated(p1 + 2, sz1 - 2);
    if (!alt1)
    {
        return -1;
    }

    alt2 = alloc_terminated(p2 + 2, sz2 - 2);
    if (!alt2)
    {
        free(alt1);
        return -1;
    }

    left.origin = a1->origin;
    left.rn = alt1;
    left.spent = 0;
    right.origin = a2->origin;
    right.rn = alt2;
    right.spent = 0;
    rv = compare(0, &left, &right);

    free(alt1);
    free(alt2);

    if (rv <= 0)
    {
        return rv;
    }

    /* left & right.origin stays a1 & a2->origin, respectively */
    left.rn = p1 + sz1;
    left.spent = 0;
    right.rn = p2 + sz2;
    right.spent = 0;
    return compare(anchored, &left, &right);
}

static int compare_negative_assertions(int anchored, Arrow *a1, Arrow *a2)
{
    regnode *p1, *alt1, *p2, *alt2;
    int rv, sz1, sz2;
    Arrow left, right;

    p1 = a1->rn;
    p2 = a2->rn;
    assert(p1->type == UNLESSM);
    assert(p2->type == UNLESSM);

    sz1 = get_assertion_offset(p1);
    if (sz1 < 0)
    {
        return -1;
    }

    sz2 = get_assertion_offset(p2);
    if (sz2 < 0)
    {
        return -1;
    }

    alt1 = alloc_terminated(p1 + 2, sz1 - 2);
    if (!alt1)
    {
        return -1;
    }

    alt2 = alloc_terminated(p2 + 2, sz2 - 2);
    if (!alt2)
    {
        free(alt1);
        return -1;
    }

    left.origin = a1->origin;
    left.rn = alt1;
    left.spent = 0;
    right.origin = a2->origin;
    right.rn = alt2;
    right.spent = 0;
    rv = compare(0, &right, &left);

    free(alt1);
    free(alt2);

    if (rv <= 0)
    {
        return rv;
    }

    /* left & right.origin stays a1 & a2->origin, respectively */
    left.rn = p1 + sz1;
    left.spent = 0;
    right.rn = p2 + sz2;
    right.spent = 0;
    return compare(anchored, &left, &right);
}

static int compare_subexpressions(int anchored, Arrow *a1, Arrow *a2)
{
    regnode *p1, *alt1, *p2, *alt2;
    int rv, sz1, sz2;
    Arrow left, right;

    p1 = a1->rn;
    p2 = a2->rn;
    assert(p1->type == SUSPEND);
    assert(p2->type == SUSPEND);

    sz1 = get_assertion_offset(p1);
    if (sz1 < 0)
    {
        return -1;
    }

    sz2 = get_assertion_offset(p2);
    if (sz2 < 0)
    {
        return -1;
    }

    alt1 = alloc_terminated(p1 + 2, sz1 - 2);
    if (!alt1)
    {
        return -1;
    }

    alt2 = alloc_terminated(p2 + 2, sz2 - 2);
    if (!alt2)
    {
        free(alt1);
        return -1;
    }

    left.origin = a1->origin;
    left.rn = alt1;
    left.spent = 0;
    right.origin = a2->origin;
    right.rn = alt2;
    right.spent = 0;
    rv = compare(1, &left, &right);

    free(alt1);
    free(alt2);

    if (rv <= 0)
    {
        return rv;
    }

    /* left & right.origin stays a1 & a2->origin, respectively */
    left.rn = p1 + sz1;
    left.spent = 0;
    right.rn = p2 + sz2;
    right.spent = 0;
    return compare(1, &left, &right);
}

static int compare_bol(int anchored, Arrow *a1, Arrow *a2)
{
    int rv;

    assert((a1->rn->type == MBOL) || (a1->rn->type == SBOL));

    if (anchored)
    {
        return 0;
    }

    if (bump_regular(a1) <= 0)
    {
        return -1;
    }

    rv = compare(1, a1, a2);
    if (!rv)
    {
        rv = compare_mismatch(0, a1, a2);
    }

    return rv;
}

static unsigned char get_bitmap_byte(regnode *p, int i)
{
    unsigned char *bitmap;
    unsigned char loc;

    assert((p->type == ANYOF) || (p->type == ANYOFD));

    bitmap = (unsigned char *)(p + 2);
#ifdef RC_SHORT_BITMAP
    if ((i >= 16) && (p->type == ANYOFD) &&
        (p->flags & ANYOF_SHARED_d_MATCHES_ALL_NON_UTF8_NON_ASCII_non_d_WARN_SUPER))
    {
        loc = 0xff;
    }
    else
    {
        loc = bitmap[i];
    }
#else
    loc = bitmap[i];
#endif
    if (p->flags & ANYOF_INVERT)
    {
        loc = ~loc;
    }

    return loc;
}

static int compare_bitmaps(int anchored, Arrow *a1, Arrow *a2,
    unsigned char *b1, unsigned char *b2)
{
    /* Note that aN->flags must be ignored when bN is set (necessary
    for ANYOFM, where they aren't really flags and can't be used as
    such). */
    unsigned char loc1, loc2;
    int i;

    /* fprintf(stderr, "enter compare_bitmaps(%d, %d, %d)\n", anchored,
        a1->rn->type, a2->rn->type); */

    for (i = 0; i < ANYOF_BITMAP_SIZE; ++i)
    {
        loc1 = b1 ? b1[i] : get_bitmap_byte(a1->rn, i);
        loc2 = b2 ? b2[i] : get_bitmap_byte(a2->rn, i);
        if (loc1 & ~loc2)
        {
            /* fprintf(stderr, "compare_bitmaps fails at %d: %d does not imply %d\n",
                i, loc1, loc2); */
            return compare_mismatch(anchored, a1, a2);
        }
    }

    return compare_tails(anchored, a1, a2);
}

#ifdef RC_NANYOFM
static int compare_negative_bitmaps(int anchored, Arrow *a1, Arrow *a2,
    unsigned char *b1, unsigned char *b2)
{
    unsigned char loc1, loc2;
    int i;

    assert(b1 && b2);
    for (i = 0; i < ANYOF_BITMAP_SIZE; ++i)
    {
        loc1 = b1[i];
        loc2 = b2[i];
        if (~loc1 & loc2)
        {
            return compare_mismatch(anchored, a1, a2);
        }
    }

    return compare_tails(anchored, a1, a2);
}
#endif

static int compare_anyof_multiline(int anchored, Arrow *a1, Arrow *a2)
{
    BitFlag bf;
    Arrow tail1, tail2;
    unsigned char req;
    int i;

    /* fprintf(stderr, "enter compare_anyof_multiline\n"); */

    assert((a1->rn->type == ANYOF) || (a1->rn->type == ANYOFD));
    assert((a2->rn->type == MBOL) || (a2->rn->type == MEOL));

    if (a1->rn->flags & ANYOF_MATCHES_ALL_ABOVE_BITMAP)
    {
        return compare_mismatch(anchored, a1, a2);
    }

    init_bit_flag(&bf, '\n');
    for (i = 0; i < ANYOF_BITMAP_SIZE; ++i)
    {
        req = (i != bf.offs) ? 0 : bf.mask;
        if (get_bitmap_byte(a1->rn, i) != req)
        {
            return compare_mismatch(anchored, a1, a2);
        }
    }

    tail1 = *a1;
    if (bump_regular(&tail1) <= 0)
    {
        return -1;
    }

    tail2 = *a2;
    if (bump_regular(&tail2) <= 0)
    {
        return -1;
    }

    return compare(1, &tail1, &tail2);
}

#ifdef RC_ANYOFM
static int compare_anyofm_multiline(int anchored, Arrow *a1, Arrow *a2)
{
    unsigned char req;
    int i;
    BitFlag bf;
    Arrow tail1, tail2;
    unsigned char left[ANYOF_BITMAP_SIZE];

    assert(a1->rn->type == ANYOFM);
    assert((a2->rn->type == MBOL) || (a2->rn->type == MEOL));

    if (!convert_anyofm_to_bitmap(a1, left))
    {
        return compare_mismatch(anchored, a1, a2);
    }

    init_bit_flag(&bf, '\n');
    for (i = 0; i < ANYOF_BITMAP_SIZE; ++i)
    {
        req = (i != bf.offs) ? 0 : bf.mask;
        if (left[i] != req)
        {
            return compare_mismatch(anchored, a1, a2);
        }
    }

    tail1 = *a1;
    if (bump_regular(&tail1) <= 0)
    {
        return -1;
    }

    tail2 = *a2;
    if (bump_regular(&tail2) <= 0)
    {
        return -1;
    }

    return compare(1, &tail1, &tail2);
}
#endif

#ifdef RC_NANYOFM
static int compare_nanyofm_multiline(int anchored, Arrow *a1, Arrow *a2)
{
    unsigned char req;
    int i;
    BitFlag bf;
    Arrow tail1, tail2;
    unsigned char left[ANYOF_BITMAP_SIZE];

    assert(a1->rn->type == NANYOFM);
    assert((a2->rn->type == MBOL) || (a2->rn->type == MEOL));

    if (!convert_anyofm_to_bitmap(a1, left))
    {
        return compare_mismatch(anchored, a1, a2);
    }

    for (i = 0; i < ANYOF_BITMAP_SIZE; ++i)
    {
        left[i] = ~left[i];
    }

    init_bit_flag(&bf, '\n');
    for (i = 0; i < ANYOF_BITMAP_SIZE; ++i)
    {
        req = (i != bf.offs) ? 0 : bf.mask;
        if (left[i] != req)
        {
            return compare_mismatch(anchored, a1, a2);
        }
    }

    tail1 = *a1;
    if (bump_regular(&tail1) <= 0)
    {
        return -1;
    }

    tail2 = *a2;
    if (bump_regular(&tail2) <= 0)
    {
        return -1;
    }

    return compare(1, &tail1, &tail2);
}
#endif

static int compare_anyof_anyof(int anchored, Arrow *a1, Arrow *a2)
{
    int extra_left;

    /* fprintf(stderr, "enter compare_anyof_anyof(%d\n", anchored); */

    assert((a1->rn->type == ANYOF) || (a1->rn->type == ANYOFD));
    assert((a2->rn->type == ANYOF) || (a2->rn->type == ANYOFD));

    extra_left = ANYOF_FLAGS(a1->rn) &
        ANYOF_SHARED_d_UPPER_LATIN1_UTF8_STRING_MATCHES_non_d_RUNTIME_USER_PROP;
    if ((extra_left || (a1->rn->flags & ANYOF_MATCHES_ALL_ABOVE_BITMAP)) &&
        !(a2->rn->flags & ANYOF_MATCHES_ALL_ABOVE_BITMAP))
    {
        U32 m1, m2;
        int cr1, cr2;

        /* fprintf(stderr, "comparing invlists: left flags = 0x%x, right flags = 0x%x\n", (int)(a1->rn->flags), (int)(a2->rn->flags)); */
        /* before recognizing standard invlists, check whether they
           aren't the same - this duplicates the code to get to the
           invlist, but works even for non-standard ones,
           e.g. [\da] */
        if ((a1->rn->flags & ANYOF_SHARED_d_UPPER_LATIN1_UTF8_STRING_MATCHES_non_d_RUNTIME_USER_PROP) &&
            (a2->rn->flags & ANYOF_SHARED_d_UPPER_LATIN1_UTF8_STRING_MATCHES_non_d_RUNTIME_USER_PROP))
        {
            SV *invlist1 = get_invlist_sv(a1);
            SV *invlist2 = get_invlist_sv(a2);
            if (invlist1 && invlist2)
            {
                UV ill1 = get_invlist_len(invlist1);
                UV ill2 = get_invlist_len(invlist2);
                if (ill1 && (ill1 == ill2))
                {
                    UV *ila1 = invlist_array(invlist1);
                    UV *ila2 = invlist_array(invlist2);
                    if (!memcmp(ila1, ila2, ill1 * sizeof(UV)))
                    {
                        return compare_bitmaps(anchored, a1, a2, 0, 0);
                    }
                }
            }
        }

        cr1 = convert_map(a1, &m1);
        if (cr1 == -1)
        {
            return -1;
        }

        cr2 = convert_map(a2, &m2);
        if (cr2 == -1)
        {
            return -1;
        }

        /* clearly this hould happen at a lower level, but there it
           breaks other paths... */
        if (m2 & NOT_ALNUM_BLOCK)
        {
            m2 |= NOT_ALPHA_BLOCK | NOT_NUMBER_BLOCK;
            m2 = extend_mask(m2);
        }

        if (!cr1 || !cr2 || (m1 & ~m2))
        {
            /* fprintf(stderr, "cr1 = %d, cr2 = %d, m1 = 0x%x, m2 = 0x%x\n",
                cr1, cr2, (unsigned)m1, (unsigned)m2); */
            return compare_mismatch(anchored, a1, a2);
        }
    }

    return compare_bitmaps(anchored, a1, a2, 0, 0);
}

#ifdef RC_ANYOFM
static int compare_anyof_anyofm(int anchored, Arrow *a1, Arrow *a2)
{
    unsigned char right[ANYOF_BITMAP_SIZE];

    /* fprintf(stderr, "enter compare_anyof_anyofm(%d\n", anchored); */

    assert((a1->rn->type == ANYOF) || (a1->rn->type == ANYOFD));
    assert(a2->rn->type == ANYOFM);

    if (ANYOF_FLAGS(a1->rn) & ANYOF_SHARED_d_UPPER_LATIN1_UTF8_STRING_MATCHES_non_d_RUNTIME_USER_PROP)
    {
        return compare_mismatch(anchored, a1, a2);
    }

    if (!convert_anyofm_to_bitmap(a2, right))
    {
        return compare_mismatch(anchored, a1, a2);
    }

    return compare_bitmaps(anchored, a1, a2, 0, right);
}

static int compare_anyofm_anyof(int anchored, Arrow *a1, Arrow *a2)
{
    unsigned char left[ANYOF_BITMAP_SIZE];

    /* fprintf(stderr, "enter compare_anyofm_anyof(%d\n", anchored); */

    assert(a1->rn->type == ANYOFM);
    assert((a2->rn->type == ANYOF) || (a2->rn->type == ANYOFD));

    if (!convert_anyofm_to_bitmap(a1, left))
    {
        return compare_mismatch(anchored, a1, a2);
    }

    return compare_bitmaps(anchored, a1, a2, left, 0);
}

static int compare_anyofm_anyofm(int anchored, Arrow *a1, Arrow *a2)
{
    unsigned char left[ANYOF_BITMAP_SIZE];
    unsigned char right[ANYOF_BITMAP_SIZE];

    assert(a1->rn->type == ANYOFM);
    assert(a2->rn->type == ANYOFM);

    if (!convert_anyofm_to_bitmap(a1, left))
    {
        return compare_mismatch(anchored, a1, a2);
    }

    if (!convert_anyofm_to_bitmap(a2, right))
    {
        return compare_mismatch(anchored, a1, a2);
    }

    return compare_bitmaps(anchored, a1, a2, left, right);
}
#endif

#ifdef RC_NANYOFM
static int compare_anyof_nanyofm(int anchored, Arrow *a1, Arrow *a2)
{
    int i;
    unsigned char right[ANYOF_BITMAP_SIZE];

    /* fprintf(stderr, "enter compare_anyof_nanyofn(%d\n", anchored); */

    assert((a1->rn->type == ANYOF) || (a1->rn->type == ANYOFD));
    assert(a2->rn->type == NANYOFM);

    /* fprintf(stderr, "left flags = 0x%x\n", a1->rn->flags); */

    if ((a1->rn->flags & ANYOF_SHARED_d_UPPER_LATIN1_UTF8_STRING_MATCHES_non_d_RUNTIME_USER_PROP) ||
        ((a1->rn->flags & ANYOF_SHARED_d_MATCHES_ALL_NON_UTF8_NON_ASCII_non_d_WARN_SUPER) &&
         !(a1->rn->flags & ANYOF_INVERT)))
    {
        return compare_mismatch(anchored, a1, a2);
    }

    if (!convert_anyofm_to_bitmap(a2, right))
    {
        return compare_mismatch(anchored, a1, a2);
    }

    for (i = 0; i < ANYOF_BITMAP_SIZE; ++i)
    {
        right[i] = ~right[i];
    }

    return compare_bitmaps(anchored, a1, a2, 0, right);
}

static int compare_anyofm_nanyofm(int anchored, Arrow *a1, Arrow *a2)
{
    int i;
    unsigned char left[ANYOF_BITMAP_SIZE];
    unsigned char right[ANYOF_BITMAP_SIZE];

    assert(a1->rn->type == ANYOFM);
    assert(a2->rn->type == NANYOFM);

    if (!convert_anyofm_to_bitmap(a1, left))
    {
        return compare_mismatch(anchored, a1, a2);
    }

    if (!convert_anyofm_to_bitmap(a2, right))
    {
        return compare_mismatch(anchored, a1, a2);
    }

    for (i = 0; i < ANYOF_BITMAP_SIZE; ++i)
    {
        right[i] = ~right[i];
    }

    return compare_bitmaps(anchored, a1, a2, left, right);
}

static int compare_nanyofm_nanyofm(int anchored, Arrow *a1, Arrow *a2)
{
    unsigned char left[ANYOF_BITMAP_SIZE];
    unsigned char right[ANYOF_BITMAP_SIZE];

    assert(a1->rn->type == NANYOFM);
    assert(a2->rn->type == NANYOFM);

    if (!convert_anyofm_to_bitmap(a1, left))
    {
        return compare_mismatch(anchored, a1, a2);
    }

    if (!convert_anyofm_to_bitmap(a2, right))
    {
        return compare_mismatch(anchored, a1, a2);
    }

    return compare_negative_bitmaps(anchored, a1, a2, left, right);
}
#endif

/* compare_bitmaps could replace this method, but when a class
   contains just a few characters, it seems more natural to compare
   them explicitly */
static int compare_short_byte_class(int anchored, Arrow *a1, Arrow *a2,
    ByteClass *left)
{
    BitFlag bf;
    int i;

    for (i = 0; i < left->expl_size; ++i)
    {
        init_bit_flag(&bf, (unsigned char)left->expl[i]);
        if (!(get_bitmap_byte(a2->rn, bf.offs) & bf.mask))
        {
            return compare_mismatch(anchored, a1, a2);
        }
    }

    return compare_tails(anchored, a1, a2);
}

static int compare_right_full(int anchored, Arrow *a1, Arrow *a2)
{
    int i;

    for (i = 0; i < 16; ++i)
    {
        if (!(get_bitmap_byte(a2->rn, i) & 0xff))
        {
            return compare_mismatch(anchored, a1, a2);
        }
    }

    return compare_tails(anchored, a1, a2);
}

static int compare_posix_posix(int anchored, Arrow *a1, Arrow *a2)
{
    U32 m1, m2;
    int cr1, cr2;

    /* fprintf(stderr, "enter compare_posix_posix\n"); */

    cr1 = convert_class(a1, &m1);
    cr2 = convert_class(a2, &m2);
    if (!cr1 || !cr2 || (m1 & ~m2))
    {
        return compare_mismatch(anchored, a1, a2);
    }

    return compare_tails(anchored, a1, a2);
}

static int compare_posix_negative_posix(int anchored, Arrow *a1, Arrow *a2)
{
    U32 m1, m2;
    int cr1, cr2;

    /* fprintf(stderr, "enter compare_posix_negative_posix\n"); */

    cr1 = convert_class(a1, &m1);
    cr2 = convert_class(a2, &m2);
    if (!cr1 || !cr2)
    {
        return compare_mismatch(anchored, a1, a2);
    }

    /* vertical space is not a strict subset of space, but it does
       have space elements, so we have to require space on the right */
    if ((m1 & VERTICAL_SPACE_BLOCK) && !(m2 & VERTICAL_SPACE_BLOCK))
    {
        m1 |= SPACE_BLOCK;
    }

    if (m1 & m2)
    {
        return compare_mismatch(anchored, a1, a2);
    }

    return compare_tails(anchored, a1, a2);
}

static int compare_negative_posix_negative_posix(int anchored, Arrow *a1, Arrow *a2)
{
    U32 m1, m2;
    int cr1, cr2;

    assert((a1->rn->type == NPOSIXD) || (a1->rn->type == NPOSIXU) ||
        (a1->rn->type == NPOSIXA));
    assert((a2->rn->type == NPOSIXD) || (a2->rn->type == NPOSIXU) ||
        (a2->rn->type == NPOSIXA));

    /* fprintf(stderr, "enter compare_negative_posix_negative_posix\n"); */

    cr1 = convert_negative_class(a1, &m1);
    cr2 = convert_negative_class(a2, &m2);
    if (!cr2 || !cr2 || (m1 & ~m2))
    {
        return compare_mismatch(anchored, a1, a2);
    }

    return compare_tails(anchored, a1, a2);
}

static int compare_exact_posix(int anchored, Arrow *a1, Arrow *a2)
{
    char *seq;

    assert((a1->rn->type == EXACT) || (a1->rn->type == EXACTF) ||
        (a1->rn->type == EXACTFU));
    assert((a2->rn->type == POSIXD) || (a2->rn->type == POSIXU) ||
        (a2->rn->type == POSIXA));

    seq = GET_LITERAL(a1);

    if (!_generic_isCC_A(*seq, a2->rn->flags))
    {
        return compare_mismatch(anchored, a1, a2);
    }

    return compare_tails(anchored, a1, a2);
}

static int compare_exactf_posix(int anchored, Arrow *a1, Arrow *a2)
{
    char *seq;
    char unf[2];
    int i;

    assert((a1->rn->type == EXACTF) || (a1->rn->type == EXACTFU));
    assert(a2->rn->type == POSIXD);

    seq = GET_LITERAL(a1);
    init_unfolded(unf, *seq);

    for (i = 0; i < 2; ++i)
    {
        if (!_generic_isCC_A(unf[i], a2->rn->flags))
        {
            return compare_mismatch(anchored, a1, a2);
        }
    }

    return compare_tails(anchored, a1, a2);
}

static int compare_exact_negative_posix(int anchored, Arrow *a1, Arrow *a2)
{
    char *seq;

    assert(a1->rn->type == EXACT);
    assert((a2->rn->type == NPOSIXD) || (a2->rn->type == NPOSIXU) ||
        (a2->rn->type == NPOSIXA));

    seq = GET_LITERAL(a1);

    if (_generic_isCC_A(*seq, a2->rn->flags))
    {
        return compare_mismatch(anchored, a1, a2);
    }

    return compare_tails(anchored, a1, a2);
}

static int compare_exactf_negative_posix(int anchored, Arrow *a1, Arrow *a2)
{
    char *seq;
    char unf[2];
    int i;

    assert((a1->rn->type == EXACTF) || (a1->rn->type == EXACTFU));
    assert((a2->rn->type == NPOSIXD) || (a2->rn->type == NPOSIXU) ||
        (a2->rn->type == NPOSIXA));

    seq = GET_LITERAL(a1);
    init_unfolded(unf, *seq);

    for (i = 0; i < 2; ++i)
    {
        if (_generic_isCC_A(unf[i], a2->rn->flags))
        {
            return compare_mismatch(anchored, a1, a2);
        }
    }

    return compare_tails(anchored, a1, a2);
}

static int compare_reg_any_anyof(int anchored, Arrow *a1, Arrow *a2)
{
    assert(a1->rn->type == REG_ANY);
    assert((a2->rn->type == ANYOF) || (a2->rn->type == ANYOFD));

    return compare_bitmaps(anchored, a1, a2, ndot.nbitmap, 0);
}

static int compare_posix_anyof(int anchored, Arrow *a1, Arrow *a2)
{
    U32 left_block;
    unsigned char *b;

    /* fprintf(stderr, "enter compare_posix_anyof\n"); */

    assert((a1->rn->type == POSIXD) || (a1->rn->type == POSIXU) ||
        (a1->rn->type == POSIXA));
    assert((a2->rn->type == ANYOF) || (a2->rn->type == ANYOFD));

    if (!convert_class_narrow(a1, &left_block))
    {
        return compare_mismatch(anchored, a1, a2);
    }

    /* fprintf(stderr, "right flags = %d\n", a2->rn->flags); */

    if (!(a2->rn->flags & ANYOF_MATCHES_ALL_ABOVE_BITMAP))
    {
        U32 right_map;

#ifndef RC_UNCOND_CHARCLASS
        /* apparently a special case... */
        if (a2->rn->flags & ANYOF_INVERT)
        {
            return compare_mismatch(anchored, a1, a2);
        }
#endif

        int cr = convert_map(a2, &right_map);
        if (cr == -1)
        {
            return -1;
        }

        if (!cr || !(right_map & left_block))
        {
            return compare_mismatch(anchored, a1, a2);
        }
    }

    /* fprintf(stderr, "left flags = %d\n", a1->rn->flags); */

    if (a1->rn->flags >= SIZEOF_ARRAY(posix_regclass_bitmaps))
    {
        return compare_mismatch(anchored, a1, a2);
    }

    b = posix_regclass_bitmaps[a1->rn->flags];
    if (!b)
    {
        return compare_mismatch(anchored, a1, a2);
    }

    return compare_bitmaps(anchored, a1, a2, b, 0);
}

static int compare_negative_posix_anyof(int anchored, Arrow *a1, Arrow *a2)
{
    U32 left_block;
    unsigned char *b;

    /* fprintf(stderr, "enter compare_negative_posix_anyof\n"); */

    assert((a1->rn->type == NPOSIXD) || (a1->rn->type == NPOSIXU) ||
        (a1->rn->type == NPOSIXA));
    assert((a2->rn->type == ANYOF) || (a2->rn->type == ANYOFD));

    if (!convert_class_narrow(a1, &left_block))
    {
        return compare_mismatch(anchored, a1, a2);
    }

    /* fprintf(stderr, "right flags = 0x%x\n", a2->rn->flags); */

    left_block = EVERY_BLOCK & ~left_block;

    /* fprintf(stderr, "left %d -> 0x%x\n", a1->rn->flags, (unsigned)left_block); */

    if (!(a2->rn->flags & ANYOF_MATCHES_ALL_ABOVE_BITMAP))
    {
        U32 right_map;

#ifndef RC_UNCOND_CHARCLASS
        /* analogically with compare_posix_anyof but untested */
        if (a2->rn->flags & ANYOF_INVERT)
        {
            return compare_mismatch(anchored, a1, a2);
        }
#endif

        int cr = convert_map(a2, &right_map);
        if (cr == -1)
        {
            return -1;
        }

#ifdef RC_UNCOND_CHARCLASS
        if (a2->rn->flags & ANYOF_INVERT)
        {
            right_map = EVERY_BLOCK & ~right_map;
        }
#endif

        /* fprintf(stderr, "right map = 0x%x\n", (unsigned)right_map); */

        if (!cr || !(right_map & left_block))
        {
            return compare_mismatch(anchored, a1, a2);
        }
    }

    if (a1->rn->flags >= SIZEOF_ARRAY(posix_regclass_bitmaps))
    {
        return compare_mismatch(anchored, a1, a2);
    }

    b = posix_regclass_nbitmaps[a1->rn->flags];
    if (!b)
    {
        return compare_mismatch(anchored, a1, a2);
    }

    return compare_bitmaps(anchored, a1, a2, b, 0);
}

static int compare_exact_anyof(int anchored, Arrow *a1, Arrow *a2)
{
    BitFlag bf;
    char *seq;

    /* fprintf(stderr, "enter compare_exact_anyof(%d, \n", anchored); */

    assert(a1->rn->type == EXACT);
    assert((a2->rn->type == ANYOF) || (a2->rn->type == ANYOFD));

    seq = GET_LITERAL(a1);
    init_bit_flag(&bf, (unsigned char)(*seq));

    if (!(get_bitmap_byte(a2->rn, bf.offs) & bf.mask))
    {
        return compare_mismatch(anchored, a1, a2);
    }

    return compare_tails(anchored, a1, a2);
}

static int compare_exactf_anyof(int anchored, Arrow *a1, Arrow *a2)
{
    BitFlag bf;
    char *seq;
    char unf[2];
    int i;

    /* fprintf(stderr, "enter compare_exactf_anyof(%d, \n", anchored); */

    assert((a1->rn->type == EXACTF) || (a1->rn->type == EXACTFU));
    assert((a2->rn->type == ANYOF) || (a2->rn->type == ANYOFD));

    seq = GET_LITERAL(a1);
    init_unfolded(unf, *seq);

    for (i = 0; i < 2; ++i)
    {
        init_bit_flag(&bf, (unsigned char)unf[i]);
        if (!(get_bitmap_byte(a2->rn, bf.offs) & bf.mask))
        {
            return compare_mismatch(anchored, a1, a2);
        }
    }

    return compare_tails(anchored, a1, a2);
}

#ifdef RC_ANYOFM
static int compare_exact_anyofm(int anchored, Arrow *a1, Arrow *a2)
{
    char *seq;
    unsigned char right[ANYOF_BITMAP_SIZE];
    BitFlag bf;

    /* fprintf(stderr, "enter compare_exact_anyofm(%d, \n", anchored); */

    assert(a1->rn->type == EXACT);
    assert(a2->rn->type == ANYOFM);

    seq = GET_LITERAL(a1);
    init_bit_flag(&bf, *seq);

    if (!convert_anyofm_to_bitmap(a2, right))
    {
        return compare_mismatch(anchored, a1, a2);
    }

    if (right[bf.offs] & bf.mask)
    {
        return compare_tails(anchored, a1, a2);
    }

    return compare_mismatch(anchored, a1, a2);
}

static int compare_exactf_anyofm(int anchored, Arrow *a1, Arrow *a2)
{
    char *seq;
    int i;
    char left[2];
    unsigned char right[ANYOF_BITMAP_SIZE];
    BitFlag bf;

    /* fprintf(stderr, "enter compare_exactf_anyofm(%d, \n", anchored); */

    assert((a1->rn->type == EXACTF) || (a1->rn->type == EXACTFU));
    assert(a2->rn->type == ANYOFM);

    seq = GET_LITERAL(a1);
    init_unfolded(left, *seq);

    if (!convert_anyofm_to_bitmap(a2, right))
    {
        return compare_mismatch(anchored, a1, a2);
    }

    for (i = 0; i < 2; ++i)
    {
        init_bit_flag(&bf, left[i]);
        if (!(right[bf.offs] & bf.mask))
        {
            return compare_mismatch(anchored, a1, a2);
        }
    }

    return compare_tails(anchored, a1, a2);
}
#endif

#ifdef RC_NANYOFM
static int compare_exact_nanyofm(int anchored, Arrow *a1, Arrow *a2)
{
    char *seq;
    unsigned char right[ANYOF_BITMAP_SIZE];
    BitFlag bf;

    assert(a1->rn->type == EXACT);
    assert(a2->rn->type == NANYOFM);

    seq = GET_LITERAL(a1);
    init_bit_flag(&bf, *seq);

    if (!convert_anyofm_to_bitmap(a2, right))
    {
        return compare_mismatch(anchored, a1, a2);
    }

    if (right[bf.offs] & bf.mask)
    {
        return compare_mismatch(anchored, a1, a2);
    }

    return compare_tails(anchored, a1, a2);
}

static int compare_exactf_nanyofm(int anchored, Arrow *a1, Arrow *a2)
{
    char *seq;
    int i;
    char left[2];
    unsigned char right[ANYOF_BITMAP_SIZE];
    BitFlag bf;

    assert((a1->rn->type == EXACTF) || (a1->rn->type == EXACTFU));
    assert(a2->rn->type == NANYOFM);

    seq = GET_LITERAL(a1);
    init_unfolded(left, *seq);

    if (!convert_anyofm_to_bitmap(a2, right))
    {
        return compare_mismatch(anchored, a1, a2);
    }

    for (i = 0; i < ANYOF_BITMAP_SIZE; ++i)
    {
        right[i] = ~right[i];
    }

    for (i = 0; i < 2; ++i)
    {
        init_bit_flag(&bf, left[i]);
        if (!(right[bf.offs] & bf.mask))
        {
            return compare_mismatch(anchored, a1, a2);
        }
    }

    return compare_tails(anchored, a1, a2);
}

static int compare_posix_nanyofm(int anchored, Arrow *a1, Arrow *a2)
{
    int i;
    unsigned char *b;
    unsigned char right[ANYOF_BITMAP_SIZE];

    assert((a1->rn->type == POSIXD) || (a1->rn->type == POSIXU) ||
        (a1->rn->type == POSIXA));
    assert(a2->rn->type == NANYOFM);

    if (a1->rn->flags >= SIZEOF_ARRAY(posix_regclass_bitmaps))
    {
        return compare_mismatch(anchored, a1, a2);
    }

    b = posix_regclass_bitmaps[a1->rn->flags];
    if (!b)
    {
        return compare_mismatch(anchored, a1, a2);
    }

    if (!convert_anyofm_to_bitmap(a2, right))
    {
        return compare_mismatch(anchored, a1, a2);
    }

    for (i = 0; i < ANYOF_BITMAP_SIZE; ++i)
    {
        right[i] = ~right[i];
    }

    return compare_bitmaps(anchored, a1, a2, b, right);
}

static int compare_negative_posix_nanyofm(int anchored, Arrow *a1, Arrow *a2)
{
    int i;
    unsigned char *b;
    unsigned char right[ANYOF_BITMAP_SIZE];

    assert((a1->rn->type == NPOSIXD) || (a1->rn->type == NPOSIXU) ||
        (a1->rn->type == NPOSIXA));
    assert(a2->rn->type == NANYOFM);

    if (a1->rn->flags >= SIZEOF_ARRAY(posix_regclass_bitmaps))
    {
        return compare_mismatch(anchored, a1, a2);
    }

    /* positive, because negative bitmaps are compared below */
    b = posix_regclass_bitmaps[a1->rn->flags];
    if (!b)
    {
        return compare_mismatch(anchored, a1, a2);
    }

    if (!convert_anyofm_to_bitmap(a2, right))
    {
        return compare_mismatch(anchored, a1, a2);
    }

    return compare_negative_bitmaps(anchored, a1, a2, b, right);
}
#endif

static int compare_exact_lnbreak(int anchored, Arrow *a1, Arrow *a2)
{
    char *cur;
    char *next;

    assert((a1->rn->type == EXACT) || (a1->rn->type == EXACTF) ||
        (a1->rn->type == EXACTFU));
    assert(a2->rn->type == LNBREAK);

    cur = GET_LITERAL(a1);

    /* first, check 2-character newline */
    if ((*cur == '\r') && ((a1->spent + 1) < a1->rn->flags))
    {
        /* we're ignoring the possibility the \n is in a different
           node, but that probably doesn't happen */
        next = (((char *)(a1->rn + 1)) + a1->spent + 1);
        if (*next == '\n')
        {
            ++(a1->spent);
            return compare_tails(anchored, a1, a2);
        }
    }

    /* otherwise, check vertical space */
    if (!_generic_isCC_A(*cur, _CC_VERTSPACE))
    {
        return compare_mismatch(anchored, a1, a2);
    }

    return compare_tails(anchored, a1, a2);
}

static int compare_exact_byte_class(int anchored, Arrow *a1, Arrow *a2,
    char *lookup)
{
    char *seq;

    assert((a1->rn->type == EXACT) || (a1->rn->type == EXACTF) || (a1->rn->type == EXACTFU));

    seq = GET_LITERAL(a1);

    if (!lookup[(unsigned char)(*seq)])
    {
        return compare_mismatch(anchored, a1, a2);
    }

    return compare_tails(anchored, a1, a2);
}

static int compare_exact_multiline(int anchored, Arrow *a1, Arrow *a2)
{
    assert((a1->rn->type == EXACT) || (a1->rn->type == EXACTF) ||
        (a1->rn->type == EXACTFU));
    assert((a2->rn->type == MBOL) || (a2->rn->type == MEOL));

    return compare_exact_byte_class(anchored, a1, a2,
        ndot.lookup);
}

static int compare_sany_anyof(int anchored, Arrow *a1, Arrow *a2)
{
    /* fprintf(stderr, "enter compare_sany_anyof\n"); */

    assert(a1->rn->type == SANY);
    assert((a2->rn->type == ANYOF) || (a2->rn->type == ANYOFD));

    /* fprintf(stderr, "left flags = 0x%x, right flags = 0x%x\n",
       a1->rn->flags, a2->rn->flags); */

    if (a2->rn->flags & ANYOF_MATCHES_ALL_ABOVE_BITMAP)
    {
        return compare_right_full(anchored, a1, a2);
    }

    return compare_mismatch(anchored, a1, a2);
}

static int compare_anyof_reg_any(int anchored, Arrow *a1, Arrow *a2)
{
    assert((a1->rn->type == ANYOF) || (a1->rn->type == ANYOFD));
    assert(a2->rn->type == REG_ANY);

    return compare_bitmaps(anchored, a1, a2, 0, ndot.nbitmap);
}

#ifdef RC_ANYOFM
static int compare_anyofm_reg_any(int anchored, Arrow *a1, Arrow *a2)
{
    unsigned char left[ANYOF_BITMAP_SIZE];

    assert(a1->rn->type == ANYOFM);
    assert(a2->rn->type == REG_ANY);

    if (!convert_anyofm_to_bitmap(a1, left))
    {
        return compare_mismatch(anchored, a1, a2);
    }

    return compare_bitmaps(anchored, a1, a2, left, ndot.nbitmap);
}
#endif

#ifdef RC_NANYOFM
static int compare_nanyofm_reg_any(int anchored, Arrow *a1, Arrow *a2)
{
    unsigned char left[ANYOF_BITMAP_SIZE];

    assert(a1->rn->type == NANYOFM);
    assert(a2->rn->type == REG_ANY);

    if (!convert_anyofm_to_bitmap(a1, left))
    {
        return compare_mismatch(anchored, a1, a2);
    }

    return compare_negative_bitmaps(anchored, a1, a2, left, ndot.bitmap);
}
#endif

static int compare_anyof_lnbreak(int anchored, Arrow *a1, Arrow *a2)
{
    assert((a1->rn->type == ANYOF) || (a1->rn->type == ANYOFD));
    assert(a2->rn->type == LNBREAK);

    return compare_bitmaps(anchored, a1, a2, 0, vertical_whitespace.bitmap);
}

static int compare_exact_reg_any(int anchored, Arrow *a1, Arrow *a2)
{
    assert((a1->rn->type == EXACT) || (a1->rn->type == EXACTF) || (a1->rn->type == EXACTFU));
    assert(a2->rn->type == REG_ANY);

    return compare_exact_byte_class(anchored, a1, a2, ndot.nlookup);
}

static int compare_anyof_posix(int anchored, Arrow *a1, Arrow *a2)
{
    unsigned char *b;

    /* fprintf(stderr, "enter compare_anyof_posix\n"); */

    assert((a1->rn->type == ANYOF) || (a1->rn->type == ANYOFD));
    assert((a2->rn->type == POSIXD) || (a2->rn->type == POSIXU) || (a2->rn->type == POSIXA));

    if (a2->rn->flags >= SIZEOF_ARRAY(posix_regclass_bitmaps))
    {
        /* fprintf(stderr, "flags = %d\n", a2->rn->flags); */
        return compare_mismatch(anchored, a1, a2);
    }

    b = posix_regclass_bitmaps[a2->rn->flags];
    if (!b)
    {
        /* fprintf(stderr, "no bitmap for flags = %d\n", a2->rn->flags); */
        return compare_mismatch(anchored, a1, a2);
    }

    return compare_bitmaps(anchored, a1, a2, 0, b);
}

#ifdef RC_ANYOFM
static int compare_anyofm_posix(int anchored, Arrow *a1, Arrow *a2)
{
    unsigned char *b;
    unsigned char left[ANYOF_BITMAP_SIZE];

    /* fprintf(stderr, "enter compare_anyofm_posix\n"); */

    assert(a1->rn->type == ANYOFM);
    assert((a2->rn->type == POSIXD) || (a2->rn->type == POSIXU) || (a2->rn->type == POSIXA));

    if (!convert_anyofm_to_bitmap(a1, left))
    {
        return compare_mismatch(anchored, a1, a2);
    }

    b = posix_regclass_bitmaps[a2->rn->flags];
    if (!b)
    {
        return compare_mismatch(anchored, a1, a2);
    }

    return compare_bitmaps(anchored, a1, a2, left, b);
}
#endif

#ifdef RC_NANYOFM
static int compare_nanyofm_posix(int anchored, Arrow *a1, Arrow *a2)
{
    unsigned char *b;
    unsigned char left[ANYOF_BITMAP_SIZE];

    assert(a1->rn->type == NANYOFM);
    assert((a2->rn->type == POSIXD) || (a2->rn->type == POSIXU) || (a2->rn->type == POSIXA));

    if (!convert_anyofm_to_bitmap(a1, left))
    {
        return compare_mismatch(anchored, a1, a2);
    }

    b = posix_regclass_nbitmaps[a2->rn->flags];
    if (!b)
    {
        return compare_mismatch(anchored, a1, a2);
    }

    return compare_negative_bitmaps(anchored, a1, a2, left, b);
}
#endif

static int compare_anyof_posixa(int anchored, Arrow *a1, Arrow *a2)
{
    unsigned char *b;

    /* fprintf(stderr, "enter compare_anyof_posixa\n"); */

    assert((a1->rn->type == ANYOF) || (a1->rn->type == ANYOFD));
    assert(a2->rn->type == POSIXA);

    if (ANYOF_FLAGS(a1->rn) & ANYOF_SHARED_d_UPPER_LATIN1_UTF8_STRING_MATCHES_non_d_RUNTIME_USER_PROP)
    {
        return compare_mismatch(anchored, a1, a2);
    }

    if (a2->rn->flags >= SIZEOF_ARRAY(posix_regclass_bitmaps))
    {
        /* fprintf(stderr, "flags = %d\n", a2->rn->flags); */
        return compare_mismatch(anchored, a1, a2);
    }

    b = posix_regclass_bitmaps[a2->rn->flags];
    if (!b)
    {
        /* fprintf(stderr, "no bitmap for flags = %d\n", a2->rn->flags); */
        return compare_mismatch(anchored, a1, a2);
    }

    return compare_bitmaps(anchored, a1, a2, 0, b);
}

static int compare_anyof_negative_posix(int anchored, Arrow *a1, Arrow *a2)
{
    unsigned char *b;

    /* fprintf(stderr, "enter compare_anyof_negative_posix\n"); */

    assert((a1->rn->type == ANYOF) || (a1->rn->type == ANYOFD));
    assert((a2->rn->type == NPOSIXD) || (a2->rn->type == NPOSIXU) ||
        (a2->rn->type == NPOSIXA));

    if (a2->rn->flags >= SIZEOF_ARRAY(posix_regclass_nbitmaps))
    {
        /* fprintf(stderr, "flags = %d\n", a2->rn->flags); */
        return compare_mismatch(anchored, a1, a2);
    }

    b = posix_regclass_nbitmaps[a2->rn->flags];
    if (!b)
    {
        /* fprintf(stderr, "no negative bitmap for flags = %d\n", a2->rn->flags); */
        return compare_mismatch(anchored, a1, a2);
    }

    return compare_bitmaps(anchored, a1, a2, 0, b);
}

#ifdef RC_ANYOFM
static int compare_anyofm_negative_posix(int anchored, Arrow *a1, Arrow *a2)
{
    unsigned char *posix_bitmap;
    unsigned char anyof_bitmap[ANYOF_BITMAP_SIZE];

    /* fprintf(stderr, "enter compare_anyofm_negative_posix\n"); */

    assert(a1->rn->type == ANYOFM);
    assert((a2->rn->type == NPOSIXD) || (a2->rn->type == NPOSIXU) ||
        (a2->rn->type == NPOSIXA));

    if (!convert_anyofm_to_bitmap(a1, anyof_bitmap))
    {
        return compare_mismatch(anchored, a1, a2);
    }

    if (a2->rn->flags >= SIZEOF_ARRAY(posix_regclass_nbitmaps))
    {
        /* fprintf(stderr, "flags = %d\n", a2->rn->flags); */
        return compare_mismatch(anchored, a1, a2);
    }

    posix_bitmap = posix_regclass_nbitmaps[a2->rn->flags];
    if (!posix_bitmap)
    {
        /* fprintf(stderr, "no negative bitmap for flags = %d\n", a2->rn->flags); */
        return compare_mismatch(anchored, a1, a2);
    }

    return compare_bitmaps(anchored, a1, a2, anyof_bitmap, posix_bitmap);
}
#endif

#ifdef RC_NANYOFM
static int compare_nanyofm_negative_posix(int anchored, Arrow *a1, Arrow *a2)
{
    unsigned char *posix_bitmap;
    unsigned char anyof_bitmap[ANYOF_BITMAP_SIZE];

    assert(a1->rn->type == NANYOFM);
    assert((a2->rn->type == NPOSIXD) || (a2->rn->type == NPOSIXU) ||
        (a2->rn->type == NPOSIXA));

    if (!convert_anyofm_to_bitmap(a1, anyof_bitmap))
    {
        return compare_mismatch(anchored, a1, a2);
    }

    if (a2->rn->flags >= SIZEOF_ARRAY(posix_regclass_bitmaps))
    {
        return compare_mismatch(anchored, a1, a2);
    }

    posix_bitmap = posix_regclass_bitmaps[a2->rn->flags];
    if (!posix_bitmap)
    {
        return compare_mismatch(anchored, a1, a2);
    }

    return compare_negative_bitmaps(anchored, a1, a2, anyof_bitmap, posix_bitmap);
}
#endif

static int compare_posix_reg_any(int anchored, Arrow *a1, Arrow *a2)
{
    assert((a1->rn->type == POSIXD) || (a1->rn->type == POSIXU) ||
        (a1->rn->type == POSIXA));
    assert(a2->rn->type == REG_ANY);

    U8 flags = a1->rn->flags;
    if (flags >= SIZEOF_ARRAY(newline_posix_regclasses))
    {
        /* fprintf(stderr, "unknown POSIX character class %d\n", flags); */
        rc_error = "unknown POSIX character class";
        return -1;
    }

    if (newline_posix_regclasses[flags])
    {
        return compare_mismatch(anchored, a1, a2);
    }

    return compare_tails(anchored, a1, a2);
}

static int compare_negative_posix_reg_any(int anchored, Arrow *a1, Arrow *a2)
{
    assert((a1->rn->type == NPOSIXD) || (a1->rn->type == NPOSIXU) ||
        (a1->rn->type == NPOSIXA));
    assert(a2->rn->type == REG_ANY);

    U8 flags = a1->rn->flags;
    if (flags >= SIZEOF_ARRAY(newline_posix_regclasses))
    {
        rc_error = "unknown negative POSIX character class";
        return -1;
    }

    if (!newline_posix_regclasses[flags])
    {
        return compare_mismatch(anchored, a1, a2);
    }

    return compare_tails(anchored, a1, a2);
}

static int compare_posix_lnbreak(int anchored, Arrow *a1, Arrow *a2)
{
    assert((a1->rn->type == POSIXD) || (a1->rn->type == POSIXU) ||
        (a1->rn->type == POSIXA));
    assert(a2->rn->type == LNBREAK);

    if (a1->rn->flags != _CC_VERTSPACE)
    {
        return compare_mismatch(anchored, a1, a2);
    }

    return compare_tails(anchored, a1, a2);
}

static int compare_anyof_exact(int anchored, Arrow *a1, Arrow *a2)
{
    BitFlag bf;
    char *seq;
    int i;
    unsigned char req;

    assert((a1->rn->type == ANYOF) || (a1->rn->type == ANYOFD));
    assert(a2->rn->type == EXACT);

    if (a1->rn->flags & ANYOF_MATCHES_ALL_ABOVE_BITMAP)
    {
        return compare_mismatch(anchored, a1, a2);
    }

    seq = GET_LITERAL(a2);
    init_bit_flag(&bf, *((unsigned char *)seq));

    for (i = 0; i < ANYOF_BITMAP_SIZE; ++i)
    {
        req = (i != bf.offs) ? 0 : bf.mask;
        if (get_bitmap_byte(a1->rn, i) != req)
        {
            return compare_mismatch(anchored, a1, a2);
        }
    }

    return compare_tails(anchored, a1, a2);
}

#ifdef RC_ANYOFM
static int compare_anyofm_exact(int anchored, Arrow *a1, Arrow *a2)
{
    unsigned char left[ANYOF_BITMAP_SIZE];
    BitFlag bf;
    char *seq;
    int i;
    unsigned char req;

    assert(a1->rn->type == ANYOFM);
    assert(a2->rn->type == EXACT);

    if (!convert_anyofm_to_bitmap(a1, left))
    {
        return compare_mismatch(anchored, a1, a2);
    }

    seq = GET_LITERAL(a2);
    init_bit_flag(&bf, *((unsigned char *)seq));

    for (i = 0; i < ANYOF_BITMAP_SIZE; ++i)
    {
        req = (i != bf.offs) ? 0 : bf.mask;
        if (left[i] != req)
        {
            return compare_mismatch(anchored, a1, a2);
        }
    }

    return compare_tails(anchored, a1, a2);
}
#endif

static int compare_anyof_exactf(int anchored, Arrow *a1, Arrow *a2)
{
    char *seq;
    char unf[2];
    BitFlag bf[2];
    unsigned char right[ANYOF_BITMAP_SIZE];
    int i;

    assert((a1->rn->type == ANYOF) || (a1->rn->type == ANYOFD));
    assert((a2->rn->type == EXACTF) || (a2->rn->type == EXACTFU));

    if (a1->rn->flags & ANYOF_MATCHES_ALL_ABOVE_BITMAP)
    {
        return compare_mismatch(anchored, a1, a2);
    }

    seq = GET_LITERAL(a2);
    init_unfolded(unf, *seq);

    for (i = 0; i < 2; ++i)
    {
        init_bit_flag(bf + i, (unsigned char)(unf[i]));
    }

    if (bf[0].offs == bf[1].offs)
    {
        bf[0].mask = bf[1].mask = bf[0].mask | bf[1].mask;
    }

    memset(right, 0, ANYOF_BITMAP_SIZE);
    for (i = 0; i < 2; ++i)
    {
        right[bf[i].offs] = bf[i].mask;
    }

    return compare_bitmaps(anchored, a1, a2, 0, right);
}

#ifdef RC_ANYOFM
static int compare_anyofm_exactf(int anchored, Arrow *a1, Arrow *a2)
{
    char *seq;
    int i;
    BitFlag bf;
    unsigned char left[ANYOF_BITMAP_SIZE];
    unsigned char right[ANYOF_BITMAP_SIZE];
    char unf[2];

    /* fprintf(stderr, "enter compare_anyofm_exactf(%d, \n", anchored); */

    assert(a1->rn->type == ANYOFM);
    assert((a2->rn->type == EXACTF) || (a2->rn->type == EXACTFU));

    if (!convert_anyofm_to_bitmap(a1, left))
    {
        return compare_mismatch(anchored, a1, a2);
    }

    seq = GET_LITERAL(a2);
    init_unfolded(unf, *seq);

    memset(right, 0, ANYOF_BITMAP_SIZE);
    for (i = 0; i < 2; ++i)
    {
        init_bit_flag(&bf, unf[i]);
        right[bf.offs] = bf.mask;
    }

    return compare_bitmaps(anchored, a1, a2, left, right);
}
#endif

static int compare_exact_exact(int anchored, Arrow *a1, Arrow *a2)
{
    char *q1, *q2;

#ifndef RC_EXACT_ONLY8
    assert(a1->rn->type == EXACT);
    assert(a2->rn->type == EXACT);
#endif

    q1 = GET_LITERAL(a1);
    q2 = GET_LITERAL(a2);

    /* fprintf(stderr, "enter compare_exact_exact(%d, '%c', '%c')\n", anchored,
        *q1, *q2); */

    if (*q1 != *q2)
    {
        return compare_mismatch(anchored, a1, a2);
    }

    return compare_tails(anchored, a1, a2);
}

static int compare_exact_exactf(int anchored, Arrow *a1, Arrow *a2)
{
    char *q1, *q2;
    char unf[2];

    assert(a1->rn->type == EXACT);
    assert((a2->rn->type == EXACTF) || (a2->rn->type == EXACTFU));

    q1 = GET_LITERAL(a1);
    q2 = GET_LITERAL(a2);
    init_unfolded(unf, *q2);

    if ((*q1 != unf[0]) && (*q1 != unf[1]))
    {
        return compare_mismatch(anchored, a1, a2);
    }

    return compare_tails(anchored, a1, a2);
}

static int compare_exactf_exact(int anchored, Arrow *a1, Arrow *a2)
{
    char *q1, *q2;
    char unf[2];

    assert((a1->rn->type == EXACTF) || (a1->rn->type == EXACTFU));
    assert(a2->rn->type == EXACT);

    q1 = GET_LITERAL(a1);
    init_unfolded(unf, *q1);
    q2 = GET_LITERAL(a2);

    if ((unf[0] != *q2) || (unf[1] != *q2))
    {
        return compare_mismatch(anchored, a1, a2);
    }

    return compare_tails(anchored, a1, a2);
}

static int compare_exactf_exactf(int anchored, Arrow *a1, Arrow *a2)
{
    char *q1, *q2;
    char l1, l2;

    assert((a1->rn->type == EXACTF) || (a1->rn->type == EXACTFU));
    assert((a2->rn->type == EXACTF) || (a2->rn->type == EXACTFU));

    q1 = GET_LITERAL(a1);
    q2 = GET_LITERAL(a2);

    l1 = TOLOWER(*q1);
    l2 = TOLOWER(*q2);

    if (l1 != l2)
    {
        return compare_mismatch(anchored, a1, a2);
    }

    return compare_tails(anchored, a1, a2);
}

static int compare_left_branch(int anchored, Arrow *a1, Arrow *a2)
{
    int rv, tsz;
    regnode *p1;
    Arrow left, right;

    /* fprintf(stderr, "enter compare_left_branch\n"); */

    assert(a1->rn->type == BRANCH);

    /* origins stay the same throughout the cycle */
    left.origin = a1->origin;
    right.origin = a2->origin;
    p1 = a1->rn;
    while (p1->type == BRANCH)
    {
        if (p1->next_off == 0)
        {
            rc_error = "Branch with zero offset";
            return -1;
        }

        left.rn = p1 + 1;
        left.spent = 0;

        right.rn = a2->rn;
        right.spent = a2->spent;

        rv = compare(anchored, &left, &right);
        /* fprintf(stderr, "rv = %d\n", rv); */

        if (rv < 0)
        {
            return rv;
        }

        if (!rv)
        {
            /* fprintf(stderr, "compare_left_branch doesn't match\n"); */
            return compare_mismatch(anchored, a1, a2);
        }

        p1 += p1->next_off;
    }

    a1->rn = p1;
    a1->spent = 0;

    tsz = get_size(a2->rn);
    if (tsz <= 0)
    {
        return -1;
    }

    a2->rn += tsz - 1;
    a2->spent = 0;

    return 1;
}

static int compare_set(int anchored, Arrow *a1, Arrow *a2, unsigned char *b1)
{
    regnode *alt, *t1;
    Arrow left, right;
    int i, j, power, rv, sz, offs;
    unsigned char loc;

    offs = GET_OFFSET(a1->rn);
    if (offs <= 0)
    {
        return -1;
    }

    t1 = a1->rn + offs;
    sz = get_size(t1);
    if (sz < 0)
    {
        return sz;
    }

    alt = (regnode *)malloc(sizeof(regnode) * (2 + sz));
    if (!alt)
    {
        rc_error = "Couldn't allocate memory for alternative copy";
        return -1;
    }

    alt[0].flags = 1;
    alt[0].type = EXACT;
    alt[0].next_off = 2;
    memcpy(alt + 2, t1, sizeof(regnode) * sz);

    left.origin = a1->origin;
    right.origin = a2->origin;
    right.rn = 0;

    for (i = 0; i < ANYOF_BITMAP_SIZE; ++i)
    {
        loc = b1 ? b1[i] : get_bitmap_byte(a1->rn, i);
        if ((i >= 16) && loc)
        {
            free(alt);
            return compare_mismatch(anchored, a1, a2);
        }

        power = 1;
        for (j = 0; j < 8; ++j)
        {
            if (loc & power)
            {
                alt[1].flags = 8 * i + j;
                left.rn = alt;
                left.spent = 0;

                right.rn = a2->rn;
                right.spent = a2->spent;

                rv = compare_right_branch(anchored, &left, &right);
                if (rv < 0)
                {
                    free(alt);
                    return rv;
                }

                if (!rv)
                {
                    free(alt);
                    return compare_mismatch(anchored, a1, a2);
                }
            }

            power *= 2;
        }
    }

    free(alt);

    if (!right.rn)
    {
        rc_error = "Empty mask not supported";
        return -1;
    }

    a1->rn = t1 + sz - 1;
    assert(a1->rn->type == END);
    a1->spent = 0;

    a2->rn = right.rn;
    a2->spent = right.spent;

    return 1;
}

static int compare_anyof_branch(int anchored, Arrow *a1, Arrow *a2)
{
    assert((a1->rn->type == ANYOF) || (a1->rn->type == ANYOFD));
    assert(a2->rn->type == BRANCH);

    return compare_set(anchored, a1, a2, 0);
}

#ifdef RC_ANYOFM
static int compare_anyofm_branch(int anchored, Arrow *a1, Arrow *a2)
{
    unsigned char left[ANYOF_BITMAP_SIZE];

    assert(a1->rn->type == ANYOFM);
    assert(a2->rn->type == BRANCH);

    if (!convert_anyofm_to_bitmap(a1, left))
    {
        return compare_mismatch(anchored, a1, a2);
    }

    return compare_set(anchored, a1, a2, left);
}
#endif

static int compare_right_branch(int anchored, Arrow *a1, Arrow *a2)
{
    int rv;
    regnode *p2;
    Arrow left, right;

    /* fprintf(stderr, "enter compare_right_branch\n"); */

    assert(a2->rn->type == BRANCH);

    /* origins stay the same throughout the cycle */
    left.origin = a1->origin;
    right.origin = a2->origin;
    p2 = a2->rn;
    rv = 0;
    while ((p2->type == BRANCH) && !rv)
    {
      /* fprintf(stderr, "p2->type = %d\n", p2->type); */

        left.rn = a1->rn;
        left.spent = a1->spent;

        if (p2->next_off == 0)
        {
            rc_error = "Branch with offset zero";
            return -1;
        }

        right.rn = p2 + 1;
        right.spent = 0;

        rv = compare(anchored, &left, &right);
        /* fprintf(stderr, "got %d\n", rv); */

        p2 += p2->next_off;
    }

    if (rv < 0)
    {
        return rv;
    }

    if (!rv)
    {
        return compare_mismatch(anchored, a1, a2);
    }

    a1->rn = left.rn;
    a1->spent = left.spent;

    a2->rn = right.rn;
    a2->spent = right.spent;

    return 1;
}

static int compare_right_star(int anchored, Arrow *a1, Arrow *a2)
{
    regnode *p2;
    Arrow left, right;
    int sz, rv, offs;

    /* fprintf(stderr, "enter compare_right_star\n"); */

    p2 = a2->rn;
    assert(p2->type == STAR);

    sz = get_size(p2);
    if (sz < 0)
    {
        return sz;
    }

    left.origin = a1->origin;
    left.rn = a1->rn;
    left.spent = a1->spent;

    offs = GET_OFFSET(p2);
    if (offs <= 0)
    {
        return -1;
    }

    right.origin = a2->origin;
    right.rn = p2 + offs;
    right.spent = 0;

    rv = compare(anchored, &left, &right);
    if (rv < 0)
    {
        return rv;
    }

    if (rv == 0)
    {
        right.rn = p2 + 1;
        right.spent = 0;

        rv = compare(anchored, a1, &right);
        if (rv < 0)
        {
            return rv;
        }

        if (!rv)
        {
            return compare_mismatch(anchored, a1, a2);
        }

        right.rn = p2;
        right.spent = 0;

        if (!anchored)
        {
            rv = compare_right_star(1, a1, &right);
        }
    }

    if (rv <= 0)
    {
        return rv;
    }

    a2->rn += sz - 1;
    assert(a2->rn->type == END);
    a2->spent = 0;

    return rv;
}

static int compare_plus_plus(int anchored, Arrow *a1, Arrow *a2)
{
    regnode *p1, *p2;
    Arrow left, right;
    int rv, offs;

    p1 = a1->rn;
    assert(p1->type == PLUS);
    p2 = a2->rn;
    assert(p2->type == PLUS);

    left.origin = a1->origin;
    left.rn = p1 + 1;
    left.spent = 0;

    right.origin = a2->origin;
    right.rn = p2 + 1;
    right.spent = 0;

    rv = compare(1, &left, &right);
    if (rv)
    {
        return rv;
    }

    offs = GET_OFFSET(p1);
    /* fprintf(stderr, "offs = %d\n", offs); */
    if (offs <= 0)
    {
        return -1;
    }

    left.origin = a1->origin;
    left.rn = p1 + offs;
    left.spent = 0;
    return compare(1, &left, a2);
}

static int compare_repeat_star(int anchored, Arrow *a1, Arrow *a2)
{
    regnode *p1, *p2;
    Arrow left, right;
    int rv, offs;

    p1 = a1->rn;
    assert((p1->type == PLUS) || (p1->type == STAR));
    p2 = a2->rn;
    assert(p2->type == STAR);
    /* fprintf(stderr, "enter compare_repeat_star(%d, %d, %d)\n",
       anchored, p1->type, p2->type); */

    left.origin = a1->origin;
    left.rn = p1 + 1;
    left.spent = 0;

    right.origin = a2->origin;
    right.rn = p2 + 1;
    right.spent = 0;

    rv = compare(1, &left, &right);
    /* fprintf(stderr, "inclusive compare returned %d\n", rv); */
    if (rv)
    {
        return rv;
    }

    offs = GET_OFFSET(p2);
    /* fprintf(stderr, "offs = %d\n", offs); */
    if (offs <= 0)
    {
        return -1;
    }

    right.origin = a2->origin;
    right.rn = p2 + offs;
    right.spent = 0;
    return compare(1, &left, &right);
}

static int compare_right_curly_from_zero(int anchored, Arrow *a1, Arrow *a2)
{
    regnode *p2, *alt;
    CurlyCount *cnt;
#ifndef RC_UNSIGNED_COUNT
    CurlyCount n;
#endif
    Arrow left, right;
    int sz, rv, offs;

    p2 = a2->rn;

#ifndef RC_UNSIGNED_COUNT
    n = ((CurlyCount *)(p2 + 1))[1];
    if (n <= 0)
    {
        rc_error = "Curly must have positive maximum";
        return -1;
    }
#endif

    sz = get_size(p2);
    if (sz < 0)
    {
        return sz;
    }

    left.origin = a1->origin;
    left.rn = a1->rn;
    left.spent = a1->spent;

    offs = GET_OFFSET(p2);
    if (offs <= 0)
    {
        return -1;
    }

    right.origin = a2->origin;
    right.rn = p2 + offs;
    right.spent = 0;

    rv = compare(anchored, &left, &right);
    if (rv < 0)
    {
        return rv;
    }

    if (rv == 0)
    {
        alt = alloc_alt(p2, sz);
        if (!alt)
        {
            return -1;
        }

        right.rn = alt + 2;
        right.spent = 0;

        rv = compare(anchored, a1, &right);
        if (rv < 0)
        {
            free(alt);
            return rv;
        }

        if (!rv)
        {
            free(alt);
            return compare_mismatch(anchored, a1, a2);
        }

        cnt = (CurlyCount *)(alt + 1);
        if (cnt[1] < INFINITE_COUNT)
        {
            --cnt[1];
        }

        if ((cnt[1] > 0) && !anchored)
        {
            right.rn = alt;
            right.spent = 0;

            rv = compare_right_curly_from_zero(1, a1, &right);
        }
        else
        {
            rv = 1;
        }

        free(alt);
    }

    if (rv <= 0)
    {
        return rv;
    }

    a2->rn += sz - 1;
    assert(a2->rn->type == END);
    a2->spent = 0;

    return rv;
}

static int compare_left_plus(int anchored, Arrow *a1, Arrow *a2)
{
    regnode *p1, *alt, *q;
    Arrow left, right;
    int sz, rv, offs, end_offs;
    unsigned char orig_type;

    p1 = a1->rn;
    assert(p1->type == PLUS);

    sz = get_size(p1);
    if (sz < 0)
    {
        return -1;
    }

    if (sz < 2)
    {
        rc_error = "Left plus offset too small";
        return -1;
    }

    alt = alloc_alt(p1 + 1, sz - 1);
    if (!alt)
    {
        return -1;
    }

    if (anchored)
    {
        offs = get_jump_offset(p1);
        if (offs <= 0)
        {
            return -1;
        }

        q = p1 + offs;
        if (q->type != END)
        {
            /* repeat with a tail after it can be more strict than a
               fixed-length match only if the tail is at least as
               strict as the repeated regexp */
            left.origin = a1->origin;
            left.rn = q;
            left.spent = 0;

            end_offs = offs - 1;
            orig_type = alt[end_offs].type;
            alt[end_offs].type = END;

            right.origin = a2->origin;
            right.rn = alt;
            right.spent = 0;

            /* fprintf(stderr, "comparing %d to %d\n", left.rn->type,
               right.rn->type); */
            rv = compare(1, &left, &right);
            /* fprintf(stderr, "compare returned %d\n", rv); */
            if (rv <= 0)
            {
                free(alt);
                return rv;
            }

            alt[end_offs].type = orig_type;
        }
    }

    left.origin = a1->origin;
    left.rn = alt;
    left.spent = 0;
    rv = compare(anchored, &left, a2);
    free(alt);
    return rv;
}

static int compare_right_plus(int anchored, Arrow *a1, Arrow *a2)
{
    regnode *p2;
    Arrow right;
    int sz, rv;

    p2 = a2->rn;
    assert(p2->type == PLUS);

    /* fprintf(stderr, "enter compare_right_plus\n"); */

    sz = get_size(p2);
    if (sz < 0)
    {
        return -1;
    }

    if (sz < 2)
    {
        rc_error = "Plus offset too small";
        return -1;
    }

    /* fprintf(stderr, "sz = %d\n", sz); */

    right.origin = a2->origin;
    right.rn = p2 + 1;
    right.spent = 0;

    rv = compare(anchored, a1, &right);

    if (rv < 0)
    {
        return rv;
    }

    if (!rv)
    {
        return compare_mismatch(anchored, a1, a2);
    }

    a2->rn += sz - 1;
    assert(a2->rn->type == END);
    a2->spent = 0;

    return rv;
}

static int compare_next(int anchored, Arrow *a1, Arrow *a2)
{
    if (bump_regular(a2) <= 0)
    {
        return -1;
    }

    return compare(anchored, a1, a2);
}

static int compare_curly_plus(int anchored, Arrow *a1, Arrow *a2)
{
    regnode *p1, *p2;
    Arrow left, right;
    CurlyCount *cnt;

    p1 = a1->rn;
    assert((p1->type == CURLY) || (p1->type == CURLYM) ||
           (p1->type == CURLYX));
    p2 = a2->rn;
    assert(p2->type == PLUS);

    cnt = (CurlyCount *)(p1 + 1);
#ifndef RC_UNSIGNED_COUNT
    if (cnt[0] < 0)
    {
        rc_error = "Left curly has negative minimum";
        return -1;
    }
#endif

    if (!cnt[0])
    {
        return compare_mismatch(anchored, a1, a2);
    }

    left.origin = a1->origin;
    left.rn = p1 + 2;
    left.spent = 0;

    right.origin = a2->origin;
    right.rn = p2 + 1;
    right.spent = 0;

    if (cnt[0] > 1)
    {
        anchored = 1;
    }

    return compare(anchored, &left, &right);
}

static int compare_curly_star(int anchored, Arrow *a1, Arrow *a2)
{
    regnode *p1, *p2;
    Arrow left, right;
    int rv;

    p1 = a1->rn;
    assert((p1->type == CURLY) || (p1->type == CURLYM) ||
           (p1->type == CURLYX));
    p2 = a2->rn;
    assert(p2->type == STAR);

    left.origin = a1->origin;
    left.rn = p1 + 2;
    left.spent = 0;

    right.origin = a2->origin;
    right.rn = p2 + 1;
    right.spent = 0;

    rv = compare(1, &left, &right);
    if (!rv)
    {
        rv = compare_next(anchored, a1, a2);
    }

    return rv;
}

static int compare_plus_curly(int anchored, Arrow *a1, Arrow *a2)
{
    regnode *p1, *p2, *e2;
    Arrow left, right;
    CurlyCount *cnt;
    int rv, offs;

    p1 = a1->rn;
    assert(p1->type == PLUS);
    p2 = a2->rn;
    assert((p2->type == CURLY) || (p2->type == CURLYM) ||
           (p2->type == CURLYX));

    cnt = (CurlyCount *)(p2 + 1);
#ifndef RC_UNSIGNED_COUNT
    if (cnt[0] < 0)
    {
        rc_error = "Negative minimum for curly";
        return -1;
    }
#endif

    if (cnt[0] > 1) /* FIXME: fails '(?:aa)+' => 'a{2,}' */
    {
        return compare_mismatch(anchored, a1, a2);
    }

    left.origin = a1->origin;
    left.rn = p1 + 1;
    left.spent = 0;

    if (cnt[1] != INFINITE_COUNT)
    {
        offs = get_jump_offset(p2);
        if (offs <= 0)
        {
            return -1;
        }

        e2 = p2 + offs;
        if (e2->type != END)
        {
            return compare_mismatch(anchored, a1, a2);
        }
    }

    right.origin = a2->origin;
    right.rn = p2 + 2;
    right.spent = 0;

    rv = compare(anchored, &left, &right);
    return (!rv && !cnt[0]) ? compare_next(anchored, a1, a2) : rv;
}

static int compare_suspend_curly(int anchored, Arrow *a1, Arrow *a2)
{
    assert(a1->rn->type == SUSPEND);
    assert(!a1->spent);

    a1->rn += 2;

    return compare(1, a1, a2);
}

static void dec_curly_counts(CurlyCount *altcnt)
{
    --altcnt[0];
    if (altcnt[1] < INFINITE_COUNT)
    {
        --altcnt[1];
    }
}

static int compare_left_curly(int anchored, Arrow *a1, Arrow *a2)
{
    regnode *p1, *alt, *q;
    Arrow left, right;
    int sz, rv, offs, end_offs;
    CurlyCount *cnt;

    /* fprintf(stderr, "enter compare_left_curly(%d, %d, %d)\n", anchored,
       a1->rn->type, a2->rn->type); */

    p1 = a1->rn;
    assert((p1->type == CURLY) || (p1->type == CURLYM) ||
           (p1->type == CURLYX));

    cnt = (CurlyCount *)(p1 + 1);
    if (!cnt[0])
    {
        /* fprintf(stderr, "curly from 0\n"); */
        return compare_mismatch(anchored, a1, a2);
    }

    sz = get_size(p1);
    if (sz < 0)
    {
        return -1;
    }

    if (sz < 3)
    {
        rc_error = "Left curly offset too small";
        return -1;
    }

    if (cnt[0] > 1)
    {
        /* fprintf(stderr, "curly with non-trivial repeat count\n"); */

        offs = GET_OFFSET(p1);
        if (offs < 0)
        {
            return -1;
        }

        if (offs < 3)
        {
            rc_error = "Left curly offset is too small";
            return -1;
        }

        alt = (regnode *)malloc(sizeof(regnode) * (offs - 2 + sz));
        if (!alt)
        {
            rc_error = "Could not allocate memory for unrolled curly";
            return -1;
        }

        memcpy(alt, p1 + 2, (offs - 2) * sizeof(regnode));
        memcpy(alt + offs - 2, p1, sz * sizeof(regnode));

        dec_curly_counts((CurlyCount *)(alt + offs - 1));

        left.origin = a1->origin;
        left.rn = alt;
        left.spent = 0;
        rv = compare(1, &left, a2);
        free(alt);
        return rv;
    }

    if (anchored && !((cnt[0] == 1) && (cnt[1] == 1)))
    {
        /* fprintf(stderr, "anchored curly with variable length\n"); */

        alt = alloc_alt(p1 + 2, sz - 2);
        if (!alt)
        {
            return -1;
        }

        offs = get_jump_offset(p1);
        if (offs <= 0)
        {
            return -1;
        }

        q = p1 + offs;
        if (q->type != END)
        {
            /* repeat with a tail after it can be more strict than a
               fixed-length match only if the tail is at least as
               strict as the repeated regexp */
            left.origin = a1->origin;
            left.rn = q;
            left.spent = 0;

            end_offs = offs - 1;
            alt[end_offs].type = END;

            right.origin = a2->origin;
            right.rn = alt;
            right.spent = 0;

            /* fprintf(stderr, "comparing %d to %d\n", left.rn->type,
               right.rn->type); */
            rv = compare(1, &left, &right);
            free(alt);
            /* fprintf(stderr, "compare returned %d\n", rv); */
            if (rv <= 0)
            {
                return rv;
            }
        }
    }

    left.origin = a1->origin;
    left.rn = p1 + 2;
    left.spent = 0;
    return compare(anchored, &left, a2);
}

static int compare_right_curly(int anchored, Arrow *a1, Arrow *a2)
{
    regnode *p2, *alt;
    Arrow right;
    CurlyCount *cnt, *altcnt;
    int sz, rv, offs, nanch;

    /* fprintf(stderr, "enter compare_right_curly(%d...: a1->spent = %d, a2->spent = %d\n", anchored, a1->spent, a2->spent); */

    p2 = a2->rn;

    cnt = (CurlyCount *)(p2 + 1);
#ifndef RC_UNSIGNED_COUNT
    if (cnt[0] < 0)
    {
        rc_error = "Curly has negative minimum";
        return -1;
    }
#endif

    /* fprintf(stderr, "compare_right_curly: minimal repeat count = %d\n", cnt[0]); */

    nanch = anchored;

    if (cnt[0] > 0)
    {
        /* the repeated expression is mandatory: */
        sz = get_size(p2);
        if (sz < 0)
        {
            return sz;
        }

        if (sz < 3)
        {
            rc_error = "Right curly offset too small";
            return -1;
        }

        right.origin = a2->origin;
        right.rn = p2 + 2;
        right.spent = 0;

        rv = compare(anchored, a1, &right);
        /* fprintf(stderr, "compare_right_curly: compare returned %d\n", rv); */
        if (rv < 0)
        {
            return rv;
        }

        if (!rv)
        {
            /* ...or (if we aren't anchored yet) just do the left tail... */
            rv = compare_mismatch(anchored, a1, a2);
            if (rv)
            {
                return rv;
            }

            /* ...or (last try) unroll the repeat (works for e.g.
               'abbc' vs. 'ab{2}c' */
            if (cnt[0] > 1)
            {
                offs = GET_OFFSET(p2);
                if (offs < 0)
                {
                    return -1;
                }

                if (offs < 3)
                {
                    rc_error = "Left curly offset is too small";
                    return -1;
                }

                alt = (regnode *)malloc(sizeof(regnode) * (offs - 2 + sz));
                if (!alt)
                {
                    rc_error = "Couldn't allocate memory for unrolled curly";
                    return -1;
                }

                memcpy(alt, p2 + 2, (offs - 2) * sizeof(regnode));
                memcpy(alt + offs - 2, p2, sz * sizeof(regnode));

                dec_curly_counts((CurlyCount *)(alt + offs - 1));

                right.origin = a2->origin;
                right.rn = alt;
                right.spent = 0;

                rv = compare(anchored, a1, &right);
                free(alt);
                return rv;
            }

            return 0;
        }

        if (cnt[0] == 1)
        {
            return 1;
        }

        if (a1->rn->type == END)
        {
            /* we presume the repeated argument matches something, which
               isn't guaranteed, but it is conservative */
            return 0;
        }

        /* strictly speaking, matching one repeat didn't *necessarily*
           anchor the match, but we'll ignore such cases as
           pathological */
        nanch = 1;

        alt = alloc_alt(p2, sz);
        if (!alt)
        {
            return -1;
        }

        altcnt = (CurlyCount *)(alt + 1);
        dec_curly_counts(altcnt);
        if (altcnt[1] > 0)
        {
            right.origin = a2->origin;
            right.rn = alt;
            right.spent = 0;

            rv = compare_right_curly(nanch, a1, &right);
        }
        else
        {
            rv = 1;
        }

        free(alt);

        if (rv <= 0)
        {
            return rv;
        }

        a2->rn += sz - 1;
        assert(a2->rn->type == END);
        a2->spent = 0;
        return rv;
    }

    return compare_right_curly_from_zero(nanch, a1, a2);
}

static int compare_curly_curly(int anchored, Arrow *a1, Arrow *a2)
{
    regnode *p1, *p2, *e2;
    Arrow left, right;
    CurlyCount *cnt1, *cnt2;
    int rv, offs;

    /* fprintf(stderr, "enter compare_curly_curly(%d...)\n", anchored); */

    p1 = a1->rn;
    assert((p1->type == CURLY) || (p1->type == CURLYM) ||
           (p1->type == CURLYX));
    p2 = a2->rn;
    assert((p2->type == CURLY) || (p2->type == CURLYM) ||
           (p2->type == CURLYX));

    cnt1 = (CurlyCount *)(p1 + 1);
#ifndef RC_UNSIGNED_COUNT
    /* fprintf(stderr, "*cnt1 = %d\n", cnt1[0]); */
    if (cnt1[0] < 0)
    {
        rc_error = "Negative minimum for left curly";
        return -1;
    }
#endif

    cnt2 = (CurlyCount *)(p2 + 1);
#ifndef RC_UNSIGNED_COUNT
    /* fprintf(stderr, "*cnt2 = %d\n", cnt2[0]); */
    if (cnt2[0] < 0)
    {
        rc_error = "Negative minimum for right curly";
        return -1;
    }
#endif

    if (cnt2[0] > cnt1[0]) /* FIXME: fails '(?:aa){1,}' => 'a{2,}' */
    {
        /* fprintf(stderr, "curly mismatch\n"); */
        return compare_mismatch(anchored, a1, a2);
    }

    left.origin = a1->origin;
    left.rn = p1 + 2;
    left.spent = 0;

    if (cnt1[1] > cnt2[1])
    {
        offs = get_jump_offset(p2);
        /* fprintf(stderr, "offs = %d\n", offs); */
        if (offs <= 0)
        {
            return -1;
        }

        e2 = p2 + offs;
        /* fprintf(stderr, "e2->type = %d\n", e2->type); */
        if (e2->type != END)
        {
            return compare_mismatch(anchored, a1, a2);
        }
    }

    right.origin = a2->origin;
    right.rn = p2 + 2;
    right.spent = 0;

    /* fprintf(stderr, "comparing tails\n"); */

    rv = compare(anchored, &left, &right);
    /* fprintf(stderr, "tail compare returned %d\n", rv); */
    return (!rv && !cnt2[0]) ? compare_next(anchored, a1, a2) : rv;
}

static int compare_bound(int anchored, Arrow *a1, Arrow *a2,
    int move_left, unsigned char *bitmap, char *lookup,
    unsigned char *oktypes,
    unsigned char *regclasses, U32 regclasses_size)
{
    Arrow left, right;
    unsigned char t;
    int i;
    char *seq;

    assert((a2->rn->type == BOUND) || (a2->rn->type == NBOUND));

    left = *a1;

    if (bump_with_check(&left) <= 0)
    {
        return -1;
    }

    t = left.rn->type;
    if (t >= REGNODE_MAX)
    {
        rc_error = "Invalid node type";
        return -1;
    }
    else if (t == ANYOF)
    {
        /* fprintf(stderr, "next is bitmap; flags = 0x%x\n", left.rn->flags); */

        if (left.rn->flags & ANYOF_MATCHES_ALL_ABOVE_BITMAP)
        {
            return compare_mismatch(anchored, a1, a2);
        }

        for (i = 0; i < ANYOF_BITMAP_SIZE; ++i)
        {
            if (get_bitmap_byte(left.rn, i) & ~bitmap[i])
            {
                return compare_mismatch(anchored, a1, a2);
            }
        }
    }
    else if ((t == EXACT) || (t == EXACTF) || (t == EXACTFU))
    {
        seq = GET_LITERAL(&left);
        if (!lookup[(unsigned char)(*seq)])
        {
            return compare_mismatch(anchored, a1, a2);
        }
    }
    else if ((t == POSIXD) || (t == NPOSIXD) || (t == POSIXU) || (t == NPOSIXU))
    {
      U8 flags = left.rn->flags;
      if ((flags >= regclasses_size) || !regclasses[flags])
      {
          return compare_mismatch(anchored, a1, a2);
      }
    }
    else if (!oktypes[t])
    {
        return compare_mismatch(anchored, a1, a2);
    }

    right = *a2;
    if (bump_with_check(&right) <= 0)
    {
        return -1;
    }

    return move_left ? compare(1, &left, &right) :
        compare(anchored, a1, &right);
}

static int compare_bol_word(int anchored, Arrow *a1, Arrow *a2)
{
    return compare_bound(anchored, a1, a2, 1, word_bc.bitmap,
        word_bc.lookup, alphanumeric_classes,
        word_posix_regclasses, SIZEOF_ARRAY(word_posix_regclasses));
}

static int compare_bol_nword(int anchored, Arrow *a1, Arrow *a2)
{
    return compare_bound(anchored, a1, a2, 1, word_bc.nbitmap,
        word_bc.nlookup, non_alphanumeric_classes,
        non_word_posix_regclasses, SIZEOF_ARRAY(non_word_posix_regclasses));
}

static int compare_next_word(int anchored, Arrow *a1, Arrow *a2)
{
    return compare_bound(anchored, a1, a2, 0, word_bc.bitmap,
        word_bc.lookup, alphanumeric_classes,
        word_posix_regclasses, SIZEOF_ARRAY(word_posix_regclasses));
}

static int compare_next_nword(int anchored, Arrow *a1, Arrow *a2)
{
    return compare_bound(anchored, a1, a2, 0, word_bc.nbitmap,
        word_bc.nlookup, non_alphanumeric_classes,
        non_word_posix_regclasses, SIZEOF_ARRAY(non_word_posix_regclasses));
}

static int compare_anyof_bounds(int anchored, Arrow *a1, Arrow *a2,
    unsigned char *bitmap1, unsigned char *bitmap2)
{
    unsigned char loc;
    FCompare cmp[2];
    int i;

    cmp[0] = compare_next_word;
    cmp[1] = compare_next_nword;
    for (i = 0; (i < ANYOF_BITMAP_SIZE) && (cmp[0] || cmp[1]); ++i)
    {
        loc = bitmap1 ? bitmap1[i] : get_bitmap_byte(a1->rn, i);

        if (loc & ~bitmap2[i])
        {
             cmp[0] = 0;
        }

        if (loc & bitmap2[i])
        {
             cmp[1] = 0;
        }
    }

    if (cmp[0] && cmp[1])
    {
        rc_error = "Zero bitmap";
        return -1;
    }

    for (i = 0; i < SIZEOF_ARRAY(cmp); ++i)
    {
        if (cmp[i])
        {
            return (cmp[i])(anchored, a1, a2);
        }
    }

    /* if would be more elegant to use compare_mismatch as a sentinel
       in cmp, but VC 2003 then warns that this function might be
       missing a return... */
    return compare_mismatch(anchored, a1, a2);
}

static int compare_anyof_bound(int anchored, Arrow *a1, Arrow *a2)
{
    assert((a1->rn->type == ANYOF) || (a1->rn->type == ANYOFD));
    assert(a2->rn->type == BOUND);

    if (a1->rn->flags & ANYOF_MATCHES_ALL_ABOVE_BITMAP)
    {
        return compare_mismatch(anchored, a1, a2);
    }

    return compare_anyof_bounds(anchored, a1, a2, 0, word_bc.nbitmap);
}

static int compare_anyof_nbound(int anchored, Arrow *a1, Arrow *a2)
{
    assert((a1->rn->type == ANYOF) || (a1->rn->type == ANYOFD));
    assert(a2->rn->type == NBOUND);

    if (a1->rn->flags & ANYOF_MATCHES_ALL_ABOVE_BITMAP)
    {
        return compare_mismatch(anchored, a1, a2);
    }

    return compare_anyof_bounds(anchored, a1, a2, 0, word_bc.bitmap);
}

#ifdef RC_ANYOFM
static int compare_anyofm_bound(int anchored, Arrow *a1, Arrow *a2)
{
    unsigned char left[ANYOF_BITMAP_SIZE];

    assert(a1->rn->type == ANYOFM);
    assert(a2->rn->type == BOUND);

    if (!convert_anyofm_to_bitmap(a1, left))
    {
        return compare_mismatch(anchored, a1, a2);
    }

    return compare_anyof_bounds(anchored, a1, a2, left, word_bc.nbitmap);
}

static int compare_anyofm_nbound(int anchored, Arrow *a1, Arrow *a2)
{
    unsigned char left[ANYOF_BITMAP_SIZE];

    assert(a1->rn->type == ANYOFM);
    assert(a2->rn->type == NBOUND);

    if (!convert_anyofm_to_bitmap(a1, left))
    {
        return compare_mismatch(anchored, a1, a2);
    }

    return compare_anyof_bounds(anchored, a1, a2, left, word_bc.bitmap);
}
#endif

static int compare_exact_bound(int anchored, Arrow *a1, Arrow *a2)
{
    char *seq;
    FCompare cmp;

    assert((a1->rn->type == EXACT) || (a1->rn->type == EXACTF) ||
        (a1->rn->type == EXACTFU));
    assert(a2->rn->type == BOUND);

    seq = GET_LITERAL(a1);

    cmp = word_bc.lookup[(unsigned char)(*seq)] ?
        compare_next_nword : compare_next_word;
    return cmp(anchored, a1, a2);
}

static int compare_exact_nbound(int anchored, Arrow *a1, Arrow *a2)
{
    char *seq;
    FCompare cmp;

    assert((a1->rn->type == EXACT) || (a1->rn->type == EXACTF) ||
        (a1->rn->type == EXACTFU));
    assert(a2->rn->type == NBOUND);

    seq = GET_LITERAL(a1);

    cmp = word_bc.lookup[(unsigned char)(*seq)] ?
        compare_next_word : compare_next_nword;
    return cmp(anchored, a1, a2);
}

static int compare_posix_bound(int anchored, Arrow *a1, Arrow *a2)
{
    assert((a1->rn->type == POSIXD) || (a1->rn->type == POSIXU) ||
        (a1->rn->type == POSIXA));
    assert(a2->rn->type == BOUND);

    U8 flags = a1->rn->flags;
    if ((flags >= SIZEOF_ARRAY(word_posix_regclasses)) ||
        (flags >= SIZEOF_ARRAY(non_word_posix_regclasses)) ||
        (!word_posix_regclasses[flags] && !non_word_posix_regclasses[flags]))
    {
        return compare_mismatch(anchored, a1, a2);
    }

    assert(!word_posix_regclasses[flags] || !non_word_posix_regclasses[flags]);

    FCompare cmp = word_posix_regclasses[flags] ?
        compare_next_nword : compare_next_word;
    return cmp(anchored, a1, a2);
}

static int compare_posix_nbound(int anchored, Arrow *a1, Arrow *a2)
{
    assert((a1->rn->type == POSIXD) || (a1->rn->type == POSIXU) ||
        (a1->rn->type == POSIXA));
    assert(a2->rn->type == NBOUND);

    U8 flags = a1->rn->flags;
    if ((flags >= SIZEOF_ARRAY(word_posix_regclasses)) ||
        (flags >= SIZEOF_ARRAY(non_word_posix_regclasses)) ||
        (!word_posix_regclasses[flags] && !non_word_posix_regclasses[flags]))
    {
        return compare_mismatch(anchored, a1, a2);
    }

    assert(!word_posix_regclasses[flags] || !non_word_posix_regclasses[flags]);

    FCompare cmp = word_posix_regclasses[flags] ?
        compare_next_word : compare_next_nword;
    return cmp(anchored, a1, a2);
}

static int compare_negative_posix_word_bound(int anchored, Arrow *a1, Arrow *a2)
{
    assert((a1->rn->type == NPOSIXD) || (a1->rn->type == NPOSIXU) ||
        (a1->rn->type == NPOSIXA));
    assert(a2->rn->type == BOUND);

    /* we could accept _CC_ALPHANUMERIC as well but let's postpone it
       until we see the need */
    if (a1->rn->flags != _CC_WORDCHAR)
    {
        return compare_mismatch(anchored, a1, a2);
    }

    return compare_next_word(anchored, a1, a2);
}

static int compare_negative_posix_word_nbound(int anchored, Arrow *a1, Arrow *a2)
{
    assert((a1->rn->type == NPOSIXD) || (a1->rn->type == NPOSIXU) ||
        (a1->rn->type == NPOSIXA));
    assert(a2->rn->type == NBOUND);

    /* we could accept _CC_ALPHANUMERIC as well but let's postpone it
       until we see the need */
    if (a1->rn->flags != _CC_WORDCHAR)
    {
        return compare_mismatch(anchored, a1, a2);
    }

    return compare_next_nword(anchored, a1, a2);
}

static int compare_open_open(int anchored, Arrow *a1, Arrow *a2)
{
    return compare_tails(anchored, a1, a2);
}

static int compare_left_open(int anchored, Arrow *a1, Arrow *a2)
{
    return compare_left_tail(anchored, a1, a2);
}

static int compare_right_open(int anchored, Arrow *a1, Arrow *a2)
{
    return compare_next(anchored, a1, a2);
}

static int success(int anchored, Arrow *a1, Arrow *a2)
{
    return 1;
}

/* #define DEBUG_dump */

int rc_compare(REGEXP *pt1, REGEXP *pt2)
{
    Arrow a1, a2;
    regnode *p1, *p2;
#ifdef DEBUG_dump
    unsigned char *p;
    int i;
#endif

    a1.origin = SvANY(pt1);
    a2.origin = SvANY(pt2);

    if ((get_forced_semantics(pt1) | get_forced_semantics(pt2)) == FORCED_MISMATCH)
    {
        return 0;
    }

    p1 = find_internal(a1.origin);
    if (!p1)
    {
        return -1;
    }

    p2 = find_internal(a2.origin);
    if (!p2)
    {
        return -1;
    }

#ifdef DEBUG_dump
    p = (unsigned char *)p1;
    for (i = 1; i <= 64; ++i)
    {
        fprintf(stderr, " %02x", (int)p[i - 1]);
        if (!(i % 4))
        {
            fprintf(stderr, "\n");
        }
    }

    fprintf(stderr, "\n\n");

    p = (unsigned char *)p2;
    for (i = 1; i <= 64; ++i)
    {
        fprintf(stderr, " %02x", (int)p[i - 1]);
        if (!(i % 4))
        {
            fprintf(stderr, "\n");
        }
    }

    fprintf(stderr, "\n\n");
#endif

    a1.rn = p1;
    a1.spent = 0;
    a2.rn = p2;
    a2.spent = 0;

    return compare(0, &a1, &a2);
}

static int compare(int anchored, Arrow *a1, Arrow *a2)
{
    FCompare cmp;

    /* fprintf(stderr, "enter compare(%d, %d, %d)\n", anchored,
       a1->rn->type, a2->rn->type); */

    if ((a1->rn->type >= REGNODE_MAX) || (a2->rn->type >= REGNODE_MAX))
    {
        rc_error = "Invalid regexp node type";
        return -1;
    }

    cmp = dispatch[a1->rn->type][a2->rn->type];
    if (!cmp)
    {
        /* fprintf(stderr, "no comparator\n"); */
        return 0;
    }

    return cmp(anchored, a1, a2);
}

void rc_init()
{
    int i, wstart;

    /* could have used compile-time assertion, but why bother
       making it compatible... */
    assert(ANYOF_BITMAP_SIZE == 32);

    init_forced_byte();

    init_byte_class(&whitespace, whitespace_expl,
        SIZEOF_ARRAY(whitespace_expl));
    init_byte_class(&horizontal_whitespace, horizontal_whitespace_expl,
        SIZEOF_ARRAY(horizontal_whitespace_expl));
    init_byte_class(&vertical_whitespace, vertical_whitespace_expl,
        SIZEOF_ARRAY(vertical_whitespace_expl));

    for (i = 0; i < SIZEOF_ARRAY(digit_expl); ++i)
    {
        digit_expl[i] = '0' + i;
    }

    init_byte_class(&digit, digit_expl, SIZEOF_ARRAY(digit_expl));

    memcpy(xdigit_expl, digit_expl, 10 * sizeof(char));

    wstart = 10;
    for (i = 0; i < 6; ++i)
    {
        xdigit_expl[wstart + i] = 'a' + i;
    }

    wstart += 6;
    for (i = 0; i < 6; ++i)
    {
        xdigit_expl[wstart + i] = 'A' + i;
    }

    init_byte_class(&xdigit, xdigit_expl, SIZEOF_ARRAY(xdigit_expl));

    init_byte_class(&ndot, ndot_expl, SIZEOF_ARRAY(ndot_expl));

    alphanumeric_expl[0] = '_';

    wstart = 1;
    memcpy(alphanumeric_expl + wstart, digit_expl, 10 * sizeof(char));

    wstart += 10;
    for (i = 0; i < LETTER_COUNT; ++i)
    {
        alphanumeric_expl[wstart + i] = 'a' + i;
    }

    wstart += LETTER_COUNT;
    for (i = 0; i < LETTER_COUNT; ++i)
    {
        alphanumeric_expl[wstart + i] = 'A' + i;
    }

    init_byte_class(&word_bc, alphanumeric_expl,
        SIZEOF_ARRAY(alphanumeric_expl));
    init_byte_class(&alnum_bc, alphanumeric_expl + 1,
        SIZEOF_ARRAY(alphanumeric_expl) - 1);

    for (i = 0; i < LETTER_COUNT; ++i)
    {
        alpha_expl[i] = lower_expl[i] = 'a' + i;
    }

    wstart = LETTER_COUNT;
    for (i = 0; i < LETTER_COUNT; ++i)
    {
        alpha_expl[wstart + i] = upper_expl[i] = 'A' + i;
    }

    init_byte_class(&alpha_bc, alpha_expl,
        SIZEOF_ARRAY(alpha_expl));
    init_byte_class(&lower_bc, lower_expl,
        SIZEOF_ARRAY(lower_expl));
    init_byte_class(&upper_bc, upper_expl,
        SIZEOF_ARRAY(upper_expl));

    memset(alphanumeric_classes, 0, SIZEOF_ARRAY(alphanumeric_classes));

    memset(non_alphanumeric_classes, 0,
        SIZEOF_ARRAY(non_alphanumeric_classes));
    non_alphanumeric_classes[EOS] = non_alphanumeric_classes[EOL] =
        non_alphanumeric_classes[SEOL] = 1;

    posix_regclass_blocks[_CC_VERTSPACE] = VERTICAL_SPACE_BLOCK;
    posix_regclass_bitmaps[_CC_VERTSPACE] = vertical_whitespace.bitmap;
    posix_regclass_nbitmaps[_CC_VERTSPACE] = vertical_whitespace.nbitmap;

    memset(word_posix_regclasses, 0,
        SIZEOF_ARRAY(word_posix_regclasses));
    word_posix_regclasses[_CC_WORDCHAR] =
        word_posix_regclasses[_CC_DIGIT] =
        word_posix_regclasses[_CC_ALPHA] =
        word_posix_regclasses[_CC_LOWER] =
        word_posix_regclasses[_CC_UPPER] =
        word_posix_regclasses[_CC_UPPER] =
        word_posix_regclasses[_CC_ALPHANUMERIC] =
        word_posix_regclasses[_CC_CASED] =
        word_posix_regclasses[_CC_XDIGIT] = 1;

    memset(non_word_posix_regclasses, 0,
        SIZEOF_ARRAY(non_word_posix_regclasses));
    non_word_posix_regclasses[_CC_PUNCT] =
        non_word_posix_regclasses[_CC_SPACE] =
        non_word_posix_regclasses[_CC_BLANK] =
        non_word_posix_regclasses[_CC_VERTSPACE] = 1;

    memset(newline_posix_regclasses, 0,
        SIZEOF_ARRAY(newline_posix_regclasses));
    newline_posix_regclasses[_CC_SPACE] =
        newline_posix_regclasses[_CC_CNTRL] =
        newline_posix_regclasses[_CC_ASCII] =
        newline_posix_regclasses[_CC_VERTSPACE] = 1;

    memset(trivial_nodes, 0, SIZEOF_ARRAY(trivial_nodes));
    trivial_nodes[SUCCEED] = trivial_nodes[NOTHING] =
        trivial_nodes[TAIL] = trivial_nodes[WHILEM] = 1;

    memset(dispatch, 0, sizeof(FCompare) * REGNODE_MAX * REGNODE_MAX);

    for (i = 0; i < REGNODE_MAX; ++i)
    {
        dispatch[i][END] = success;
    }

    for (i = 0; i < REGNODE_MAX; ++i)
    {
        dispatch[i][SUCCEED] = compare_next;
    }

    dispatch[SUCCEED][SUCCEED] = compare_tails;

    dispatch[SUCCEED][MBOL] = compare_left_tail;
    dispatch[MBOL][MBOL] = compare_tails;
    dispatch[SBOL][MBOL] = compare_tails;
    dispatch[REG_ANY][MBOL] = compare_mismatch;
    dispatch[SANY][MBOL] = compare_mismatch;
    dispatch[ANYOF][MBOL] = compare_anyof_multiline;
    dispatch[ANYOFD][MBOL] = compare_anyof_multiline;
#ifdef RC_ANYOFM
    dispatch[ANYOFM][MBOL] = compare_anyofm_multiline;
#endif
#ifdef RC_NANYOFM
    dispatch[NANYOFM][MBOL] = compare_nanyofm_multiline;
#endif
    dispatch[POSIXD][MBOL] = compare_mismatch;
    dispatch[POSIXU][MBOL] = compare_mismatch;
    dispatch[POSIXA][MBOL] = compare_mismatch;
    dispatch[NPOSIXD][MBOL] = compare_mismatch;
    dispatch[NPOSIXU][MBOL] = compare_mismatch;
    dispatch[NPOSIXA][MBOL] = compare_mismatch;
    dispatch[BRANCH][MBOL] = compare_left_branch;
    dispatch[EXACT][MBOL] = compare_exact_multiline;
    dispatch[EXACTF][MBOL] = compare_exact_multiline;
    dispatch[EXACTFU][MBOL] = compare_exact_multiline;
    dispatch[NOTHING][MBOL] = compare_left_tail;
    dispatch[TAIL][MBOL] = compare_left_tail;
    dispatch[STAR][MBOL] = compare_mismatch;
    dispatch[PLUS][MBOL] = compare_left_plus;
    dispatch[CURLY][MBOL] = compare_left_curly;
    dispatch[CURLYM][MBOL] = compare_left_curly;
    dispatch[CURLYX][MBOL] = compare_left_curly;
    dispatch[WHILEM][MBOL] = compare_left_tail;
    dispatch[OPEN][MBOL] = compare_left_open;
    dispatch[CLOSE][MBOL] = compare_left_tail;
    dispatch[IFMATCH][MBOL] = compare_after_assertion;
    dispatch[UNLESSM][MBOL] = compare_after_assertion;
    dispatch[MINMOD][MBOL] = compare_left_tail;
    dispatch[LNBREAK][MBOL] = compare_tails;
    dispatch[OPTIMIZED][MBOL] = compare_left_tail;

    dispatch[SUCCEED][SBOL] = compare_left_tail;
    dispatch[SBOL][SBOL] = compare_tails;
    dispatch[BRANCH][SBOL] = compare_left_branch;
    dispatch[NOTHING][SBOL] = compare_left_tail;
    dispatch[TAIL][SBOL] = compare_left_tail;
    dispatch[STAR][SBOL] = compare_mismatch;
    dispatch[PLUS][SBOL] = compare_left_plus;
    dispatch[CURLY][SBOL] = compare_left_curly;
    dispatch[CURLYM][SBOL] = compare_left_curly;
    dispatch[CURLYX][SBOL] = compare_left_curly;
    dispatch[WHILEM][SBOL] = compare_left_tail;
    dispatch[OPEN][SBOL] = compare_left_open;
    dispatch[CLOSE][SBOL] = compare_left_tail;
    dispatch[IFMATCH][SBOL] = compare_after_assertion;
    dispatch[UNLESSM][SBOL] = compare_after_assertion;
    dispatch[MINMOD][SBOL] = compare_left_tail;
    dispatch[OPTIMIZED][SBOL] = compare_left_tail;

    dispatch[SUCCEED][EOS] = compare_left_tail;
    dispatch[EOS][EOS] = compare_tails;
    dispatch[EOL][EOS] = compare_mismatch;
    dispatch[SEOL][EOS] = compare_mismatch;
    dispatch[BRANCH][EOS] = compare_left_branch;
    dispatch[NOTHING][EOS] = compare_left_tail;
    dispatch[TAIL][EOS] = compare_left_tail;
    dispatch[STAR][EOS] = compare_mismatch;
    dispatch[PLUS][EOS] = compare_left_plus;
    dispatch[CURLY][EOS] = compare_left_curly;
    dispatch[CURLYM][EOS] = compare_left_curly;
    dispatch[CURLYX][EOS] = compare_left_curly;
    dispatch[WHILEM][EOS] = compare_left_tail;
    dispatch[OPEN][EOS] = compare_left_open;
    dispatch[CLOSE][EOS] = compare_left_tail;
    dispatch[IFMATCH][EOS] = compare_after_assertion;
    dispatch[UNLESSM][EOS] = compare_after_assertion;
    dispatch[MINMOD][EOS] = compare_left_tail;
    dispatch[OPTIMIZED][EOS] = compare_left_tail;

    dispatch[SUCCEED][EOL] = compare_left_tail;
    dispatch[EOS][EOL] = compare_tails;
    dispatch[EOL][EOL] = compare_tails;
    dispatch[SEOL][EOL] = compare_tails;
    dispatch[BRANCH][EOL] = compare_left_branch;
    dispatch[NOTHING][EOL] = compare_left_tail;
    dispatch[TAIL][EOL] = compare_left_tail;
    dispatch[STAR][EOL] = compare_mismatch;
    dispatch[PLUS][EOL] = compare_left_plus;
    dispatch[CURLY][EOL] = compare_left_curly;
    dispatch[CURLYM][EOL] = compare_left_curly;
    dispatch[CURLYX][EOL] = compare_left_curly;
    dispatch[WHILEM][EOL] = compare_left_tail;
    dispatch[OPEN][EOL] = compare_left_open;
    dispatch[CLOSE][EOL] = compare_left_tail;
    dispatch[IFMATCH][EOL] = compare_after_assertion;
    dispatch[UNLESSM][EOL] = compare_after_assertion;
    dispatch[MINMOD][EOL] = compare_left_tail;
    dispatch[OPTIMIZED][EOL] = compare_left_tail;

    dispatch[SUCCEED][MEOL] = compare_left_tail;
    dispatch[EOS][MEOL] = compare_tails;
    dispatch[EOL][MEOL] = compare_tails;
    dispatch[MEOL][MEOL] = compare_tails;
    dispatch[SEOL][MEOL] = compare_tails;
    dispatch[REG_ANY][MEOL] = compare_mismatch;
    dispatch[SANY][MEOL] = compare_mismatch;
    dispatch[ANYOF][MEOL] = compare_anyof_multiline; /* not in tests; remove? */
    dispatch[POSIXD][MEOL] = compare_mismatch;
    dispatch[POSIXU][MEOL] = compare_mismatch;
    dispatch[POSIXA][MEOL] = compare_mismatch;
    dispatch[NPOSIXD][MEOL] = compare_mismatch;
    dispatch[NPOSIXU][MEOL] = compare_mismatch;
    dispatch[NPOSIXA][MEOL] = compare_mismatch;
    dispatch[BRANCH][MEOL] = compare_left_branch;
    dispatch[EXACT][MEOL] = compare_exact_multiline;
    dispatch[EXACTF][MEOL] = compare_exact_multiline;
    dispatch[EXACTFU][MEOL] = compare_exact_multiline;
    dispatch[NOTHING][MEOL] = compare_left_tail;
    dispatch[TAIL][MEOL] = compare_left_tail;
    dispatch[STAR][MEOL] = compare_mismatch;
    dispatch[PLUS][MEOL] = compare_left_plus;
    dispatch[CURLY][MEOL] = compare_left_curly;
    dispatch[CURLYM][MEOL] = compare_left_curly;
    dispatch[CURLYX][MEOL] = compare_left_curly;
    dispatch[WHILEM][MEOL] = compare_left_tail;
    dispatch[OPEN][MEOL] = compare_left_open;
    dispatch[CLOSE][MEOL] = compare_left_tail;
    dispatch[IFMATCH][MEOL] = compare_after_assertion;
    dispatch[UNLESSM][MEOL] = compare_after_assertion;
    dispatch[MINMOD][MEOL] = compare_left_tail;
    dispatch[LNBREAK][MEOL] = compare_mismatch;
    dispatch[OPTIMIZED][MEOL] = compare_left_tail;

    dispatch[SUCCEED][SEOL] = compare_left_tail;
    dispatch[EOS][SEOL] = compare_tails;
    dispatch[EOL][SEOL] = compare_tails;
    dispatch[SEOL][SEOL] = compare_tails;
    dispatch[BRANCH][SEOL] = compare_left_branch;
    dispatch[NOTHING][SEOL] = compare_left_tail;
    dispatch[POSIXD][SEOL] = compare_mismatch;
    dispatch[POSIXU][SEOL] = compare_mismatch;
    dispatch[POSIXA][SEOL] = compare_mismatch;
    dispatch[NPOSIXD][SEOL] = compare_mismatch;
    dispatch[NPOSIXU][SEOL] = compare_mismatch;
    dispatch[NPOSIXA][SEOL] = compare_mismatch;
    dispatch[TAIL][SEOL] = compare_left_tail;
    dispatch[STAR][SEOL] = 0;
    dispatch[PLUS][SEOL] = compare_left_plus;
    dispatch[CURLY][SEOL] = compare_left_curly;
    dispatch[CURLYM][SEOL] = compare_left_curly;
    dispatch[CURLYX][SEOL] = compare_left_curly;
    dispatch[WHILEM][SEOL] = compare_left_tail;
    dispatch[OPEN][SEOL] = compare_left_open;
    dispatch[CLOSE][SEOL] = compare_left_tail;
    dispatch[IFMATCH][SEOL] = compare_after_assertion;
    dispatch[UNLESSM][SEOL] = compare_after_assertion;
    dispatch[MINMOD][SEOL] = compare_left_tail;
    dispatch[LNBREAK][SEOL] = compare_mismatch;
    dispatch[OPTIMIZED][SEOL] = compare_left_tail;

    dispatch[SUCCEED][BOUND] = compare_left_tail;
    dispatch[MBOL][BOUND] = compare_bol_word;
    dispatch[SBOL][BOUND] = compare_bol_word;
    dispatch[BOUND][BOUND] = compare_tails;
    dispatch[NBOUND][BOUND] = compare_mismatch;
    dispatch[REG_ANY][BOUND] = compare_mismatch;
    dispatch[SANY][BOUND] = compare_mismatch;
    dispatch[ANYOF][BOUND] = compare_anyof_bound;
    dispatch[ANYOFD][BOUND] = compare_anyof_bound;
#ifdef RC_ANYOFM
    dispatch[ANYOFM][BOUND] = compare_anyofm_bound;
#endif
#ifdef RC_NANYOFM
    dispatch[NANYOFM][BOUND] = compare_mismatch;
#endif
    dispatch[POSIXD][BOUND] = compare_posix_bound;
    dispatch[POSIXU][BOUND] = compare_posix_bound;
    dispatch[POSIXA][BOUND] = compare_posix_bound;
    dispatch[NPOSIXD][BOUND] = compare_negative_posix_word_bound;
    dispatch[NPOSIXU][BOUND] = compare_mismatch; /* should be replaced, needs extra test */
    dispatch[NPOSIXA][BOUND] = compare_negative_posix_word_bound;
    dispatch[BRANCH][BOUND] = compare_left_branch;
    dispatch[EXACT][BOUND] = compare_exact_bound;
    dispatch[EXACTF][BOUND] = compare_exact_bound;
    dispatch[EXACTFU][BOUND] = compare_exact_bound;
    dispatch[NOTHING][BOUND] = compare_left_tail;
    dispatch[TAIL][BOUND] = compare_left_tail;
    dispatch[CURLY][BOUND] = compare_left_curly;
    dispatch[CURLYM][BOUND] = compare_left_curly;
    dispatch[CURLYX][BOUND] = compare_left_curly;
    dispatch[WHILEM][BOUND] = compare_left_tail;
    dispatch[OPEN][BOUND] = compare_left_open;
    dispatch[CLOSE][BOUND] = compare_left_tail;
    dispatch[IFMATCH][BOUND] = compare_after_assertion;
    dispatch[UNLESSM][BOUND] = compare_after_assertion;
    dispatch[MINMOD][BOUND] = compare_left_tail;
    dispatch[LNBREAK][BOUND] = compare_mismatch;
    dispatch[OPTIMIZED][BOUND] = compare_left_tail;

    dispatch[SUCCEED][NBOUND] = compare_left_tail;
    dispatch[MBOL][NBOUND] = compare_bol_nword;
    dispatch[SBOL][NBOUND] = compare_bol_nword;
    dispatch[BOUND][NBOUND] = compare_mismatch;
    dispatch[NBOUND][NBOUND] = compare_tails;
    dispatch[REG_ANY][NBOUND] = compare_mismatch;
    dispatch[SANY][NBOUND] = compare_mismatch;
    dispatch[ANYOF][NBOUND] = compare_anyof_nbound;
    dispatch[ANYOFD][NBOUND] = compare_anyof_nbound;
#ifdef RC_ANYOFM
    dispatch[ANYOFM][NBOUND] = compare_anyofm_nbound;
#endif
#ifdef RC_NANYOFM
    dispatch[NANYOFM][NBOUND] = compare_mismatch;
#endif
    dispatch[POSIXD][NBOUND] = compare_posix_nbound;
    dispatch[POSIXU][NBOUND] = compare_posix_nbound;
    dispatch[POSIXA][NBOUND] = compare_posix_nbound;
    dispatch[NPOSIXD][NBOUND] = compare_negative_posix_word_nbound;
    dispatch[NPOSIXU][NBOUND] = compare_negative_posix_word_nbound;
    dispatch[NPOSIXA][NBOUND] = compare_negative_posix_word_nbound;
    dispatch[BRANCH][NBOUND] = compare_left_branch;
    dispatch[EXACT][NBOUND] = compare_exact_nbound;
    dispatch[EXACTF][NBOUND] = compare_exact_nbound;
    dispatch[EXACTFU][NBOUND] = compare_exact_nbound;
    dispatch[NOTHING][NBOUND] = compare_left_tail;
    dispatch[TAIL][NBOUND] = compare_left_tail;
    dispatch[CURLY][NBOUND] = compare_left_curly;
    dispatch[CURLYM][NBOUND] = compare_left_curly;
    dispatch[CURLYX][NBOUND] = compare_left_curly;
    dispatch[WHILEM][NBOUND] = compare_left_tail;
    dispatch[OPEN][NBOUND] = compare_left_open;
    dispatch[CLOSE][NBOUND] = compare_left_tail;
    dispatch[IFMATCH][NBOUND] = compare_after_assertion;
    dispatch[UNLESSM][NBOUND] = compare_after_assertion;
    dispatch[MINMOD][NBOUND] = compare_left_tail;
    dispatch[LNBREAK][NBOUND] = compare_mismatch;
    dispatch[OPTIMIZED][NBOUND] = compare_left_tail;

    dispatch[SUCCEED][REG_ANY] = compare_left_tail;
    dispatch[MBOL][REG_ANY] = compare_bol;
    dispatch[SBOL][REG_ANY] = compare_bol;
    dispatch[BOUND][REG_ANY] = compare_mismatch;
    dispatch[NBOUND][REG_ANY] = compare_mismatch;
    dispatch[REG_ANY][REG_ANY] = compare_tails;
    dispatch[SANY][REG_ANY] = compare_mismatch;
    dispatch[ANYOF][REG_ANY] = compare_anyof_reg_any;
    dispatch[ANYOFD][REG_ANY] = compare_anyof_reg_any;
#ifdef RC_ANYOFM
    dispatch[ANYOFM][REG_ANY] = compare_anyofm_reg_any;
#endif
#ifdef RC_NANYOFM
    dispatch[NANYOFM][REG_ANY] = compare_nanyofm_reg_any;
#endif
    dispatch[POSIXD][REG_ANY] = compare_posix_reg_any;
    dispatch[POSIXU][REG_ANY] = compare_posix_reg_any;
    dispatch[POSIXA][REG_ANY] = compare_posix_reg_any;
    dispatch[NPOSIXD][REG_ANY] = compare_negative_posix_reg_any;
    dispatch[NPOSIXU][REG_ANY] = compare_negative_posix_reg_any;
    dispatch[NPOSIXA][REG_ANY] = compare_negative_posix_reg_any;
    dispatch[BRANCH][REG_ANY] = compare_left_branch;
    dispatch[EXACT][REG_ANY] = compare_exact_reg_any;
    dispatch[EXACTF][REG_ANY] = compare_exact_reg_any;
    dispatch[EXACTFU][REG_ANY] = compare_exact_reg_any;
    dispatch[NOTHING][REG_ANY] = compare_left_tail;
    dispatch[TAIL][REG_ANY] = compare_left_tail;
    dispatch[STAR][REG_ANY] = compare_mismatch;
    dispatch[PLUS][REG_ANY] = compare_left_plus;
    dispatch[CURLY][REG_ANY] = compare_left_curly;
    dispatch[CURLYM][REG_ANY] = compare_left_curly;
    dispatch[CURLYX][REG_ANY] = compare_left_curly;
    dispatch[WHILEM][REG_ANY] = compare_left_tail;
    dispatch[OPEN][REG_ANY] = compare_left_open;
    dispatch[CLOSE][REG_ANY] = compare_left_tail;
    dispatch[IFMATCH][REG_ANY] = compare_after_assertion;
    dispatch[UNLESSM][REG_ANY] = compare_after_assertion;
    dispatch[MINMOD][REG_ANY] = compare_left_tail;
    dispatch[LNBREAK][REG_ANY] = compare_mismatch;
    dispatch[OPTIMIZED][REG_ANY] = compare_left_tail;

    dispatch[SUCCEED][SANY] = compare_left_tail;
    dispatch[MBOL][SANY] = compare_bol;
    dispatch[SBOL][SANY] = compare_bol;
    dispatch[BOUND][SANY] = compare_mismatch;
    dispatch[NBOUND][SANY] = compare_mismatch;
    dispatch[REG_ANY][SANY] = compare_tails;
    dispatch[SANY][SANY] = compare_tails;
    dispatch[ANYOF][SANY] = compare_tails;
    dispatch[ANYOFD][SANY] = compare_tails;
#ifdef RC_ANYOFM
    dispatch[ANYOFM][SANY] = compare_tails;
#endif
#ifdef RC_NANYOFM
    dispatch[NANYOFM][SANY] = compare_tails;
#endif
    dispatch[POSIXD][SANY] = compare_tails;
    dispatch[POSIXU][SANY] = compare_tails;
    dispatch[POSIXA][SANY] = compare_tails;
    dispatch[NPOSIXD][SANY] = compare_tails;
    dispatch[NPOSIXU][SANY] = compare_tails;
    dispatch[NPOSIXA][SANY] = compare_tails;
    dispatch[BRANCH][SANY] = compare_left_branch;
    dispatch[EXACT][SANY] = compare_tails;
    dispatch[EXACTF][SANY] = compare_tails;
    dispatch[EXACTFU][SANY] = compare_tails;
    dispatch[NOTHING][SANY] = compare_left_tail;
    dispatch[TAIL][SANY] = compare_left_tail;
    dispatch[STAR][SANY] = compare_mismatch;
    dispatch[PLUS][SANY] = compare_left_plus;
    dispatch[CURLY][SANY] = compare_left_curly;
    dispatch[CURLYM][SANY] = compare_left_curly;
    dispatch[CURLYX][SANY] = compare_left_curly;
    dispatch[WHILEM][SANY] = compare_left_tail;
    dispatch[OPEN][SANY] = compare_left_open;
    dispatch[CLOSE][SANY] = compare_left_tail;
    dispatch[IFMATCH][SANY] = compare_after_assertion;
    dispatch[UNLESSM][SANY] = compare_after_assertion;
    dispatch[MINMOD][SANY] = compare_left_tail;
    dispatch[LNBREAK][SANY] = compare_mismatch;
    dispatch[OPTIMIZED][SANY] = compare_left_tail;

    dispatch[SUCCEED][ANYOF] = compare_left_tail;
    dispatch[MBOL][ANYOF] = compare_bol;
    dispatch[SBOL][ANYOF] = compare_bol;
    dispatch[BOUND][ANYOF] = compare_mismatch;
    dispatch[NBOUND][ANYOF] = compare_mismatch;
    dispatch[REG_ANY][ANYOF] = compare_reg_any_anyof;
    dispatch[SANY][ANYOF] = compare_sany_anyof;
    dispatch[ANYOF][ANYOF] = compare_anyof_anyof;
    dispatch[ANYOFD][ANYOF] = compare_anyof_anyof;
#ifdef RC_ANYOFM
    dispatch[ANYOFM][ANYOF] = compare_anyofm_anyof;
#endif
#ifdef RC_NANYOFM
    dispatch[NANYOFM][ANYOF] = compare_mismatch;
#endif
    dispatch[POSIXD][ANYOF] = compare_posix_anyof;
    dispatch[POSIXU][ANYOF] = compare_posix_anyof;
    dispatch[POSIXA][ANYOF] = compare_posix_anyof;
    dispatch[NPOSIXD][ANYOF] = compare_negative_posix_anyof;
    dispatch[NPOSIXU][ANYOF] = compare_negative_posix_anyof;
    dispatch[NPOSIXA][ANYOF] = compare_negative_posix_anyof;
    dispatch[BRANCH][ANYOF] = compare_left_branch;
    dispatch[EXACT][ANYOF] = compare_exact_anyof;
    dispatch[EXACTF][ANYOF] = compare_exactf_anyof;
    dispatch[EXACTFU][ANYOF] = compare_exactf_anyof;
    dispatch[NOTHING][ANYOF] = compare_left_tail;
    dispatch[TAIL][ANYOF] = compare_left_tail;
    dispatch[STAR][ANYOF] = compare_mismatch;
    dispatch[PLUS][ANYOF] = compare_left_plus;
    dispatch[CURLY][ANYOF] = compare_left_curly;
    dispatch[CURLYM][ANYOF] = compare_left_curly;
    dispatch[CURLYX][ANYOF] = compare_left_curly;
    dispatch[WHILEM][ANYOF] = compare_left_tail;
    dispatch[OPEN][ANYOF] = compare_left_open;
    dispatch[CLOSE][ANYOF] = compare_left_tail;
    dispatch[IFMATCH][ANYOF] = compare_after_assertion;
    dispatch[UNLESSM][ANYOF] = compare_after_assertion;
    dispatch[MINMOD][ANYOF] = compare_left_tail;
    dispatch[LNBREAK][ANYOF] = compare_mismatch;
    dispatch[OPTIMIZED][ANYOF] = compare_left_tail;

    dispatch[SUCCEED][ANYOFD] = compare_left_tail;
    dispatch[MBOL][ANYOFD] = compare_bol;
    dispatch[SBOL][ANYOFD] = compare_bol;
    dispatch[BOUND][ANYOFD] = compare_mismatch;
    dispatch[NBOUND][ANYOFD] = compare_mismatch;
    dispatch[REG_ANY][ANYOFD] = compare_reg_any_anyof;
    dispatch[SANY][ANYOFD] = compare_sany_anyof;
    dispatch[ANYOF][ANYOFD] = compare_anyof_anyof;
    dispatch[ANYOFD][ANYOFD] = compare_anyof_anyof;
#ifdef RC_ANYOFM
    dispatch[ANYOFM][ANYOFD] = compare_anyofm_anyof;
#endif
#ifdef RC_NANYOFM
    dispatch[NANYOFM][ANYOFD] = compare_mismatch;
#endif
    dispatch[POSIXD][ANYOFD] = compare_posix_anyof;
    dispatch[POSIXU][ANYOFD] = compare_posix_anyof;
    dispatch[POSIXA][ANYOFD] = compare_posix_anyof;
    dispatch[NPOSIXD][ANYOFD] = compare_negative_posix_anyof;
    dispatch[NPOSIXU][ANYOFD] = compare_negative_posix_anyof;
    dispatch[NPOSIXA][ANYOFD] = compare_negative_posix_anyof;
    dispatch[BRANCH][ANYOFD] = compare_left_branch;
    dispatch[EXACT][ANYOFD] = compare_exact_anyof;
    dispatch[EXACTFU][ANYOFD] = compare_exactf_anyof;
    dispatch[NOTHING][ANYOFD] = compare_left_tail;
    dispatch[TAIL][ANYOFD] = compare_left_tail;
    dispatch[STAR][ANYOFD] = compare_mismatch;
    dispatch[PLUS][ANYOFD] = compare_left_plus;
    dispatch[CURLY][ANYOFD] = compare_left_curly;
    dispatch[CURLYM][ANYOFD] = compare_left_curly;
    dispatch[CURLYX][ANYOFD] = compare_left_curly;
    dispatch[OPEN][ANYOFD] = compare_left_open;
    dispatch[CLOSE][ANYOFD] = compare_left_tail;
    dispatch[IFMATCH][ANYOFD] = compare_after_assertion;
    dispatch[UNLESSM][ANYOFD] = compare_after_assertion;
    dispatch[MINMOD][ANYOFD] = compare_left_tail;
    dispatch[LNBREAK][ANYOFD] = compare_mismatch;
    dispatch[OPTIMIZED][ANYOFD] = compare_left_tail;

#ifdef RC_ANYOFM
    dispatch[SUCCEED][ANYOFM] = compare_left_tail;
    dispatch[MBOL][ANYOFM] = compare_bol;
    dispatch[SBOL][ANYOFM] = compare_bol;
    dispatch[BOUND][ANYOFM] = compare_mismatch;
    dispatch[NBOUND][ANYOFM] = compare_mismatch;
    dispatch[REG_ANY][ANYOFM] = compare_mismatch;
    dispatch[SANY][ANYOFM] = compare_mismatch;
    dispatch[ANYOF][ANYOFM] = compare_anyof_anyofm;
    dispatch[ANYOFD][ANYOFM] = compare_anyof_anyofm;
    dispatch[ANYOFM][ANYOFM] = compare_anyofm_anyofm;
#ifdef RC_NANYOFM
    dispatch[NANYOFM][ANYOFM] = compare_mismatch;
#endif
    dispatch[POSIXD][ANYOFM] = compare_mismatch;
    dispatch[POSIXU][ANYOFM] = compare_mismatch;
    dispatch[POSIXA][ANYOFM] = compare_mismatch;
    dispatch[NPOSIXD][ANYOFM] = compare_mismatch;
    dispatch[NPOSIXU][ANYOFM] = compare_mismatch;
    dispatch[NPOSIXA][ANYOFM] = compare_mismatch;
    dispatch[BRANCH][ANYOFM] = compare_left_branch;
    dispatch[EXACT][ANYOFM] = compare_exact_anyofm;
    dispatch[EXACTF][ANYOFM] = compare_exactf_anyofm;
    dispatch[EXACTFU][ANYOFM] = compare_exactf_anyofm;
    dispatch[NOTHING][ANYOFM] = compare_left_tail;
    dispatch[TAIL][ANYOFM] = compare_left_tail;
    dispatch[STAR][ANYOFM] = compare_mismatch;
    dispatch[PLUS][ANYOFM] = compare_left_plus;
    dispatch[CURLY][ANYOFM] = compare_left_curly;
    dispatch[CURLYM][ANYOFM] = compare_left_curly;
    dispatch[CURLYX][ANYOFM] = compare_left_curly;
    dispatch[OPEN][ANYOFM] = compare_left_open;
    dispatch[CLOSE][ANYOFM] = compare_left_tail;
    dispatch[IFMATCH][ANYOFM] = compare_after_assertion;
    dispatch[UNLESSM][ANYOFM] = compare_after_assertion;
    dispatch[MINMOD][ANYOFM] = compare_left_tail;
    dispatch[LNBREAK][ANYOFM] = compare_mismatch;
    dispatch[OPTIMIZED][ANYOFM] = compare_left_tail;
#endif

#ifdef RC_NANYOFM
    dispatch[SUCCEED][NANYOFM] = compare_left_tail;
    dispatch[MBOL][NANYOFM] = compare_bol;
    dispatch[SBOL][NANYOFM] = compare_bol;
    dispatch[BOUND][NANYOFM] = compare_mismatch;
    dispatch[NBOUND][NANYOFM] = compare_mismatch;
    dispatch[REG_ANY][NANYOFM] = compare_mismatch;
    dispatch[SANY][NANYOFM] = compare_mismatch;
    dispatch[ANYOF][NANYOFM] = compare_anyof_nanyofm;
    dispatch[ANYOFD][NANYOFM] = compare_anyof_nanyofm;
    dispatch[ANYOFM][NANYOFM] = compare_anyofm_nanyofm;
    dispatch[NANYOFM][NANYOFM] = compare_nanyofm_nanyofm;
    dispatch[POSIXD][NANYOFM] = compare_posix_nanyofm;
    dispatch[POSIXU][NANYOFM] = compare_posix_nanyofm;
    dispatch[POSIXA][NANYOFM] = compare_posix_nanyofm;
    dispatch[NPOSIXD][NANYOFM] = compare_negative_posix_nanyofm;
    dispatch[NPOSIXU][NANYOFM] = compare_negative_posix_nanyofm;
    dispatch[NPOSIXA][NANYOFM] = compare_negative_posix_nanyofm;
    dispatch[BRANCH][NANYOFM] = compare_left_branch;
    dispatch[EXACT][NANYOFM] = compare_exact_nanyofm;
    dispatch[EXACTF][NANYOFM] = compare_exactf_nanyofm;
    dispatch[EXACTFU][NANYOFM] = compare_exactf_nanyofm;
    dispatch[NOTHING][NANYOFM] = compare_left_tail;
    dispatch[TAIL][NANYOFM] = compare_left_tail;
    dispatch[STAR][NANYOFM] = compare_mismatch;
    dispatch[PLUS][NANYOFM] = compare_left_plus;
    dispatch[CURLY][NANYOFM] = compare_left_curly;
    dispatch[CURLYM][NANYOFM] = compare_left_curly;
    dispatch[CURLYX][NANYOFM] = compare_left_curly;
    dispatch[OPEN][NANYOFM] = compare_left_open;
    dispatch[CLOSE][NANYOFM] = compare_left_tail;
    dispatch[IFMATCH][NANYOFM] = compare_after_assertion;
    dispatch[UNLESSM][NANYOFM] = compare_after_assertion;
    dispatch[MINMOD][NANYOFM] = compare_left_tail;
    dispatch[LNBREAK][NANYOFM] = compare_mismatch;
    dispatch[OPTIMIZED][NANYOFM] = compare_left_tail;
#endif

    dispatch[SUCCEED][POSIXD] = compare_left_tail;
    dispatch[MBOL][POSIXD] = compare_bol;
    dispatch[SBOL][POSIXD] = compare_bol;
    dispatch[BOUND][POSIXD] = compare_mismatch;
    dispatch[NBOUND][POSIXD] = compare_mismatch;
    dispatch[REG_ANY][POSIXD] = compare_mismatch;
    dispatch[SANY][POSIXD] = compare_mismatch;
    dispatch[ANYOF][POSIXD] = compare_anyof_posix;
    dispatch[ANYOFD][POSIXD] = compare_anyof_posix;
#ifdef RC_ANYOFM
    dispatch[ANYOFM][POSIXD] = compare_anyofm_posix;
#endif
#ifdef RC_NANYOFM
    dispatch[NANYOFM][POSIXD] = compare_nanyofm_posix;
#endif
    dispatch[POSIXD][POSIXD] = compare_posix_posix;
    dispatch[POSIXU][POSIXD] = compare_posix_posix;
    dispatch[POSIXA][POSIXD] = compare_posix_posix;
    dispatch[NPOSIXD][POSIXD] = compare_mismatch;
    dispatch[NPOSIXU][POSIXD] = compare_mismatch;
    dispatch[NPOSIXA][POSIXD] = compare_mismatch;
    dispatch[BRANCH][POSIXD] = compare_left_branch;
    dispatch[EXACT][POSIXD] = compare_exact_posix;
    dispatch[EXACTF][POSIXD] = compare_exactf_posix;
    dispatch[EXACTFU][POSIXD] = compare_exactf_posix;
    dispatch[NOTHING][POSIXD] = compare_left_tail;
    dispatch[STAR][POSIXD] = compare_mismatch;
    dispatch[PLUS][POSIXD] = compare_left_plus;
    dispatch[CURLY][POSIXD] = compare_left_curly;
    dispatch[CURLYM][POSIXD] = compare_left_curly;
    dispatch[CURLYX][POSIXD] = compare_left_curly;
    dispatch[OPEN][POSIXD] = compare_left_open;
    dispatch[CLOSE][POSIXD] = compare_left_tail;
    dispatch[IFMATCH][POSIXD] = compare_after_assertion;
    dispatch[UNLESSM][POSIXD] = compare_after_assertion;
    dispatch[MINMOD][POSIXD] = compare_left_tail;
    dispatch[LNBREAK][POSIXD] = compare_mismatch;
    dispatch[OPTIMIZED][POSIXD] = compare_left_tail;

    dispatch[SUCCEED][POSIXU] = compare_left_tail;
    dispatch[MBOL][POSIXU] = compare_bol;
    dispatch[SBOL][POSIXU] = compare_bol;
    dispatch[BOUND][POSIXU] = compare_mismatch;
    dispatch[NBOUND][POSIXU] = compare_mismatch;
    dispatch[REG_ANY][POSIXU] = compare_mismatch;
    dispatch[SANY][POSIXU] = compare_mismatch;
    dispatch[ANYOF][POSIXU] = compare_anyof_posix;
    dispatch[ANYOFD][POSIXU] = compare_anyof_posix;
#ifdef RC_ANYOFM
    dispatch[ANYOFM][POSIXU] = compare_anyofm_posix;
#endif
#ifdef RC_NANYOFM
    dispatch[NANYOFM][POSIXU] = compare_nanyofm_posix;
#endif
    dispatch[POSIXD][POSIXU] = compare_posix_posix;
    dispatch[POSIXA][POSIXU] = compare_posix_posix;
    dispatch[POSIXU][POSIXU] = compare_posix_posix;
    dispatch[NPOSIXD][POSIXU] = compare_mismatch;
    dispatch[NPOSIXU][POSIXU] = compare_mismatch;
    dispatch[NPOSIXA][POSIXU] = compare_mismatch;
    dispatch[BRANCH][POSIXU] = compare_left_branch;
    dispatch[EXACT][POSIXU] = compare_exact_posix;
    dispatch[EXACTF][POSIXU] = compare_exact_posix;
    dispatch[EXACTFU][POSIXU] = compare_exact_posix;
    dispatch[NOTHING][POSIXU] = compare_left_tail;
    dispatch[TAIL][POSIXU] = compare_left_tail;
    dispatch[STAR][POSIXU] = compare_mismatch;
    dispatch[PLUS][POSIXU] = compare_left_plus;
    dispatch[CURLY][POSIXU] = compare_left_curly;
    dispatch[CURLYM][POSIXU] = compare_left_curly;
    dispatch[CURLYX][POSIXU] = compare_left_curly;
    dispatch[OPEN][POSIXU] = compare_left_open;
    dispatch[CLOSE][POSIXU] = compare_left_tail;
    dispatch[IFMATCH][POSIXU] = compare_after_assertion;
    dispatch[UNLESSM][POSIXU] = compare_after_assertion;
    dispatch[MINMOD][POSIXU] = compare_left_tail;
    dispatch[LNBREAK][POSIXU] = compare_mismatch;
    dispatch[OPTIMIZED][POSIXU] = compare_left_tail;

    dispatch[SUCCEED][POSIXA] = compare_left_tail;
    dispatch[MBOL][POSIXA] = compare_bol;
    dispatch[SBOL][POSIXA] = compare_bol;
    dispatch[BOUND][POSIXA] = compare_mismatch;
    dispatch[NBOUND][POSIXA] = compare_mismatch;
    dispatch[REG_ANY][POSIXA] = compare_mismatch;
    dispatch[SANY][POSIXA] = compare_mismatch;
    dispatch[ANYOF][POSIXA] = compare_anyof_posixa;
    dispatch[ANYOFD][POSIXA] = compare_anyof_posixa;
#ifdef RC_ANYOFM
    dispatch[ANYOFM][POSIXA] = compare_anyofm_posix;
#endif
#ifdef RC_NANYOFM
    dispatch[NANYOFM][POSIXA] = compare_nanyofm_posix;
#endif
    dispatch[POSIXD][POSIXA] = compare_mismatch;
    dispatch[POSIXU][POSIXA] = compare_mismatch;
    dispatch[POSIXA][POSIXA] = compare_posix_posix;
    dispatch[NPOSIXD][POSIXA] = compare_mismatch;
    dispatch[NPOSIXU][POSIXA] = compare_mismatch;
    dispatch[NPOSIXA][POSIXA] = compare_mismatch;
    dispatch[BRANCH][POSIXA] = compare_left_branch;
    dispatch[EXACT][POSIXA] = compare_exact_posix;
    dispatch[EXACTF][POSIXA] = compare_exact_posix;
    dispatch[EXACTFU][POSIXA] = compare_exact_posix;
    dispatch[NOTHING][POSIXA] = compare_left_tail;
    dispatch[STAR][POSIXA] = compare_mismatch;
    dispatch[PLUS][POSIXA] = compare_left_plus;
    dispatch[CURLY][POSIXA] = compare_left_curly;
    dispatch[CURLYM][POSIXA] = compare_left_curly;
    dispatch[CURLYX][POSIXA] = compare_left_curly;
    dispatch[OPEN][POSIXA] = compare_left_open;
    dispatch[CLOSE][POSIXA] = compare_left_tail;
    dispatch[IFMATCH][POSIXA] = compare_after_assertion;
    dispatch[UNLESSM][POSIXA] = compare_after_assertion;
    dispatch[MINMOD][POSIXA] = compare_left_tail;
    dispatch[LNBREAK][POSIXA] = compare_mismatch;
    dispatch[OPTIMIZED][POSIXA] = compare_left_tail;

    dispatch[SUCCEED][NPOSIXD] = compare_left_tail;
    dispatch[MBOL][NPOSIXD] = compare_bol;
    dispatch[SBOL][NPOSIXD] = compare_bol;
    dispatch[BOUND][NPOSIXD] = compare_mismatch;
    dispatch[NBOUND][NPOSIXD] = compare_mismatch;
    dispatch[REG_ANY][NPOSIXD] = compare_mismatch;
    dispatch[SANY][NPOSIXD] = compare_mismatch;
    dispatch[ANYOF][NPOSIXD] = compare_anyof_negative_posix;
    dispatch[ANYOFD][NPOSIXD] = compare_anyof_negative_posix;
#ifdef RC_ANYOFM
    dispatch[ANYOFM][NPOSIXD] = compare_anyofm_negative_posix;
#endif
#ifdef RC_NANYOFM
    dispatch[NANYOFM][NPOSIXD] = compare_nanyofm_negative_posix;
#endif
    dispatch[POSIXD][NPOSIXD] = compare_posix_negative_posix;
    dispatch[POSIXU][NPOSIXD] = compare_posix_negative_posix;
    dispatch[POSIXA][NPOSIXD] = compare_posix_negative_posix;
    dispatch[NPOSIXD][NPOSIXD] = compare_negative_posix_negative_posix;
    dispatch[NPOSIXU][NPOSIXD] = compare_negative_posix_negative_posix;
    dispatch[NPOSIXA][NPOSIXD] = compare_mismatch;
    dispatch[BRANCH][NPOSIXD] = compare_left_branch;
    dispatch[EXACT][NPOSIXD] = compare_exact_negative_posix;
    dispatch[EXACTF][NPOSIXD] = compare_exactf_negative_posix;
    dispatch[EXACTFU][NPOSIXD] = compare_exactf_negative_posix;
    dispatch[NOTHING][NPOSIXD] = compare_left_tail;
    dispatch[STAR][NPOSIXD] = compare_mismatch;
    dispatch[PLUS][NPOSIXD] = compare_left_plus;
    dispatch[CURLY][NPOSIXD] = compare_left_curly;
    dispatch[CURLYM][NPOSIXD] = compare_left_curly;
    dispatch[CURLYX][NPOSIXD] = compare_left_curly;
    dispatch[OPEN][NPOSIXD] = compare_left_open;
    dispatch[CLOSE][NPOSIXD] = compare_left_tail;
    dispatch[IFMATCH][NPOSIXD] = compare_after_assertion;
    dispatch[UNLESSM][NPOSIXD] = compare_after_assertion;
    dispatch[MINMOD][NPOSIXD] = compare_left_tail;
    dispatch[LNBREAK][NPOSIXD] = compare_mismatch;
    dispatch[OPTIMIZED][NPOSIXD] = compare_left_tail;

    dispatch[SUCCEED][NPOSIXU] = compare_left_tail;
    dispatch[MBOL][NPOSIXU] = compare_bol;
    dispatch[SBOL][NPOSIXU] = compare_bol;
    dispatch[BOUND][NPOSIXU] = compare_mismatch;
    dispatch[NBOUND][NPOSIXU] = compare_mismatch;
    dispatch[REG_ANY][NPOSIXU] = compare_mismatch;
    dispatch[SANY][NPOSIXU] = compare_mismatch;
    dispatch[ANYOF][NPOSIXU] = compare_anyof_negative_posix;
    dispatch[ANYOFD][NPOSIXU] = compare_anyof_negative_posix;
#ifdef RC_ANYOFM
    dispatch[ANYOFM][NPOSIXU] = compare_anyofm_negative_posix;
#endif
#ifdef RC_NANYOFM
    dispatch[NANYOFM][NPOSIXU] = compare_nanyofm_negative_posix;
#endif
    dispatch[POSIXD][NPOSIXU] = compare_posix_negative_posix;
    dispatch[POSIXU][NPOSIXU] = compare_posix_negative_posix;
    dispatch[POSIXA][NPOSIXU] = compare_posix_negative_posix;
    dispatch[NPOSIXD][NPOSIXU] = compare_negative_posix_negative_posix;
    dispatch[NPOSIXU][NPOSIXU] = compare_negative_posix_negative_posix;
    dispatch[NPOSIXA][NPOSIXU] = compare_mismatch;
    dispatch[BRANCH][NPOSIXU] = compare_left_branch;
    dispatch[EXACT][NPOSIXU] = compare_exact_negative_posix;
    dispatch[EXACTF][NPOSIXU] = compare_exactf_negative_posix;
    dispatch[EXACTFU][NPOSIXU] = compare_exactf_negative_posix;
    dispatch[NOTHING][NPOSIXU] = compare_left_tail;
    dispatch[STAR][NPOSIXU] = compare_mismatch;
    dispatch[PLUS][NPOSIXU] = compare_left_plus;
    dispatch[CURLY][NPOSIXU] = compare_left_curly;
    dispatch[CURLYM][NPOSIXU] = compare_left_curly;
    dispatch[CURLYX][NPOSIXU] = compare_left_curly;
    dispatch[OPEN][NPOSIXU] = compare_left_open;
    dispatch[CLOSE][NPOSIXU] = compare_left_tail;
    dispatch[IFMATCH][NPOSIXU] = compare_after_assertion;
    dispatch[UNLESSM][NPOSIXU] = compare_after_assertion;
    dispatch[MINMOD][NPOSIXU] = compare_left_tail;
    dispatch[LNBREAK][NPOSIXU] = compare_mismatch;
    dispatch[OPTIMIZED][NPOSIXU] = compare_left_tail;

    dispatch[SUCCEED][NPOSIXA] = compare_left_tail;
    dispatch[MBOL][NPOSIXA] = compare_bol;
    dispatch[SBOL][NPOSIXA] = compare_bol;
    dispatch[BOUND][NPOSIXA] = compare_mismatch;
    dispatch[NBOUND][NPOSIXA] = compare_mismatch;
    dispatch[REG_ANY][NPOSIXA] = compare_mismatch;
    dispatch[SANY][NPOSIXA] = compare_mismatch;
    dispatch[ANYOF][NPOSIXA] = compare_anyof_negative_posix;
    dispatch[ANYOFD][NPOSIXA] = compare_anyof_negative_posix;
#ifdef RC_ANYOFM
    dispatch[ANYOFM][NPOSIXA] = compare_anyofm_negative_posix;
#endif
#ifdef RC_NANYOFM
    dispatch[NANYOFM][NPOSIXA] = compare_nanyofm_negative_posix;
#endif
    dispatch[POSIXD][NPOSIXA] = compare_posix_negative_posix;
    dispatch[POSIXU][NPOSIXA] = compare_posix_negative_posix;
    dispatch[POSIXA][NPOSIXA] = compare_posix_negative_posix;
    dispatch[NPOSIXD][NPOSIXA] = compare_negative_posix_negative_posix;
    dispatch[NPOSIXU][NPOSIXA] = compare_negative_posix_negative_posix;
    dispatch[NPOSIXA][NPOSIXA] = compare_negative_posix_negative_posix;
    dispatch[BRANCH][NPOSIXA] = compare_left_branch;
    dispatch[EXACT][NPOSIXA] = compare_exact_negative_posix;
    dispatch[EXACTF][NPOSIXA] = compare_exactf_negative_posix;
    dispatch[EXACTFU][NPOSIXA] = compare_exactf_negative_posix;
    dispatch[NOTHING][NPOSIXA] = compare_left_tail;
    dispatch[STAR][NPOSIXA] = compare_mismatch;
    dispatch[PLUS][NPOSIXA] = compare_left_plus;
    dispatch[CURLY][NPOSIXA] = compare_left_curly;
    dispatch[CURLYM][NPOSIXA] = compare_left_curly;
    dispatch[CURLYX][NPOSIXA] = compare_left_curly;
    dispatch[OPEN][NPOSIXA] = compare_left_open;
    dispatch[CLOSE][NPOSIXA] = compare_left_tail;
    dispatch[IFMATCH][NPOSIXA] = compare_after_assertion;
    dispatch[UNLESSM][NPOSIXA] = compare_after_assertion;
    dispatch[MINMOD][NPOSIXA] = compare_left_tail;
    dispatch[LNBREAK][NPOSIXA] = compare_mismatch;
    dispatch[OPTIMIZED][NPOSIXA] = compare_left_tail;

    for (i = 0; i < REGNODE_MAX; ++i)
    {
        dispatch[i][BRANCH] = compare_right_branch;
    }

    dispatch[SUCCEED][BRANCH] = compare_left_tail;
    dispatch[ANYOF][BRANCH] = compare_anyof_branch;
    dispatch[ANYOFD][BRANCH] = compare_anyof_branch;
#ifdef RC_ANYOFM
    dispatch[ANYOFM][BRANCH] = compare_anyofm_branch;
#endif
    dispatch[BRANCH][BRANCH] = compare_left_branch;
    dispatch[NOTHING][BRANCH] = compare_left_tail;
    dispatch[TAIL][BRANCH] = compare_left_tail;
    dispatch[WHILEM][BRANCH] = compare_left_tail;
    dispatch[OPEN][BRANCH] = compare_left_open;
    dispatch[CLOSE][BRANCH] = compare_left_tail;
    dispatch[IFMATCH][BRANCH] = compare_after_assertion;
    dispatch[UNLESSM][BRANCH] = compare_after_assertion;
    dispatch[MINMOD][BRANCH] = compare_left_tail;
    dispatch[OPTIMIZED][BRANCH] = compare_left_tail;

    dispatch[SUCCEED][EXACT] = compare_left_tail;
    dispatch[MBOL][EXACT] = compare_bol;
    dispatch[SBOL][EXACT] = compare_bol;
    dispatch[BOUND][EXACT] = compare_mismatch;
    dispatch[NBOUND][EXACT] = compare_mismatch;
    dispatch[REG_ANY][EXACT] = compare_mismatch;
    dispatch[SANY][EXACT] = compare_mismatch;
    dispatch[ANYOF][EXACT] = compare_anyof_exact;
    dispatch[ANYOFD][EXACT] = compare_anyof_exact;
#ifdef RC_ANYOFM
    dispatch[ANYOFM][EXACT] = compare_anyofm_exact;
#endif
#ifdef RC_NANYOFM
    dispatch[NANYOFM][EXACT] = compare_mismatch;
#endif
    dispatch[POSIXD][EXACT] = compare_mismatch;
    dispatch[POSIXU][EXACT] = compare_mismatch;
    dispatch[POSIXA][EXACT] = compare_mismatch;
    dispatch[NPOSIXD][EXACT] = compare_mismatch;
    dispatch[NPOSIXU][EXACT] = compare_mismatch;
    dispatch[NPOSIXA][EXACT] = compare_mismatch;
    dispatch[BRANCH][EXACT] = compare_left_branch;
    dispatch[EXACT][EXACT] = compare_exact_exact;
    dispatch[EXACTF][EXACT] = compare_exactf_exact;
    dispatch[EXACTFU][EXACT] = compare_exactf_exact;
    dispatch[NOTHING][EXACT] = compare_left_tail;
    dispatch[TAIL][EXACT] = compare_left_tail;
    dispatch[STAR][EXACT] = compare_mismatch;
    dispatch[PLUS][EXACT] = compare_left_plus;
    dispatch[CURLY][EXACT] = compare_left_curly;
    dispatch[CURLYM][EXACT] = compare_left_curly;
    dispatch[CURLYX][EXACT] = compare_left_curly;
    dispatch[WHILEM][EXACT] = compare_left_tail;
    dispatch[OPEN][EXACT] = compare_left_open;
    dispatch[CLOSE][EXACT] = compare_left_tail;
    dispatch[IFMATCH][EXACT] = compare_after_assertion;
    dispatch[UNLESSM][EXACT] = compare_after_assertion;
    dispatch[MINMOD][EXACT] = compare_left_tail;
    dispatch[LNBREAK][EXACT] = compare_mismatch;
    dispatch[OPTIMIZED][EXACT] = compare_left_tail;

    dispatch[SUCCEED][EXACTF] = compare_left_tail;
    dispatch[MBOL][EXACTF] = compare_bol;
    dispatch[SBOL][EXACTF] = compare_bol;
    dispatch[BOUND][EXACTF] = compare_mismatch;
    dispatch[NBOUND][EXACTF] = compare_mismatch;
    dispatch[REG_ANY][EXACTF] = compare_mismatch;
    dispatch[SANY][EXACTF] = compare_mismatch;
    dispatch[ANYOF][EXACTF] = compare_anyof_exactf;
    dispatch[ANYOFD][EXACTF] = compare_anyof_exactf;
#ifdef RC_ANYOFM
    dispatch[ANYOFM][EXACTF] = compare_anyofm_exactf;
#endif
#ifdef RC_NANYOFM
    dispatch[NANYOFM][EXACTF] = compare_mismatch;
#endif
    dispatch[POSIXD][EXACTF] = compare_mismatch;
    dispatch[POSIXU][EXACTF] = compare_mismatch;
    dispatch[POSIXA][EXACTF] = compare_mismatch;
    dispatch[NPOSIXD][EXACTF] = compare_mismatch;
    dispatch[NPOSIXU][EXACTF] = compare_mismatch;
    dispatch[NPOSIXA][EXACTF] = compare_mismatch;
    dispatch[BRANCH][EXACTF] = compare_left_branch;
    dispatch[EXACT][EXACTF] = compare_exact_exactf;
    dispatch[EXACTF][EXACTF] = compare_exactf_exactf;
    dispatch[NOTHING][EXACTF] = compare_left_tail;
    dispatch[TAIL][EXACTF] = compare_left_tail;
    dispatch[STAR][EXACTF] = compare_mismatch;
    dispatch[PLUS][EXACTF] = compare_left_plus;
    dispatch[CURLY][EXACTF] = compare_left_curly;
    dispatch[CURLYM][EXACTF] = compare_left_curly;
    dispatch[CURLYX][EXACTF] = compare_left_curly;
    dispatch[WHILEM][EXACTF] = compare_left_tail;
    dispatch[OPEN][EXACTF] = compare_left_open;
    dispatch[CLOSE][EXACTF] = compare_left_tail;
    dispatch[IFMATCH][EXACTF] = compare_after_assertion;
    dispatch[UNLESSM][EXACTF] = compare_after_assertion;
    dispatch[MINMOD][EXACTF] = compare_left_tail;
    dispatch[LNBREAK][EXACTF] = compare_mismatch;
    dispatch[OPTIMIZED][EXACTF] = compare_left_tail;

    dispatch[SUCCEED][EXACTFU] = compare_left_tail;
    dispatch[MBOL][EXACTFU] = compare_bol;
    dispatch[SBOL][EXACTFU] = compare_bol;
    dispatch[BOUND][EXACTFU] = compare_mismatch;
    dispatch[NBOUND][EXACTFU] = compare_mismatch;
    dispatch[REG_ANY][EXACTFU] = compare_mismatch;
    dispatch[SANY][EXACTFU] = compare_mismatch;
    dispatch[ANYOF][EXACTFU] = compare_anyof_exactf;
    dispatch[ANYOFD][EXACTFU] = compare_anyof_exactf;
#ifdef RC_ANYOFM
    dispatch[ANYOFM][EXACTFU] = compare_anyofm_exactf;
#endif
#ifdef RC_NANYOFM
    dispatch[NANYOFM][EXACTFU] = compare_mismatch;
#endif
    dispatch[POSIXD][EXACTFU] = compare_mismatch;
    dispatch[POSIXU][EXACTFU] = compare_mismatch;
    dispatch[POSIXA][EXACTFU] = compare_mismatch;
    dispatch[NPOSIXD][EXACTFU] = compare_mismatch;
    dispatch[NPOSIXU][EXACTFU] = compare_mismatch;
    dispatch[NPOSIXA][EXACTFU] = compare_mismatch;
    dispatch[BRANCH][EXACTFU] = compare_left_branch;
    dispatch[EXACT][EXACTFU] = compare_exact_exactf;
    dispatch[EXACTF][EXACTFU] = compare_exactf_exactf;
    dispatch[EXACTFU][EXACTFU] = compare_exactf_exactf;
    dispatch[NOTHING][EXACTFU] = compare_left_tail;
    dispatch[STAR][EXACTFU] = compare_mismatch;
    dispatch[PLUS][EXACTFU] = compare_left_plus;
    dispatch[CURLY][EXACTFU] = compare_left_curly;
    dispatch[CURLYM][EXACTFU] = compare_left_curly;
    dispatch[CURLYX][EXACTFU] = compare_left_curly;
    dispatch[OPEN][EXACTFU] = compare_left_open;
    dispatch[CLOSE][EXACTFU] = compare_left_tail;
    dispatch[IFMATCH][EXACTFU] = compare_after_assertion;
    dispatch[UNLESSM][EXACTFU] = compare_after_assertion;
    dispatch[MINMOD][EXACTFU] = compare_left_tail;
    dispatch[LNBREAK][EXACTFU] = compare_mismatch;
    dispatch[OPTIMIZED][EXACTFU] = compare_left_tail;

#ifdef RC_EXACT_ONLY8
    dispatch[EXACT_ONLY8][EXACT_ONLY8] = compare_exact_exact;
#endif

    for (i = 0; i < REGNODE_MAX; ++i)
    {
        dispatch[i][NOTHING] = compare_next;
    }

    dispatch[SUCCEED][NOTHING] = compare_tails;
    dispatch[NOTHING][NOTHING] = compare_tails;
    dispatch[TAIL][NOTHING] = compare_tails;
    dispatch[WHILEM][NOTHING] = compare_tails;
    dispatch[CLOSE][NOTHING] = compare_tails;
    dispatch[MINMOD][NOTHING] = compare_tails;
    dispatch[OPTIMIZED][NOTHING] = compare_tails;

    for (i = 0; i < REGNODE_MAX; ++i)
    {
        dispatch[i][TAIL] = compare_next;
    }

    dispatch[SUCCEED][TAIL] = compare_tails;
    dispatch[NOTHING][TAIL] = compare_tails;
    dispatch[TAIL][TAIL] = compare_tails;
    dispatch[WHILEM][TAIL] = compare_tails;
    dispatch[CLOSE][TAIL] = compare_tails;
    dispatch[MINMOD][TAIL] = compare_tails;
    dispatch[OPTIMIZED][TAIL] = compare_tails;

    for (i = 0; i < REGNODE_MAX; ++i)
    {
        dispatch[i][STAR] = compare_right_star;
    }

    dispatch[SUCCEED][STAR] = compare_left_tail;
    dispatch[EOS][STAR] = compare_tails;
    dispatch[EOL][STAR] = compare_tails;
    dispatch[MEOL][STAR] = compare_tails;
    dispatch[SEOL][STAR] = compare_tails;
    dispatch[NOTHING][STAR] = compare_left_tail;
    dispatch[TAIL][STAR] = compare_left_tail;
    dispatch[STAR][STAR] = compare_repeat_star;
    dispatch[PLUS][STAR] = compare_repeat_star;
    dispatch[CURLY][STAR] = compare_curly_star;
    dispatch[CURLYM][STAR] = compare_curly_star;
    dispatch[CURLYX][STAR] = compare_curly_star;
    dispatch[WHILEM][STAR] = compare_left_tail;
    dispatch[OPEN][STAR] = compare_left_open;
    dispatch[CLOSE][STAR] = compare_left_tail;
    dispatch[IFMATCH][STAR] = compare_after_assertion;
    dispatch[UNLESSM][STAR] = compare_after_assertion;
    dispatch[MINMOD][STAR] = compare_left_tail;
    dispatch[OPTIMIZED][STAR] = compare_left_tail;

    for (i = 0; i < REGNODE_MAX; ++i)
    {
        dispatch[i][PLUS] = compare_right_plus;
    }

    dispatch[SUCCEED][PLUS] = compare_left_tail;
    dispatch[NOTHING][PLUS] = compare_left_tail;
    dispatch[TAIL][PLUS] = compare_left_tail;
    dispatch[PLUS][PLUS] = compare_plus_plus;
    dispatch[CURLY][PLUS] = compare_curly_plus;
    dispatch[CURLYM][PLUS] = compare_curly_plus;
    dispatch[CURLYX][PLUS] = compare_curly_plus;
    dispatch[WHILEM][PLUS] = compare_left_tail;
    dispatch[OPEN][PLUS] = compare_left_open;
    dispatch[CLOSE][PLUS] = compare_left_tail;
    dispatch[IFMATCH][PLUS] = compare_after_assertion;
    dispatch[UNLESSM][PLUS] = compare_after_assertion;
    dispatch[MINMOD][PLUS] = compare_left_tail;
    dispatch[OPTIMIZED][PLUS] = compare_left_tail;

    for (i = 0; i < REGNODE_MAX; ++i)
    {
        dispatch[i][CURLY] = compare_right_curly;
    }

    dispatch[SUCCEED][CURLY] = compare_left_tail;
    dispatch[NOTHING][CURLY] = compare_left_tail;
    dispatch[TAIL][CURLY] = compare_left_tail;
    dispatch[PLUS][CURLY] = compare_plus_curly;
    dispatch[CURLY][CURLY] = compare_curly_curly;
    dispatch[CURLYM][CURLY] = compare_curly_curly;
    dispatch[CURLYX][CURLY] = compare_curly_curly;
    dispatch[WHILEM][CURLY] = compare_left_tail;
    dispatch[OPEN][CURLY] = compare_left_open;
    dispatch[CLOSE][CURLY] = compare_left_tail;
    dispatch[IFMATCH][CURLY] = compare_after_assertion;
    dispatch[UNLESSM][CURLY] = compare_after_assertion;
    dispatch[SUSPEND][CURLY] = compare_suspend_curly;
    dispatch[MINMOD][CURLY] = compare_left_tail;
    dispatch[OPTIMIZED][CURLY] = compare_left_tail;

    for (i = 0; i < REGNODE_MAX; ++i)
    {
        dispatch[i][CURLYM] = compare_right_curly;
    }

    dispatch[SUCCEED][CURLYM] = compare_left_tail;
    dispatch[NOTHING][CURLYM] = compare_left_tail;
    dispatch[TAIL][CURLYM] = compare_left_tail;
    dispatch[PLUS][CURLYM] = compare_plus_curly;
    dispatch[CURLY][CURLYM] = compare_curly_curly;
    dispatch[CURLYM][CURLYM] = compare_curly_curly;
    dispatch[CURLYX][CURLYM] = compare_curly_curly;
    dispatch[WHILEM][CURLYM] = compare_left_tail;
    dispatch[OPEN][CURLYM] = compare_left_open;
    dispatch[CLOSE][CURLYM] = compare_left_tail;
    dispatch[IFMATCH][CURLYM] = compare_after_assertion;
    dispatch[UNLESSM][CURLYM] = compare_after_assertion;
    dispatch[SUSPEND][CURLYM] = compare_suspend_curly;
    dispatch[MINMOD][CURLYM] = compare_left_tail;
    dispatch[OPTIMIZED][CURLYM] = compare_left_tail;

    for (i = 0; i < REGNODE_MAX; ++i)
    {
        dispatch[i][CURLYX] = compare_right_curly;
    }

    dispatch[SUCCEED][CURLYX] = compare_left_tail;
    dispatch[NOTHING][CURLYX] = compare_left_tail;
    dispatch[TAIL][CURLYX] = compare_left_tail;
    dispatch[PLUS][CURLYX] = compare_plus_curly;
    dispatch[CURLY][CURLYX] = compare_curly_curly;
    dispatch[CURLYM][CURLYX] = compare_curly_curly;
    dispatch[CURLYX][CURLYX] = compare_curly_curly;
    dispatch[WHILEM][CURLYX] = compare_left_tail;
    dispatch[OPEN][CURLYX] = compare_left_open;
    dispatch[CLOSE][CURLYX] = compare_left_tail;
    dispatch[IFMATCH][CURLYX] = compare_after_assertion;
    dispatch[UNLESSM][CURLYX] = compare_after_assertion;
    dispatch[SUSPEND][CURLYX] = compare_suspend_curly;
    dispatch[MINMOD][CURLYX] = compare_left_tail;
    dispatch[OPTIMIZED][CURLYX] = compare_left_tail;

    for (i = 0; i < REGNODE_MAX; ++i)
    {
        dispatch[i][WHILEM] = compare_next;
    }

    dispatch[SUCCEED][WHILEM] = compare_tails;
    dispatch[NOTHING][WHILEM] = compare_tails;
    dispatch[TAIL][WHILEM] = compare_tails;
    dispatch[WHILEM][WHILEM] = compare_tails;
    dispatch[CLOSE][WHILEM] = compare_tails;
    dispatch[MINMOD][WHILEM] = compare_tails;
    dispatch[OPTIMIZED][WHILEM] = compare_tails;

    for (i = 0; i < REGNODE_MAX; ++i)
    {
        dispatch[i][OPEN] = compare_right_open;
    }

    dispatch[OPEN][OPEN] = compare_open_open;

    for (i = 0; i < REGNODE_MAX; ++i)
    {
        dispatch[i][CLOSE] = compare_next;
    }

    dispatch[SUCCEED][CLOSE] = compare_tails;
    dispatch[NOTHING][CLOSE] = compare_tails;
    dispatch[TAIL][CLOSE] = compare_tails;
    dispatch[WHILEM][CLOSE] = compare_tails;
    dispatch[CLOSE][CLOSE] = compare_tails;
    dispatch[MINMOD][CLOSE] = compare_tails;
    dispatch[OPTIMIZED][CLOSE] = compare_tails;

    dispatch[SUCCEED][IFMATCH] = compare_left_tail;
    dispatch[MBOL][IFMATCH] = compare_bol;
    dispatch[SBOL][IFMATCH] = compare_bol;
    dispatch[BOUND][IFMATCH] = compare_mismatch;
    dispatch[NBOUND][IFMATCH] = compare_mismatch;
    dispatch[REG_ANY][IFMATCH] = compare_mismatch;
    dispatch[SANY][IFMATCH] = compare_mismatch;
    dispatch[ANYOF][IFMATCH] = compare_mismatch;
    dispatch[ANYOFD][IFMATCH] = compare_mismatch;
#ifdef RC_ANYOFM
    dispatch[ANYOFM][IFMATCH] = compare_mismatch;
#endif
#ifdef RC_NANYOFM
    dispatch[NANYOFM][IFMATCH] = compare_mismatch;
#endif
    dispatch[POSIXD][IFMATCH] = compare_mismatch;
    dispatch[POSIXU][IFMATCH] = compare_mismatch;
    dispatch[POSIXA][IFMATCH] = compare_mismatch;
    dispatch[NPOSIXD][IFMATCH] = compare_mismatch;
    dispatch[NPOSIXU][IFMATCH] = compare_mismatch;
    dispatch[NPOSIXA][IFMATCH] = compare_mismatch;
    dispatch[BRANCH][IFMATCH] = compare_mismatch;
    dispatch[EXACT][IFMATCH] = compare_mismatch;
    dispatch[EXACTF][IFMATCH] = compare_mismatch;
    dispatch[EXACTFU][IFMATCH] = compare_mismatch;
    dispatch[NOTHING][IFMATCH] = compare_left_tail;
    dispatch[TAIL][IFMATCH] = compare_left_tail;
    dispatch[STAR][IFMATCH] = compare_mismatch;
    dispatch[PLUS][IFMATCH] = compare_mismatch;
    dispatch[CURLY][IFMATCH] = compare_mismatch;
    dispatch[CURLYM][IFMATCH] = compare_mismatch;
    dispatch[CURLYX][IFMATCH] = compare_mismatch;
    dispatch[WHILEM][IFMATCH] = compare_left_tail;
    dispatch[OPEN][IFMATCH] = compare_left_open;
    dispatch[CLOSE][IFMATCH] = compare_left_tail;
    dispatch[IFMATCH][IFMATCH] = compare_positive_assertions;
    dispatch[UNLESSM][IFMATCH] = compare_mismatch;
    dispatch[MINMOD][IFMATCH] = compare_left_tail;
    dispatch[LNBREAK][IFMATCH] = compare_mismatch;
    dispatch[OPTIMIZED][IFMATCH] = compare_left_tail;

    dispatch[SUCCEED][UNLESSM] = compare_left_tail;
    dispatch[MBOL][UNLESSM] = compare_bol;
    dispatch[SBOL][UNLESSM] = compare_bol;
    dispatch[BOUND][UNLESSM] = compare_mismatch;
    dispatch[NBOUND][UNLESSM] = compare_mismatch;
    dispatch[REG_ANY][UNLESSM] = compare_mismatch;
    dispatch[SANY][UNLESSM] = compare_mismatch;
    dispatch[ANYOF][UNLESSM] = compare_mismatch;
    dispatch[ANYOFD][UNLESSM] = compare_mismatch;
#ifdef RC_ANYOFM
    dispatch[ANYOFM][UNLESSM] = compare_mismatch;
#endif
#ifdef RC_NANYOFM
    dispatch[NANYOFM][UNLESSM] = compare_mismatch;
#endif
    dispatch[POSIXD][UNLESSM] = compare_mismatch;
    dispatch[POSIXU][UNLESSM] = compare_mismatch;
    dispatch[POSIXA][UNLESSM] = compare_mismatch;
    dispatch[NPOSIXD][UNLESSM] = compare_mismatch;
    dispatch[NPOSIXU][UNLESSM] = compare_mismatch;
    dispatch[NPOSIXA][UNLESSM] = compare_mismatch;
    dispatch[BRANCH][UNLESSM] = compare_mismatch;
    dispatch[EXACT][UNLESSM] = compare_mismatch;
    dispatch[EXACTF][UNLESSM] = compare_mismatch;
    dispatch[EXACTFU][UNLESSM] = compare_mismatch;
    dispatch[NOTHING][UNLESSM] = compare_left_tail;
    dispatch[TAIL][UNLESSM] = compare_left_tail;
    dispatch[STAR][UNLESSM] = compare_mismatch;
    dispatch[PLUS][UNLESSM] = compare_mismatch;
    dispatch[CURLY][UNLESSM] = compare_mismatch;
    dispatch[CURLYM][UNLESSM] = compare_mismatch;
    dispatch[CURLYX][UNLESSM] = compare_mismatch;
    dispatch[WHILEM][UNLESSM] = compare_left_tail;
    dispatch[OPEN][UNLESSM] = compare_left_open;
    dispatch[CLOSE][UNLESSM] = compare_left_tail;
    dispatch[IFMATCH][UNLESSM] = compare_mismatch;
    dispatch[UNLESSM][UNLESSM] = compare_negative_assertions;
    dispatch[MINMOD][UNLESSM] = compare_left_tail;
    dispatch[LNBREAK][UNLESSM] = compare_mismatch;
    dispatch[OPTIMIZED][UNLESSM] = compare_left_tail;

    dispatch[SUSPEND][SUSPEND] = compare_subexpressions;

    for (i = 0; i < REGNODE_MAX; ++i)
    {
        dispatch[i][MINMOD] = compare_next;
    }

    dispatch[SUCCEED][MINMOD] = compare_tails;
    dispatch[NOTHING][MINMOD] = compare_tails;
    dispatch[TAIL][MINMOD] = compare_tails;
    dispatch[WHILEM][MINMOD] = compare_tails;
    dispatch[CLOSE][MINMOD] = compare_tails;
    dispatch[MINMOD][MINMOD] = compare_tails;
    dispatch[OPTIMIZED][MINMOD] = compare_tails;

    dispatch[SUCCEED][LNBREAK] = compare_left_tail;
    dispatch[SBOL][LNBREAK] = compare_bol;
    dispatch[MBOL][LNBREAK] = compare_bol;
    dispatch[BOUND][LNBREAK] = compare_mismatch;
    dispatch[NBOUND][LNBREAK] = compare_mismatch;
    dispatch[REG_ANY][LNBREAK] = compare_mismatch;
    dispatch[SANY][LNBREAK] = compare_mismatch;
    dispatch[ANYOF][LNBREAK] = compare_anyof_lnbreak;
    dispatch[ANYOFD][LNBREAK] = compare_anyof_lnbreak;
#ifdef RC_ANYOFM
    dispatch[ANYOFM][LNBREAK] = compare_mismatch;
#endif
#ifdef RC_NANYOFM
    dispatch[NANYOFM][LNBREAK] = compare_mismatch;
#endif
    dispatch[POSIXD][LNBREAK] = compare_posix_lnbreak;
    dispatch[POSIXU][LNBREAK] = compare_posix_lnbreak;
    dispatch[POSIXA][LNBREAK] = compare_posix_lnbreak;
    dispatch[NPOSIXD][LNBREAK] = compare_mismatch;
    dispatch[NPOSIXU][LNBREAK] = compare_mismatch;
    dispatch[NPOSIXA][LNBREAK] = compare_mismatch;
    dispatch[BRANCH][LNBREAK] = compare_left_branch;
    dispatch[EXACT][LNBREAK] = compare_exact_lnbreak;
    dispatch[EXACTFU][LNBREAK] = compare_exact_lnbreak;
    dispatch[NOTHING][LNBREAK] = compare_left_tail;
    dispatch[TAIL][LNBREAK] = compare_left_tail;
    dispatch[STAR][LNBREAK] = compare_mismatch;
    dispatch[PLUS][LNBREAK] = compare_left_plus;
    dispatch[CURLY][LNBREAK] = compare_left_curly;
    dispatch[CURLYM][LNBREAK] = compare_left_curly;
    dispatch[CURLYX][LNBREAK] = compare_left_curly;
    dispatch[WHILEM][LNBREAK] = compare_left_tail;
    dispatch[OPEN][LNBREAK] = compare_left_open;
    dispatch[CLOSE][LNBREAK] = compare_left_tail;
    dispatch[IFMATCH][LNBREAK] = compare_after_assertion;
    dispatch[UNLESSM][LNBREAK] = compare_after_assertion;
    dispatch[MINMOD][LNBREAK] = compare_left_tail;
    dispatch[LNBREAK][LNBREAK] = compare_tails;

    for (i = 0; i < REGNODE_MAX; ++i)
    {
        dispatch[i][OPTIMIZED] = compare_next;
    }

    dispatch[SUCCEED][OPTIMIZED] = compare_tails;
    dispatch[NOTHING][OPTIMIZED] = compare_tails;
    dispatch[TAIL][OPTIMIZED] = compare_tails;
    dispatch[WHILEM][OPTIMIZED] = compare_tails;
    dispatch[CLOSE][OPTIMIZED] = compare_tails;
    dispatch[MINMOD][OPTIMIZED] = compare_tails;
    dispatch[OPTIMIZED][OPTIMIZED] = compare_tails;
}
