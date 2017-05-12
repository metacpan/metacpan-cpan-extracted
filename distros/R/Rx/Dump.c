#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "regcomp.h"
#include "regarglen.h"
#include <stdio.h>
#include <ctype.h>
#include "Dump.h"

#ifndef MJD_DB
#define MJD_DB 0
#endif
#if MJD_DB
#define DEBUG_printf(x) printf x
#else
#define DEBUG_printf(x) 
#endif

#define NEXTNODE(n) ((regnode *)((char *)((n)+1) + regtype_arglen[regtype_arg[(n)->type]]))

RXCALLBACK the_callback;
unsigned let_finish_naturally = 0;


char *labels[] = { "id", "$`", "$&", "$'" };
#define N_LABELS (sizeof(labels)/sizeof(*labels))

unsigned 
test_callback(unsigned id, AV *items)
{
  I32 len, i;
  printf("Test callback called for instrument #%u.\n", id);
  
  len = av_len(items);
  if (len == -1) {
    printf("Items array is empty.\n");
    return 1;
  }

  for (i=0; i<=len; i++) {
    char buf[6], *label;
    SV** item = av_fetch(items, i, 0);
    if (i >= N_LABELS) {
      label = buf;
      sprintf(label, "$%d", i+1-N_LABELS);
    } else {
      label = labels[i];
    }
    printf(" %s : ", label);
    if (item)
      printf("%s \n", SvPV_nolen(*item));
    else 
      printf("none defined\n");
  }
  return 0;
}
        
SV *
instrument(char *regex_string, char *options, SV *offsets)
{
  PMOP *pm = _options_to_pm(options);
  SV *dumped_regex = dump_regex(regex_string, pm);
  SV * annotated_regex;
  I32 subr_flags = G_SCALAR, retval_count;
  int rc;

  dSP;

  Safefree(pm);
  PUSHMARK(SP);
  XPUSHs(dumped_regex);
  PUTBACK;
  retval_count = call_pv("Rx::_add_instruments", subr_flags);
  SPAGAIN ;
  if (retval_count != 1) croak("Bad return from _add_instruments");
  annotated_regex = POPs;
  rc = SvREFCNT(dumped_regex);
  DEBUG_printf(("Refcount on dumped_regex value is %d.\n", rc));
  PUTBACK;

  PUSHMARK(SP);
  XPUSHs(newSVpv(regex_string, 0));
  XPUSHs(annotated_regex);
  XPUSHs(newSViv(0));
  XPUSHs(newSVpv(options, 0));
  if (offsets) {
      XPUSHs(newSViv(0));
      XPUSHs(offsets);
  }
  PUTBACK;

  return annotated_regex;
}

void
start(SV *rhrx, SV *target, RXCALLBACK callback)
{
  const char *bytecode;
  SV *bytecodeSV, *num_instrumentsSV;
  OP *match = _locate_match_op("Rx::do_match");
  REGEXP * rx;
  HV *hrx;
  unsigned retval_count, num_instruments;

  STRLEN bytecode_len;
  dSP;

  let_finish_naturally = 0;

  PUSHMARK(SP);
  XPUSHs(rhrx);
  PUTBACK;
  retval_count = call_pv("Rx::undump", G_ARRAY);
  SPAGAIN ;
  if (retval_count != 2) croak("Wrong number of return values from Rx::undump");
  num_instrumentsSV = POPs;
  num_instruments = SvIV(num_instrumentsSV);
  DEBUG_printf(("start: num_instruments = %u.\n", num_instruments));
  bytecodeSV = POPs;
  bytecode = SvPV(bytecodeSV, bytecode_len) ;

  PUTBACK;

#if MJD_DB
  {
    unsigned i;
    unsigned n = 0;
    unsigned char *bcp = (unsigned char *)bytecode;
    for (i=0; i<bytecode_len; i++) {
      if (n%4==0) printf("%6d  ", n);
      printf("%4u ", (unsigned)(bcp[i]));
      if (++n % 4 == 0) putchar('\n');
    }
    putchar('\n');
  }
#endif

  hrx = (HV *)SvRV(rhrx); 

  if ((rx = safemalloc(sizeof(REGEXP) + bytecode_len)) == 0) {
    croak("Couldn't allocaate space for struct regexp in start");
  }
  memcpy(rx->program, bytecode, bytecode_len);
  rx->startp = (I32 *)SvIV(*hv_fetch(hrx, "__startp", 8, 0));
  rx->endp   = (I32 *)SvIV(*hv_fetch(hrx, "__endp",   6, 0));
  DEBUG_printf(("out startp/endp: %d %d\n", rx->startp, rx->endp));
  { 
    SV** subbeg = hv_fetch(hrx, "__subbeg",    8, 0);
    if (subbeg) rx->subbeg    = SvPV_nolen(*subbeg);
  }
  rx->sublen    = SvIV(*hv_fetch(hrx, "__sublen",    8, 0));
  rx->refcnt    = SvIV(*hv_fetch(hrx, "__refcnt",    8, 0));
  rx->minlen    = SvIV(*hv_fetch(hrx, "__minlen",    8, 0));
  rx->minlen    = 0;            /* Disable minlen optimization */
  rx->prelen    = SvIV(*hv_fetch(hrx, "__prelen",    8, 0));
  rx->nparens   = SvIV(*hv_fetch(hrx, "__nparens",   9, 0));
  rx->lastparen = SvIV(*hv_fetch(hrx, "__lastparen",11, 0));
  rx->reganch   = (SvIV(*hv_fetch(hrx, "__reganch",   9, 0)) 
                    & ~RE_USE_INTUIT) 
                  | ROPT_EVAL_SEEN;
  rx->substrs   = SvPV_nolen(*hv_fetch(hrx, "__substrs",   9, 0));
  rx->precomp   = SvPV_nolen(*hv_fetch(hrx, "REGEX", 5, 0));
  rx->regstclass= 0;            /* XXX? */

  /* This installs the instruments themselves.  Each is a tiny perl
     code that calls _xs_callback_glue with the appropriate argument.
     They are pointed to by the 'args' parts of the instruments' regex
     nodes.
  */
  { 
    struct reg_data *regdata = 
      (struct reg_data *)safemalloc(sizeof(struct reg_data)
                                    + num_instruments * 3 * sizeof(void *));
    rx->data = regdata;

    regdata->count = 3*num_instruments;
    /* regdata->what = ??? */
    {
      unsigned i;
      for (i=0; i<num_instruments; i++) {
        char call_glue_code[42];       /* code below + 10 digits */
        OP *sop, *rop;
        AV *pad;
        SV *code_SV;
        
        sprintf(call_glue_code, "Rx::_xs_callback_glue(%d)", i);
        /*        sprintf(call_glue_code, "print \"In callback $-[0]/$+[0] ]]\\n\"", i);
         */
        code_SV = newSVpv(call_glue_code, 0);
        
        rop = sv_compile_2op(code_SV, &sop, "callback glue", &pad);
      
        regdata->data[3*i+0] = (void *)rop;
        regdata->data[3*i+1] = (void *)sop;
        regdata->data[3*i+2] = (void *)pad;
        SvREFCNT_dec(code_SV);
      }
    }
  }

  match = _locate_match_op("Rx::do_match");
  if (match == 0) croak("Couldn't locate match op in do_match");
  DEBUG_printf(("match PMOP = %#x\n", (unsigned)match));

  /* Install new regex into match node in do_match function */
  ((PMOP *)match)->op_pmregexp = rx;

  /* install callback function */
  the_callback = callback;

  /* upgrade target to magical (so it can hold pos() information */
  sv_magic(target, (SV*)0 , 'g', Nullch, 0);
  PL_reg_magic = mg_find(target, 'g');
  
  PUSHMARK(SP);
  XPUSHs(target);
  PUTBACK;
  (void) call_pv("Rx::do_match", G_SCALAR);
  SPAGAIN ;
  PUTBACK;
}
        
PMOP *
_options_to_pm(const char *options)
{
  PMOP *pm;

  Newz(1, pm, 1, PMOP);
  if (pm == 0) croak("Couldn't allocate memory for PMOP");

  if (options == 0) return pm;

  /* pm needs only the following fields populated for use by pregcomp:
   *  op_pmdynflags
   *  op_pmflags
   */
  for ( ; *options; options++) {
    switch (*options) {
    case 'm':
      pm->op_pmflags |= PMf_MULTILINE;
      break;
    case 's':
      pm->op_pmflags |= PMf_SINGLELINE;
      break;
    case 'o':
      pm->op_pmflags |= PMf_KEEP;
      break;
    case 'i':
      pm->op_pmflags |= PMf_FOLD;
      break;
    case 'x':
      pm->op_pmflags |= PMf_EXTENDED;
      break;
    case 'g':
      pm->op_pmflags |= PMf_GLOBAL;
      break;
    case '\'':
      /* no-op */
      break;
    case '\x0c':                /* Conrol-L */
      pm->op_pmflags |= PMf_LOCALE;
      break;
    case '\x15':                /* Control-U */
      pm->op_pmdynflags |= PMdf_UTF8;
      break;
    default:
      if (isascii(*options) && isprint(*options)) {
        croak("Unrecognized regex option character '%c'", *options);
      } else {
        croak("Unrecognized regex option character #%#x", *options);
      }
    }
  }
  return pm;
}

SV *
dump_regex(const char *regex_string, PMOP *pm) 
{
  regexp *compiled_regex;
  char *xend;
  xend = strchr(regex_string, '\0');

  if (xend == 0 || pm == 0) 
    croak("xend or pm is null; bagging out.\n");

  { /* This block tricks the regex engine into suppressing 
     * the abort that normally follows an attempt to do 
     * runtime compilation of a regex with (?{CODE}) nodes.
     *
     * The trick is a horrible hack:  PL_reginterp_cnt is the 
     * variable that says how many such nodes were in the static
     * part of the regex; pregcomp counts the total number
     * of (?{CODE}) nodes and aborts if this total exceeds
     * PL_reginterp_cnt.  To prevent the abort, we temporarily
     * set PL_reginterp_cnt to a very large number.
     *
     * Don't blame me; that's how "use re 'eval'" works also.
     */
    int save_PL_reginterp_cnt = PL_reginterp_cnt;
    PL_reginterp_cnt = I32_MAX;
    compiled_regex = pregcomp((char *)regex_string, xend, pm);
    PL_reginterp_cnt = save_PL_reginterp_cnt;
  }

  return dump_compiled_regex(compiled_regex);
}
		

/* Dump offset data from compiled regex to array.  Return arrayref. */
void
dump_offset_data(regexp *rx, SV **off_r, SV **len_r) 
{
  U32 *offsets = rx->offsets;
  U32 n_nodes = *offsets;
  AV *off = newAV(), *len = newAV();
  U32 i;

  if (!off_r && !len_r) return;
  if (off_r) *off_r = newRV_noinc((SV *)off);
  if (len_r) *len_r = newRV_noinc((SV *)len);

  for (i=1; i <= n_nodes; i++) {
    U32 node_offset = offsets[i*2-1];
    U32 node_length = offsets[i*2];
    SV *node_offset_sv,  *node_length_sv;

    if (node_offset == 0) {
      /*      node_offset_sv = node_length_sv = &PL_sv_undef; */
      node_offset_sv = newSVsv(&PL_sv_undef);
      node_length_sv = newSVsv(&PL_sv_undef);
    } else {
      node_offset_sv = newSViv(node_offset);
      node_length_sv = newSViv(node_length);
    }

    if (off_r) av_store(off, i-1, node_offset_sv);
    if (len_r) av_store(len, i-1, node_length_sv);
  }
}

/* Dump compiled regex to hash.  Return hashref. */
SV *
dump_compiled_regex(regexp *rx)
{
  HV *hash = newHV();
  SV *hashref = newRV_noinc((SV *)hash);
  unsigned final_offset;
  int magic = *(unsigned char *)(rx->program);
  if (magic != REG_MAGIC) {
    /* BUG - handle error condition properly here */
    printf("  Regex has bad magic number %d (s/b %d)\n", magic, REG_MAGIC);
    return 0;
  }
  final_offset = _partial_dump_regex(rx->program +1, rx->program +1, hash);

  hv_store(hash, "REGEX", 5, newSVpv(rx->precomp, 0), 0);

  DEBUG_printf(("in startp/endp: %d %d\n", rx->startp, rx->endp));
  hv_store(hash, "__startp",    8, newSViv((I32)rx->startp), 0);
  hv_store(hash, "__endp",      6, newSViv((I32)rx->endp), 0);
  if (rx->subbeg)
    hv_store(hash, "__subbeg",    8, newSVpv(rx->subbeg, 0), 0);
  hv_store(hash, "__sublen",    8, newSViv( rx->sublen), 0);
  hv_store(hash, "__refcnt",    8, newSViv( rx->refcnt), 0); /* XXX */
  hv_store(hash, "__minlen",    8, newSViv( rx->minlen), 0);
  hv_store(hash, "__prelen",    8, newSViv( rx->prelen), 0);
  hv_store(hash, "__nparens",   9, newSViv( rx->nparens), 0);
  hv_store(hash, "__lastparen",11, newSViv( rx->lastparen), 0);
  hv_store(hash, "__reganch",   9, newSViv( rx->reganch), 0);
  hv_store(hash, "__substrs",   9, newSVpv( rx->substrs, sizeof(*rx->substrs)), 0);

  /* Gather and store offset data */
  {
    SV *off = newSVsv(&PL_sv_undef),
       *len = newSVsv(&PL_sv_undef)
      ;
    dump_offset_data(rx, &off, &len);
    hv_store(hash, "OFFSETS",   7, off, 0 );
    hv_store(hash, "LENGTHS",   7, len, 0 );
  }

  return hashref;
}

/* Internal use only: Convert compiled regex into hash, storing
 * results into argument hv.  `base' is the beginning node of the
 * regex.  Starts converting at node n, continues until it gets to a
 * 'final node' with end marker.  These end markers occur at the end
 * of the main regex and also at the end of any nested regexes in
 * (?(...)R1|R2), (?>R), (?=R), (?!R), etc.
 *
 * You should probably be calling dump_compiled_regex instead.  
 */
unsigned
_partial_dump_regex(regnode *n, regnode *base, HV *result) 
{
  for (;;) {
    int offset = n - base;
    U8 type = n->type;
    U8 flags = n->flags;
    U16 next_off = n->next_off;
    int argtype = regtype_arg[type], arglen = regtype_arglen[argtype];
    regnode *branch = (regnode *)((char *)(n+1) + arglen);
    HV *node = newHV();
    SV *noderef = newRV_noinc((SV *)node);

    if (node == 0 || noderef == 0) {
      croak("Out of memory in _partial_dump_regex");
    }

    hv_store(node, "TYPE", 4, newSVpv(reg_name[type], 0), 0);
    hv_store(node, "TYPEn", 5,newSViv(type), 0);
    hv_store(node, "FLAGS", 5, newSViv(flags), 0);
    if (argtype) {
      hv_store(node, "ARGS", 4, regargSV(argtype, (char *)(n+1)), 0);
    }
    if (next_off) hv_store(node, "NEXT", 4,  newSViv(next_off+n-base), 0);

    { /* This section computes the byte offset into the compiled regex
         bytecode and stores the new node there */
      char offkey[24];          /* String version of byte offset */
      sprintf(offkey, "%d", offset); 
      if (hv_fetch(result, offkey, strlen(offkey), 0))
        goto CONTINUE;

      hv_store(result, offkey, strlen(offkey), noderef, 0);
/* This stuff probably isn't necessary
      hv_store(result, "MAX_OFFSET", 10, newSViv(offset), 0);
*/
    }

    switch (type) {
    case BRANCH:
    case BRANCHJ:
    case STAR:
    case PLUS:
    case CURLY:
    case CURLYM:
    case CURLYN:
    case CURLYX:
      _partial_dump_regex(branch, base, result);
      hv_store(node, "CHILD", 5, newSVpvf("%d", branch-base), 0);
      break;
      
    case SUCCEED:
      _partial_dump_regex(branch, base, result);
      hv_store(node, "NEXT", 4, newSVpvf("%d", branch-base), 0);
      break;

    case EXACT:
    case EXACTF:
    case EXACTFL:
      /* printf("String length in node %d: %u\n", offset, flags); */
      hv_store(node, "STRING", 6, newSVpv((char *)(n+1), flags), 0);
      break;

    case IFTHEN:		/* (?(COND)x) or (?(COND)x|y) */
      _partial_dump_regex(branch, base, result);
      hv_store(node, "TRUE", 4,  newSVpvf("%d", branch-base), 0);
      _partial_dump_regex(n + GET_ARG_1_OF_1(n), base, result);
      break;

    case SUSPEND:		/* (?>foo) */
    case UNLESSM:		/* (?!foo) and (?<!foo) [fl=1] */
    case IFMATCH:		/* (?=foo) and (?<=foo) [fl=1] */
      _partial_dump_regex(branch, base, result);
      hv_store(node, "LOOKFOR", 7,  newSVpvf("%d", branch-base), 0);
      _partial_dump_regex(n + GET_ARG_1_OF_1(n), base, result);
      hv_store(node, "NEXT", 4, newSVpvf("%d", n+GET_ARG_1_OF_1(n)-base), 0);
      break;

    case ANYOF:			/* char class */
      /* Rx2: Locales ignored here? */
      /* Rx2: Better dump format for inverted char classes? */
      { char *class;            /* array for char list */
        int cn = 0, i;
        char *c = ((char *)(n+1)); /* points to charclass bitmap */

        Newz(1, class, 257, char); 
        if (class == 0) croak("Out of memory in _partial_dump_regex");
        hv_store(node, "BITMAP", 6, newSVpvn(c, 32), 0);
        for (i=0; i < 256; i++)
          if (c[i>>3] & (1<<(i&7))) /* test bit for char #i */
            class[cn++] = i;
        hv_store(node, "CLASS", 5, newSVpvn(class, cn), 0);
        break;
      }

    case END: 
      return offset;

    case WHILEM:
    default:
      /* All other nodes get handled generically */
      break;

    }
  CONTINUE:
    if (next_off == 0) return;
    n += next_off;
  }
}


/* Convert regex node arguments to a Perl datum suitable
 * for inclusion in a regex dump structure 
 *
 * Args: format: argument type number from the regex node
 *       args: pointer to the arg structure
 *
 * BUG: Does not handle out-of-memory conditions
 */
SV *
regargSV(int format, char *args) 
{
  switch(format) {
  case 0:			/* no args */
    break;			/* Just return undef */
  case 1:			/* One 32-bit arg */
    return newSViv((IV) *(unsigned *) args);
  case 2:			/* Two 16-bit args */
    {
      AV *ary = newAV();
      SV *aref;

      av_push(ary, newSViv(*(unsigned short *)(args+0)));
      av_push(ary, newSViv(*(unsigned short *)(args+2)));
      aref = newRV_noinc((SV *)ary);
      return aref;
    }
  default:
    printf("Unknown node argument format #%d.\n", format);
    break;
  }
  return &PL_sv_undef;
}

OP *
_locate_match_op(const char *fname)
{
  CV *cv = get_cv(fname, 0);
  OP *op;

  return cv ? _search_op_for_match(CvROOT(cv)) : 0;
}

/* Recurse down op tree looking for the 'match' node.  There should be
   only one.  */
OP *
_search_op_for_match(OP *o) 
{
  OP *m;

  if (o->op_type == OP_MATCH) {
    if (o) return o;
  }

  if (o->op_flags & OPf_KIDS) {
    m = _search_op_for_match(((UNOP *)o)->op_first);
    if (m) return m;
  }

  if (o->op_sibling) {
    m  = _search_op_for_match(o->op_sibling);
    if (m) return m;
  }

  return 0;
}

