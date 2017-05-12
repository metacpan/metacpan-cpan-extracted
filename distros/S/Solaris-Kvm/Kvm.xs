#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <sys/types.h>
#include <sys/stat.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <fcntl.h>
#include <kvm.h>
#include <nlist.h>
#include <gelf.h>

#define F_SIZE  0
#define F_BIND  1
#define F_TYPE  2
#define F_VISB  3

typedef struct {
   char  *kvm_dev_name;
   kvm_t *kvm_sd;
} kvm_dev_t;

typedef struct {
   char         *var_name;
   GElf_Word     var_size;
   unsigned char var_bind;
   unsigned char var_type;
   unsigned char var_visib;
   unsigned char var_blob;
   IV            var_value;
} kvm_var_t;

static int
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant_STV(char *name, int len, int arg)
{
    if (3 + 1 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[3 + 1]) {
    case 'D':
	if (strEQ(name + 3, "_DEFAULT")) {	/* STV removed */
#ifdef STV_DEFAULT
	    return STV_DEFAULT;
#else
	    goto not_there;
#endif
	}
    case 'H':
	if (strEQ(name + 3, "_HIDDEN")) {	/* STV removed */
#ifdef STV_HIDDEN
	    return STV_HIDDEN;
#else
	    goto not_there;
#endif
	}
    case 'I':
	if (strEQ(name + 3, "_INTERNAL")) {	/* STV removed */
#ifdef STV_INTERNAL
	    return STV_INTERNAL;
#else
	    goto not_there;
#endif
	}
    case 'P':
	if (strEQ(name + 3, "_PROTECTED")) {	/* STV removed */
#ifdef STV_PROTECTED
	    return STV_PROTECTED;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_STB(char *name, int len, int arg)
{
    if (3 + 1 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[3 + 1]) {
    case 'G':
	if (strEQ(name + 3, "_GLOBAL")) {	/* STB removed */
#ifdef STB_GLOBAL
	    return STB_GLOBAL;
#else
	    goto not_there;
#endif
	}
    case 'L':
	if (strEQ(name + 3, "_LOCAL")) {	/* STB removed */
#ifdef STB_LOCAL
	    return STB_LOCAL;
#else
	    goto not_there;
#endif
	}
    case 'N':
	if (strEQ(name + 3, "_NUM")) {	/* STB removed */
#ifdef STB_NUM
	    return STB_NUM;
#else
	    goto not_there;
#endif
	}
    case 'W':
	if (strEQ(name + 3, "_WEAK")) {	/* STB removed */
#ifdef STB_WEAK
	    return STB_WEAK;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_STT_N(char *name, int len, int arg)
{
    switch (name[5 + 0]) {
    case 'O':
	if (strEQ(name + 5, "OTYPE")) {	/* STT_N removed */
#ifdef STT_NOTYPE
	    return STT_NOTYPE;
#else
	    goto not_there;
#endif
	}
    case 'U':
	if (strEQ(name + 5, "UM")) {	/* STT_N removed */
#ifdef STT_NUM
	    return STT_NUM;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_STT_F(char *name, int len, int arg)
{
    switch (name[5 + 0]) {
    case 'I':
	if (strEQ(name + 5, "ILE")) {	/* STT_F removed */
#ifdef STT_FILE
	    return STT_FILE;
#else
	    goto not_there;
#endif
	}
    case 'U':
	if (strEQ(name + 5, "UNC")) {	/* STT_F removed */
#ifdef STT_FUNC
	    return STT_FUNC;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_STT(char *name, int len, int arg)
{
    if (3 + 1 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[3 + 1]) {
    case 'C':
	if (strEQ(name + 3, "_COMMON")) {	/* STT removed */
#ifdef STT_COMMON
	    return STT_COMMON;
#else
	    goto not_there;
#endif
	}
    case 'F':
	if (!strnEQ(name + 3,"_", 1))
	    break;
	return constant_STT_F(name, len, arg);
    case 'N':
	if (!strnEQ(name + 3,"_", 1))
	    break;
	return constant_STT_N(name, len, arg);
    case 'O':
	if (strEQ(name + 3, "_OBJECT")) {	/* STT removed */
#ifdef STT_OBJECT
	    return STT_OBJECT;
#else
	    goto not_there;
#endif
	}
    case 'S':
	if (strEQ(name + 3, "_SECTION")) {	/* STT removed */
#ifdef STT_SECTION
	    return STT_SECTION;
#else
	    goto not_there;
#endif
	}
    case 'T':
	if (strEQ(name + 3, "_TLS")) {	/* STT removed */
#ifdef STT_TLS
	    return STT_TLS;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant(char *name, int len, int arg)
{
    errno = 0;
    if (0 + 2 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[0 + 2]) {
    case 'B':
	if (!strnEQ(name + 0,"ST", 2))
	    break;
	return constant_STB(name, len, arg);
    case 'T':
	if (!strnEQ(name + 0,"ST", 2))
	    break;
	return constant_STT(name, len, arg);
    case 'V':
	if (!strnEQ(name + 0,"ST", 2))
	    break;
	return constant_STV(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

MODULE = Solaris::Kvm		PACKAGE = Solaris::Kvm		

double
constant(sv,arg)
PREINIT:
   STRLEN len;
INPUT:
   SV    *sv;
   char  *s = SvPV(sv, len);
   int    arg;
CODE:
   RETVAL = constant(s,len,arg);
OUTPUT:
   RETVAL

void
new(class,dev=NULL)
   char      *class;
   char      *dev;
PREINIT:
   SV        *ret;
   HV        *stash;
   HV        *hash;
   HV        *tie;
   SV        *dsv;
   SV        *tieref;
   Elf       *elf;
   Elf_Scn   *scn;
   GElf_Shdr  shdr;
   Elf_Data  *data;
   GElf_Sym   sym;
   kvm_dev_t *kd;
   kvm_var_t *kv;
   char      *p;
   char      *n;
   char      *t;
   char       errstr[1024];
   int        i, fd, ii, count;
PPCODE:
   hash   = newHV();
   ret    = (SV*)newRV_noinc((SV*)hash);

   stash  = gv_stashpv(class,TRUE);
   sv_bless(ret,stash);

   stash  = gv_stashpv(class,TRUE);
   sv_bless(ret,stash);

   Newz(0,kd,sizeof(kvm_dev_t),kvm_dev_t);
   kd->kvm_dev_name = strdup(dev ? dev : "/dev/ksyms");
   if ((kd->kvm_sd = kvm_open(0, 0, 0, O_RDONLY, errstr)) == 0)
      croak("kvm_open failed (%s)", strerror(errno));
   
   tie = newHV();
   tieref = newRV_noinc((SV*)tie);
   sv_bless(tieref, gv_stashpv("Solaris::Kvm::Stat", TRUE));
   hv_magic(hash, (GV*)tieref, 'P'); 

   dsv = newSViv((IV)kd);
   sv_magic(SvRV(tieref), dsv, '~', 0, 0);
   SvREFCNT_dec(dsv);

   elf_version(EV_CURRENT);

   fd = open(kd->kvm_dev_name, O_RDONLY);
   if((elf = elf_begin(fd, ELF_C_READ, NULL)) == 0)
      croak("elf_begin failed (%s)", strerror(errno));

   scn = NULL;
   while ((scn = elf_nextscn(elf, scn)) != NULL) {
      gelf_getshdr(scn, &shdr);
      if (shdr.sh_type == SHT_SYMTAB) break;
   }

   if (!scn) croak("no symbol table (%s)", strerror(errno));
   data  = elf_getdata(scn, NULL);
   count = shdr.sh_size / shdr.sh_entsize;

   for (ii=0; ii < count; ++ii) {
      gelf_getsym(data, ii, &sym);
      if (GELF_ST_TYPE(sym.st_info) != STT_OBJECT)
	 continue;
      n = strdup(elf_strptr(elf, shdr.sh_link, sym.st_name));
      Newz(0, kv, sizeof(kvm_var_t), kvm_var_t);
      kv->var_name  = n;
      kv->var_bind  = GELF_ST_BIND(sym.st_info);
      kv->var_type  = GELF_ST_TYPE(sym.st_info);
      kv->var_size  = sym.st_size;
      kv->var_visib = ELF64_ST_VISIBILITY(sym.st_other);
      kv->var_value = (IV)0;
      kv->var_blob  = kv->var_size <= sizeof(IV) ? 0 : 1;
      hv_store(tie, n, strlen(n), newSViv((IV)kv), 0);
   }
   elf_end(elf);
   close(fd);

   EXTEND(SP,1);
   PUSHs(sv_2mortal(ret));

void
rAUTOLOAD(self,prop,...)
   SV           *self;
   SV           *prop;
PREINIT:
   MAGIC        *mg;
   SV           *ref;
   STRLEN        plen;
   char         *pval;
   int           i;
PPCODE:
   mg = mg_find(SvRV(self), 'P');
   if(!mg) { croak("lost P magic"); }
   ref = mg->mg_obj;
   PUSHMARK(SP);
   XPUSHs(ref);
   for(i=2; i<items; i++)
      XPUSHs(ST(i));
   call_method(SvPV(prop,PL_na), G_SCALAR);

void
DESTROY(self)
   SV           *self;
CODE:

MODULE = Solaris::Kvm		PACKAGE = Solaris::Kvm::Stat

void
FETCH(self, key)
   SV           *self;
   SV           *key;
PREINIT:
   SV           *ret;
   HV           *hash;
   char         *k;
   STRLEN        klen;
   MAGIC        *mg;
   SV          **val;
   kvm_dev_t    *kp;
   kvm_var_t    *kv;
   struct nlist *nl;
   char         *t;
   int           i;
PPCODE:
   hash = (HV*)SvRV(self);
   k    = SvPV(key, klen);
   mg   = mg_find(SvRV(self),'~');
   if(!mg) { croak("lost ~ magic"); }
   kp   = (kvm_dev_t*)SvIVX(mg->mg_obj);

   val  = hv_fetch(hash, k, klen, FALSE);
   if (!val) 
      croak("kernel variable %s does not exist", k);
   kv   = (kvm_var_t*)SvIV(*val);
   Newz(0,nl,sizeof(struct nlist)*2,struct nlist);
   nl[0].n_name = k;
   if(kvm_nlist(kp->kvm_sd, nl) < 0) 
      croak("kvm_nlist failed (%s)", strerror(errno));

   if(kv->var_blob && !kv->var_value)
	 Newz(0, (char*)kv->var_value, kv->var_size, char);
   if(kvm_kread(kp->kvm_sd, nl[0].n_value, 
      kv->var_blob ? 
	 (char*)kv->var_value : (char*)&(kv->var_value)+(sizeof(IV)-kv->var_size), 
      kv->var_size) < 0)
      croak("kvm_kread failed (%s)", strerror(errno));

   ret = kv->var_blob ? 
      newSVpv((char*)(kv->var_value),kv->var_size) : 
      newSViv(kv->var_value);
   EXTEND(SP,1);
   PUSHs(sv_2mortal(ret));
   
SV*
STORE(self, key, value)
   SV         *self;
   SV         *key;
   SV         *value;
PREINIT:
   HV         *hash;
   char       *k;
   char       *v;
   STRLEN      klen;
   STRLEN      vlen;
   MAGIC      *mg;
   kvm_dev_t  *kp;
CODE:
   hash = (HV*)SvRV(self);
   k    = SvPV(key, klen);
   croak("STORE function is not implemented");
OUTPUT:
   RETVAL

void
DESTROY(self)
   SV        *self;
PREINIT:
   MAGIC     *mg;
   HV        *hash;
   HE        *hent;
   SV        *val;
   kvm_dev_t *kp;
   kvm_var_t *kv;
   char      *k;
   I32        klen;
CODE:
   mg = mg_find(SvRV(self),'~');
   if(!mg) { croak("lost ~ magic"); }
   kp = (kvm_dev_t*)SvIVX(mg->mg_obj);
   kvm_close(kp->kvm_sd);
   free(kp->kvm_dev_name);
   Safefree(kp);

   hash = (HV*)SvRV(self);
   hv_iterinit(hash);
   while(hent = hv_iternext(hash)) {
      k   = hv_iterkey(hent, &klen);
      val = hv_delete(hash, k, klen, 0);
      kv  = (kvm_var_t*)SvIV(val);
      if(kv->var_blob && kv->var_value)
	 Safefree(kv->var_value);
      free(kv->var_name);
      Safefree(kv);
      kv = (IV)0;
   }


bool
EXISTS(self, key)
   SV   *self;
   SV   *key;
PREINIT:
   HV   *hash;
   char *k;
CODE:
   hash = (HV*)SvRV(self);
   k    = SvPV(key, PL_na);
   RETVAL = hv_exists_ent(hash, key, 0);
OUTPUT:
   RETVAL

SV*
FIRSTKEY(self)
   SV *self;
PREINIT:
   HV *hash;
   HE *he;
PPCODE:
   hash = (HV*)SvRV(self);
   hv_iterinit(hash);
   if (he = hv_iternext(hash)) {
      EXTEND(sp, 1);
      PUSHs(hv_iterkeysv(he));
   }

SV*
NEXTKEY(self, lastkey)
   SV *self;
   SV *lastkey;
PREINIT:
   HV *hash;
   HE *he;
PPCODE:
   hash = (HV*)SvRV(self);
   if (he = hv_iternext(hash)) {
      EXTEND(sp, 1);
      PUSHs(hv_iterkeysv(he));
   }

SV*
DELETE(self, key)
   SV        *self;
   SV        *key;
PREINIT:
   HV *hash;
   HE *he;
CODE:
   hash = (HV*)SvRV(self);
   croak("DELETE functions is not implemented");
OUTPUT:
   RETVAL

void
CLEAR(self)
   SV *self;
PREINIT:
   HV *hash;
CODE:
   hash = (HV*)SvRV(self);
   croak("CLEAR function is not implemented");

void
_lookup(self,prop,...)
   SV     *self;
   SV     *prop;
ALIAS:
   Solaris::Kvm::Stat::size       = F_SIZE
   Solaris::Kvm::Stat::bind       = F_BIND
   Solaris::Kvm::Stat::type       = F_TYPE
   Solaris::Kvm::Stat::visibility = F_VISB
PREINIT:
   HV         *hash;
   SV        **var;
   SV         *ret;
   char       *pval;
   STRLEN      plen;
   kvm_var_t  *kv;
   int i;
PPCODE:
   hash = (HV*)SvRV(self);
   pval = SvPV(prop, plen);
   var  = hv_fetch(hash, pval, plen, FALSE);

   if(var) {
      kv = (kvm_var_t*)SvIV(*var);
      switch(ix) {
      case F_SIZE:
         ret = newSViv(kv->var_size);
	 break;
      case F_BIND:
         ret = newSViv(kv->var_bind);
	 break;
      case F_TYPE:
         ret = newSViv(kv->var_type);
	 break;
      case F_VISB:
         ret = newSViv(kv->var_visib);
	 break;
      }
   } else {
      ret = &PL_sv_undef;
   }
   EXTEND(SP,1);
   PUSHs(sv_2mortal(ret));
