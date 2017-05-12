/*  -*- Mode: C -*- */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"


#include <sys/types.h>

/* malloc() */
#include <stdlib.h>

/* memset() */
#include <string.h>

#include <stdio.h>

#ifdef _WIN32
#include <stdint.h>
typedef   uint32_t    u_int32_t;
#endif

#ifdef SOLARIS
typedef   uint32_t    u_int32_t;
#else
# if ! (defined(LINUX) || defined(CYGWIN))
typedef   u_int32_t   in_addr_t;
# endif
#endif

#define bitcheck(a, b)   (a>>b) & 1
#define bitset(a, b)     a |= (1<<b)
#define bitunset(a, b)   a &= ~(1<<b)

u_int32_t bits[] = {
  0x80000000, 0x40000000, 0x20000000, 0x10000000, 0x08000000, 0x04000000,
  0x02000000, 0x01000000, 0x00800000, 0x00400000, 0x00200000, 0x00100000,
  0x00080000, 0x00040000, 0x00020000, 0x00010000, 0x00008000, 0x00004000,
  0x00002000, 0x00001000, 0x00000800, 0x00000400, 0x00000200, 0x00000100,
  0x00000080, 0x00000040, 0x00000020, 0x00000010, 0x00000008, 0x00000004,
  0x00000002, 0x00000001,
};

typedef struct _n {
  struct _n *zero;
  struct _n *one;
  char *code;
} Node;

#define MCB_MAX 1024
typedef struct {
  Node *block;
  int pos;
#define COUNT_MAX 1024*1024
} MCB;

typedef struct {
  Node *root;
  MCB *m_cb;
  int m_cur;
  int clean;
} XS2_CTX;

/* prototypes */
int _inet_aton2(char *, in_addr_t *);
int parse_net4(char *, int, in_addr_t *, int *);
void print_ip (u_int32_t, int, char **);

/* allocate mem block */
Node *alloc_m (XS2_CTX *ctx)
{
  Node *x;

  ctx->m_cur++;
  if (ctx->m_cur >= MCB_MAX) {
    /* memory exhausted */
    return NULL;
  }
  x = malloc(sizeof(Node) * COUNT_MAX);
  if (x != NULL) {
    memset(x, 0, sizeof(Node) * COUNT_MAX);
    ctx->m_cb[ctx->m_cur].block = x;
    ctx->m_cb[ctx->m_cur].pos = 0;
  }
  return x;
}

Node *alloc_1 (XS2_CTX *ctx)
{
  Node *x;
  if (ctx->m_cb[ctx->m_cur].pos >= COUNT_MAX-1) {
    x = alloc_m(ctx);
    if (x == NULL) {
      return x;
    }
  }
  return &(ctx->m_cb)[ctx->m_cur].block[ctx->m_cb[ctx->m_cur].pos++];
}

void free_m (pTHX_ XS2_CTX *ctx)
{
  int i;
  for (i=0; i< MCB_MAX; i++) {
    if (ctx->m_cb[i].block != NULL) {
      free(ctx->m_cb[i].block);
    }
  }
  free(ctx->m_cb);
}

int _inet_aton2(char *ip, in_addr_t *addr)
{
  char buf[4][4];
  unsigned int pt[4];
  int i, j;
  char c;

  for (i=0; i<4; i++) {
    for (j=0; j<4; j++) {
      c = *(ip++);
      if (c >= '0' && c <= '9')
	buf[i][j] = c;
      else
	break;
    }
    buf[i][j] = '\0';
    /*    pt[i] = atoi((char*)&buf[i][0]); */
    pt[i] = atoi((char*)&buf[i][0]) & 0xff;
    /* check */
    /*
    if (pt[i] < 0 || pt[i] > 255)
    return(-1);
    */
  }

  /*
  *addr = (pt[0] << 24) |
    ((pt[1] & 0xff)<<16) |
    ((pt[2] & 0xff)<<8) |
    (pt[3] & 0xff);
  */
  *addr = (pt[0]<<24)|(pt[1]<<16)|(pt[2]<<8)|pt[3];
  
  return(1);
}

#define PRINTABLE_V4_ADDR_LEN 16

int parse_net4(char *buf, int len, in_addr_t *addr, int *mask)
{
    int i, j, k, m;
    char d[4];
    char ip[16];

    k = 0;
    for (i=0; i<PRINTABLE_V4_ADDR_LEN && i<len; i++) {
      if (buf[i] != '.' && (buf[i] < '0' || buf[i] > '9')) {
        break;
      } else {
	ip[k++] = buf[i];
      }
    }
    ip[k] = '\0';
    if (_inet_aton2(ip, addr) < 0)
      return(-1);

    for (; i<len && (buf[i]<'0' || buf[i]>'9'); i++)
      ;

    d[0] = '\0';
    for (j=0; i<len && j<3; i++, j++) {
      if (buf[i] < '0' || buf[i] > '9') {
	break;
      } else {
	d[j] = buf[i];
      }
    }
    d[j] = '\0';

    m = atoi(d);
    if (m <= 0 || m > 32)
      m = 32;
    *mask = m;
    return(1);
}

int regist4(XS2_CTX *ctx, in_addr_t in_addr, int mask, char *desc)
{
  Node *p;
  int i;

  p = ctx->root;
  for (i=0; i<mask; i++) {
    if (in_addr & bits[i]) {
      if (p->one == NULL) {
	/* alloc */
	p->one = alloc_1(ctx);
      }
      if (p->one) {
	p = p->one;
      } else {
	return(-1);
      }
    } else {
      if (p->zero == NULL) {
	/* alloc */
	p->zero = alloc_1(ctx);
      }
      if (p->zero) {
	p = p->zero;
      } else {
	return(-1);
      }
    }
  }
  if (desc != NULL) {
	/*
    printf("desc: %s(%x)\n", desc, desc);
	*/
    p->code = strdup(desc);
  } else {
    p->code = (char *)(-1);
  }

  ctx->clean = 0; /* flag dirty */

  return(1);
}

int regist(XS2_CTX *ctx, char *addr, int len, char *desc)
{
  in_addr_t in_addr;
  int mask;

  if (parse_net4(addr, len, &in_addr, &mask) < 0)
    return (-1);
  return (regist4(ctx, in_addr, mask, desc));
}

in_addr_t add_bit(in_addr_t addr, int bits)
{
  int i;

  for (i=bits; i<32; i++) {
    if (bitcheck(addr, i)) {
      bitunset(addr, i);
    } else {
      break;
    }
  }
  bitset(addr, i);
  return(addr);
}

int regist_range4(XS2_CTX *ctx, in_addr_t start, in_addr_t end)
{
  in_addr_t x, y;
  int i, mask;
  /*char *p, str[21];*/
  int sbit;

  /*p = str;*/

  x = start;
  while (x < end+1) {
    for (sbit=0; sbit<32; sbit++) {
      if (bitcheck(x, sbit))
        break;
    }
    /* printf("sbit: %d\n", sbit); */
    for (i=sbit; i>=0; i--) {
      y = add_bit(x, i);
      mask = 32-i;
      if (y <= end+1)
        break;
    }
    /*
    print_ip(x, mask, &p);
    printf("%s\n", str);
    */
    if (regist4(ctx, x, mask, NULL) < 0)
      return(-1);

    x = y;
  }
  return(1);
}

int regist_range(XS2_CTX *ctx, char *buf, int len)
{
    in_addr_t start, end;
    int i, j, k;
    char ip[16];

    k = 0;
    for (i=0; i<PRINTABLE_V4_ADDR_LEN && i<len; i++) {
      if (buf[i] == ' ' || buf[i] == '-') {
        break;
      } else {
	ip[k++] = buf[i];
      }
    }
    ip[k] = '\0';
    if (_inet_aton2(ip, &start) < 0)
      return (-1);

    for (; i<len && (buf[i] < '0' || buf[i] > '9'); i++)
      ;

    k = 0;
    for (j=0; j<PRINTABLE_V4_ADDR_LEN && i<len; j++, i++) {
      if (buf[i] != '.' && (buf[i] < '0' || buf[i] > '9')) {
        break;
      } else {
	ip[k++] = buf[i];
      }
    }
    ip[k] = '\0';
    if (_inet_aton2(ip, &end) < 0)
      return (-1);

    return (regist_range4(ctx, start, end));

}

void print_ip (u_int32_t ip, int lvl, char **str)
{
  if (*str != NULL) {
    snprintf(*str, 20, "%u.%u.%u.%u/%d",
		    (ip & 0xff000000) >> 24,
		    (ip & 0x00ff0000) >> 16,
		    (ip & 0x0000ff00) >> 8,
		    ip & 0x000000ff, lvl);
  }
}

#define is_leaf(a)  ((a) && (a)->zero == NULL && (a)->one == NULL)

void _clean_up (Node *p, int lvl, int cl)
{

  /* aggregate */
  if (is_leaf(p->zero) && is_leaf(p->one)) {
    if (p->code != NULL  && p->code != (char *)(-1))
      free(p->code);
    p->code = (char *)(-1);
    p->zero = NULL;
    p->one = NULL;
  }

  /* cut leaves */
  if (p->code != NULL) {
    cl++;
  }

  if (p->zero) {
    if (cl && is_leaf(p->zero))
      p->zero = NULL;
    else
      _clean_up(p->zero, lvl+1, cl);
  }
  if (p->one) {
    if (cl && is_leaf(p->one))
      p->one = NULL;
    else
      _clean_up(p->one, lvl+1, cl);
  }

  /* re-aggregate */
  if (is_leaf(p->zero) && is_leaf(p->one)) {
    if (p->code != NULL && p->code != (char *)(-1))
      free(p->code);
    p->code = (char *)(-1);
    p->zero = NULL;
    p->one = NULL;
  }

  /* cut leaves */
  if (cl && is_leaf(p->zero))
    p->zero = NULL;

  if (cl && is_leaf(p->one))
    p->one = NULL;

}

void _clean (pTHX_ XS2_CTX* ctx)
{
  if (!ctx->clean) {
    _clean_up(ctx->root, 0, 0);
    ctx->clean = 1;
  }
}

void _dump (Node *p, u_int32_t ip, int lvl)
{
  char str[21];
  char *s = str;

  if (p->code != NULL) {
    if (p->code == (char *)(-1)) {
      print_ip(ip, lvl, &s);
      printf("%s\n", str);
    } else {
      print_ip(ip, lvl, &s);
      printf("%s %s\n", str, p->code);
    }
  }
  if (p->zero) {
    _dump(p->zero, ip, lvl+1);
  }
  if (p->one) {
    _dump(p->one, ip|bits[lvl], lvl+1);
  }
}

void _list (AV *out, Node *p, u_int32_t ip, int lvl)
{
  char str[21];
  char *s = str;

  if (p->code != NULL) {
    print_ip(ip, lvl, &s);
    av_push(out, newSVpv(str, 0));
    return; /* OK ? */
  }
  if (p->zero) {
    _list(out, p->zero, ip, lvl+1);
  }
  if (p->one) {
    _list(out, p->one, ip|bits[lvl], lvl+1);
  }
}

int init (pTHX_ XS2_CTX *ctx)
{
  Node *x;

  ctx->m_cb = malloc(sizeof(MCB) * MCB_MAX);
  memset(ctx->m_cb, 0, sizeof(MCB) * MCB_MAX);

  ctx->m_cur = -1;
  x = alloc_m(ctx);
  if (x == NULL) {
    return(-1);
  }
  ctx->root = alloc_1(ctx);
  return(1);
}

int _add(pTHX_ XS2_CTX* ctx, SV* sv)
{
  int j, num;
  STRLEN len;
  I32 alen;
  I32 klen;
  SV** p_aval;
  SV* hval;
  char *str, *key;

  switch (SvTYPE(sv)) {
  case SVt_PVAV:
    alen = av_len((AV*)sv);
    for(j=0; j<=alen; j++) {
      p_aval = av_fetch((AV*)sv, j, 1);
      if (*p_aval == &PL_sv_undef)
	continue;
      str = SvPVbyte(*p_aval, len);
      if (regist(ctx, str, len, NULL) < 0)
	return (-1);
    }
    break;

  case SVt_PVHV:
    num = hv_iterinit((HV*)sv);
    for (j=0; j<num; j++) {
      hval = hv_iternextsv((HV*)sv, &key, &klen);
      str = SvPVbyte(hval, len);
      /*
      printf("HV(%d)> %s : %s (%d)\n", j, key, str, klen);
      printf(">str %x\n", str);
      */
      if (SvTRUE(hval)) {
	if (regist(ctx, key, klen, str)<0)
	  return (-1);
      } else {
	if (regist(ctx, key, klen, NULL)<0)
	  return (-1);
      }
    }
    break;

  case SVt_PV:
  default:
    str = SvPVbyte(sv, len);
    if (regist(ctx, str, len, NULL)<0)
      return (-1);
    break;
  }
  return(1);
}

int _add_range(pTHX_ XS2_CTX* ctx, SV* sv)
{
  int  i;
  STRLEN len;
  I32 alen;
  SV** p_aval;
  char *str;

  switch (SvTYPE(sv)) {
  case SVt_PVAV:
    alen = av_len((AV*)sv);
    for(i=0; i<=alen; i++) {
      p_aval = av_fetch((AV*)sv, i, 1);
      if (*p_aval == &PL_sv_undef)
	continue;
      str = SvPVbyte(*p_aval, len);
      if (regist_range(ctx, str, len)<0)
	return (-1);
    }
    break;
  case SVt_PV:
  default:
    str = SvPVbyte(sv, len);
    if (regist_range(ctx, str, len)<0)
      return (-1);
    break;
  }
  return (1);
}

int _match_ip(pTHX_ XS2_CTX * ctx, SV* net, char **match)
{
  /* warn:
	*match can be filled a string "xxx.xxx.xxx.xxx/NN"
	or pointer will be replaced as p->code
  */
  char *str;
  STRLEN len;
  in_addr_t addr, m_addr;
  int mask;
  Node *p;
  int i;

  str = SvPVbyte(net, len);
  parse_net4(str, len, &addr, &mask);
  /* _inet_aton2(ip, &addr); */
  m_addr = 0;
  p = ctx->root;
  /*
  _dump(p, m_addr, 0);
  m_addr = 0;
  */
  for (i=0; i<=mask; i++) {
    if (p->code != NULL) {
	/*
      printf("p->code: %s(%x) mask=%d i=%d \n", p->code, p->code, mask, i);
	*/
      if (match != NULL && *match != NULL) {
	if (p->code == (char *)(-1)) {
	   print_ip(m_addr, i, match);
	} else {
	   *match = p->code;
	}
      }
      return 1;
    }
    if (addr & bits[i]) {
      m_addr |= bits[i];
      if (p->one) {
	p = p->one;
	continue;
      }
    } else {
      if (p->zero) {
	p = p->zero;
	continue;
      }
    }
	/*
    print_ip(m_addr, i, &str);
    printf("||| mask=%d i=%d where=%s one(%p) zero(%p) code(%p)\n", mask, i, str, p->one, p->zero, p->code);
	*/
    return 0;
  }
	/*
  print_ip(m_addr, i, &str);
  printf(">>> mask=%d i=%d where=%s one(%p) zero(%p) code(%p)\n", mask, i, str, p->one, p->zero, p->code);
	*/
  return 0;
}

MODULE = Net::IP::Match::Bin		PACKAGE = Net::IP::Match::Bin

PROTOTYPES: DISABLE

void
new(class, ...)
    SV* class

    PREINIT:
        XS2_CTX* ctx;
	SV* sv;
	int i;

    PPCODE:
        STRLEN len;
        char *sclass = SvPV(class, len);
#if PVER >= 5008008
        Newx(ctx, 1, XS2_CTX);
#else
        Newz(0, ctx, 1, XS2_CTX);
#endif
        if (init(aTHX_ ctx) != 1) {
            Safefree(ctx);
            XSRETURN_UNDEF;
	} else {
	    for (i=1; i<items; i++) {
		if (SvROK(ST(i))) {
		    sv = SvRV(ST(i));
		} else {
		    sv = ST(i);
		}
		if (_add(aTHX_ ctx, sv) < 0) {
		  Safefree(ctx);
		  XSRETURN_UNDEF;
		}
	    }

            ST(0) = sv_newmortal();
            sv_setref_pv(ST(0), sclass, ctx);
            XSRETURN(1);
        }

void
add(self, ...)
     SV* self

     PREINIT:
	XS2_CTX* ctx;
	SV* sv;
	int i;

     PPCODE:
	if (!SvROK(self)) {
	    XSRETURN_UNDEF;
	} else {
	    ctx = INT2PTR(XS2_CTX*, SvIV(SvRV(self)));
	}
	if (items < 2) {
	    /* too few args */
	    XSRETURN_UNDEF;
	}
	for (i=1; i<items; i++) {
	    if (SvROK(ST(i))) {
                sv = SvRV(ST(i));
            } else {
                sv = ST(i);
            }
	    if (_add(aTHX_ ctx, sv)<0) {
	      Safefree(ctx);
	      XSRETURN_UNDEF;
	    }
	}
	ST(0) = newSVsv(self);
	sv_2mortal(ST(0));
	XSRETURN(1);
	/*XSRETURN_YES;*/

void
add_range(self, ...)
     SV* self

     PREINIT:
	XS2_CTX* ctx;
	SV* sv;
	int i;

     PPCODE:
	if (!SvROK(self)) {
	    XSRETURN_UNDEF;
	} else {
	    ctx = INT2PTR(XS2_CTX*, SvIV(SvRV(self)));
	}
	if (items < 2) {
	    /* too few args */
	    XSRETURN_UNDEF;
	}
	for (i=1; i<items; i++) {
	    if (SvROK(ST(i))) {
                sv = SvRV(ST(i));
            } else {
                sv = ST(i);
            }
	    if (_add_range(aTHX_ ctx, sv) < 0) {
	      Safefree(ctx);
	      XSRETURN_UNDEF;
	    }
	}
	ST(0) = newSVsv(self);
	sv_2mortal(ST(0));
	XSRETURN(1);
	/*XSRETURN_YES;*/

void
DESTROY(self)
	SV* self
     CODE:
	if (SvROK(self)) {
	  XS2_CTX* ctx = INT2PTR(XS2_CTX*, SvIV(SvRV(self)));
	  free_m(aTHX_ ctx);
	  Safefree(ctx);
	}

void
match_ip(...)
     PREINIT:
	XS2_CTX* ctx;
	char *ip;
	SV* net;
	STRLEN len;
	char out[21];
	char *p;
	int i;
	SV* sv;
	int func_call;
	int res;
     PPCODE:
	if (items < 2) {
	    /* too few args */
	    XSRETURN_UNDEF;
	}
	if (!SvROK(ST(0))) {
	    /* can be called as function */
#if PVER >= 5008008
	    Newx(ctx, 1, XS2_CTX);
#else
	    Newz(0, ctx, 1, XS2_CTX);
#endif
            if (init(aTHX_ ctx) != 1) {
		Safefree(ctx);
		XSRETURN_UNDEF;
	    }
	    i = 0;
	    func_call = 1;
	} else {
	    ctx = INT2PTR(XS2_CTX*, SvIV(SvRV(ST(0))));
	    i = 1;
	    func_call = 0;
	}
	ip = SvPVbyte(ST(i), len);
	if (SvROK(ST(i))) {
	    net = SvRV(ST(i));
	} else {
	    net = ST(i);
	}

	/* printf("%s\n", ip); */
	
	i++;
	for (; i<items; i++) {
	    if (SvROK(ST(i))) {
		sv = SvRV(ST(i));
	    } else {
		sv = ST(i);
	    }
	    if (_add(aTHX_ ctx, sv) < 0) {
	      Safefree(ctx);
	      XSRETURN_UNDEF;
	    }
	}

	p = out;
	_clean(aTHX_ ctx);
	res = _match_ip(aTHX_ ctx, net, &p);
	if (func_call > 0) {
	  free_m(aTHX_ ctx);
	  Safefree(ctx);
	}
	if (res > 0) {
	  ST(0) = newSVpv(p, 0);
	  sv_2mortal(ST(0));
	  XSRETURN(1);
	} else {
	  XSRETURN_UNDEF;
	}

void
list(self)
     SV* self

     PREINIT:
	XS2_CTX* ctx;
        AV* out;
        I32 i;

     PPCODE:
	I32 gimme = GIMME_V;
	I32 len = 0;

	if (!SvROK(self)) {
	    XSRETURN_UNDEF;
	} else {
	    if (gimme == G_VOID)
		XSRETURN_EMPTY;
	    
	    ctx = INT2PTR(XS2_CTX*, SvIV(SvRV(self)));
	    out = newAV();
	    _clean(aTHX_ ctx);
	    _list(out, ctx->root, 0, 0);
	    switch(gimme) {
	    case G_SCALAR:
		ST(0) = newRV((SV *)out);
		sv_2mortal(ST(0));
		len = 1;
		break;

	    default:
		len = av_len(out) + 1;
		EXTEND(SP, len+1);
		for (i = 0; i < len; i++) {
		    ST(i) = sv_2mortal(av_shift(out));
		}
		break;
	    }
	}
	XSRETURN(len);

void
clean(self)
     SV* self

     PREINIT:
	XS2_CTX* ctx;

     PPCODE:
	if (!SvROK(self)) {
	    XSRETURN_UNDEF;
	} else {
	    ctx = INT2PTR(XS2_CTX*, SvIV(SvRV(self)));
	    _clean(aTHX_ ctx);
	}
	XSRETURN_YES;

void
dump(self)
     SV* self

     PREINIT:
	XS2_CTX* ctx;

     PPCODE:
	if (!SvROK(self)) {
	    XSRETURN_UNDEF;
	} else {
	    ctx = INT2PTR(XS2_CTX*, SvIV(SvRV(self)));
	    _clean(aTHX_ ctx);
	    _dump(ctx->root, 0, 0);
	}
	XSRETURN_YES;
