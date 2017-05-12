#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "embedvar.h"

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <fcntl.h>
#include <sys/stropts.h>
#include <inet/nd.h>

#define  S_BUFFER	(1024*64)
#define fatal(msg)				\
   croak("%s(%d): %s",strerror(errno),errno,msg) 
#define warning(msg)				\
   warn("%s(%d): %s",strerror(errno),errno,msg) 

typedef enum {
   VAR_INT_T,
   VAR_STRING_T
} var_type_t;

typedef struct {
   char *ndd_dev_name;
   int   ndd_sd;
} ndd_dev_t;

typedef struct {
   char       *var_name;
   var_type_t  var_type;
   long        var_len;
   union {
      int      var_int;
      char    *var_string;
   } var_un;
} var_t;

static int
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(char *name, int len, int arg)
{
    errno = EINVAL;
    return 0;
}

static int
ndd_name_io(ndd_dev_t *np, int cmd, var_t *vp) {
   char *ndd_buf;
   struct strioctl str_cmd;

   Newz(0,ndd_buf,S_BUFFER,char);
   str_cmd.ic_cmd    = cmd;
   str_cmd.ic_timout = 0;
   str_cmd.ic_dp     = ndd_buf;
   str_cmd.ic_len    = S_BUFFER;

   switch(cmd) {
      case ND_GET:
	 strcpy(ndd_buf, vp->var_name);
	 break;
      case ND_SET:
	 switch(vp->var_type) {
	    case VAR_INT_T:
	       sprintf(ndd_buf, "%s%c%d", vp->var_name, 
		  0x00, vp->var_un.var_int);
               break;
	    case VAR_STRING_T:
	       sprintf(ndd_buf, "%s%c%s", vp->var_name, 
		  0x00, vp->var_un.var_string);
               break;
            default:
	       return -1;
         }
	 break;
      default:
	 return -1;
   }
   if (ioctl(np->ndd_sd, I_STR, &str_cmd) < 0) {
#if defined _WARN
      warning("ioctl failed");
#endif
      return -1;
   }
   if (cmd == ND_GET) {
      switch(vp->var_type) {
	 case VAR_INT_T:
	    vp->var_un.var_int = atoi(ndd_buf);
	    break;
         case VAR_STRING_T:
	    vp->var_len           = str_cmd.ic_len;
            vp->var_un.var_string = ndd_buf;
	    break;
	 default:
	    return -1;
      }
   } else {
      Safefree(ndd_buf);
   }
   return 0;
};

MODULE = Solaris::NDDI		PACKAGE = Solaris::NDDI

SV*
new(class,dev)
   char      *class;
   char      *dev;
PREINIT:
   HV        *stash;
   HV        *hash;
   HV        *tie;
   SV        *dsv;
   SV        *tieref;
   ndd_dev_t *nd;
   var_t      var;
   var_t      vvar;
   char      *p;
   char      *n;
   char      *t;
   int        i;
CODE:
   hash   = newHV();
   RETVAL = (SV*)newRV_noinc((SV*)hash);
   stash  = gv_stashpv(class,TRUE);
   sv_bless(RETVAL,stash);

   New(0,nd,sizeof(ndd_dev_t),ndd_dev_t);
   nd->ndd_dev_name = strdup(dev);
   if ((nd->ndd_sd = open(nd->ndd_dev_name, O_RDWR)) < 0)
      fatal("open failed");

   tie = newHV();
   tieref = newRV_noinc((SV*)tie);
   sv_bless(tieref, gv_stashpv("Solaris::NDDI::Stat", TRUE));
   hv_magic(hash, (GV*)tieref, 'P'); 

   dsv = newSViv((int)nd);
   sv_magic(SvRV(tieref), dsv, '~', 0, 0);
   SvREFCNT_dec(dsv);

   var.var_name 	 = "?";
   var.var_type          = VAR_STRING_T;
   var.var_un.var_string = 0;

   if (ndd_name_io(nd, ND_GET, &var) < 0)
      fatal("ndd_name_io failed");
   for (p = var.var_un.var_string; *p; p += strlen(p)+1) {
      if (p[0] == '?') continue;
      n = strdup(p); n[strcspn(p, " \t(")] = '\0';
      vvar.var_name         = n;
      vvar.var_type         = VAR_STRING_T;
      var.var_un.var_string = 0;
      if (ndd_name_io(nd, ND_GET, &vvar) != -1) {
         switch(vvar.var_type) {
	    case VAR_INT_T:
	       hv_store(tie, n, strlen(n), newSViv(vvar.var_un.var_int), 0);
	       break;
            case VAR_STRING_T:
	       for(i=0, t=vvar.var_un.var_string; i<vvar.var_len-2; i++, t++) 
	          if (*t == '\0') *t = '\n';
               hv_store(tie, n, strlen(n), newSVpv(vvar.var_un.var_string,0), 0);
	       Safefree(vvar.var_un.var_string);
	       break;
            default:
	       hv_store(tie, n, strlen(n), &PL_sv_undef, 0);
	       break;
         }
      }
      else {
#if defined _WARN
	 warning("ndd_name_io failed");
#endif
	 hv_store(tie, n, strlen(n), &PL_sv_undef, 0);
      }
      free(n);
   }
   Safefree(var.var_un.var_string);
OUTPUT:
   RETVAL

MODULE = Solaris::NDDI		PACKAGE = Solaris::NDDI::Stat

SV*
FETCH(self, key)
   SV         *self;
   SV         *key;
PREINIT:
   HV         *hash;
   char       *k;
   STRLEN      klen;
   MAGIC      *mg;
   SV        **val;
   ndd_dev_t  *np;
   var_t       var;
   char       *t;
   int         i;
CODE:
   hash = (HV*)SvRV(self);
   k    = SvPV(key, klen);
   mg = mg_find(SvRV(self),'~');
   if(!mg) { croak("lost ~ magic"); }
   np = (ndd_dev_t*)SvIVX(mg->mg_obj);

   var.var_name          = k;
   var.var_type          = VAR_STRING_T;
   var.var_un.var_string = 0;
   if (ndd_name_io(np, ND_GET, &var) != -1)
      switch(var.var_type) {
         case VAR_INT_T:
            hv_store(hash, k, klen, newSViv(var.var_un.var_int), 0);
            break;
         case VAR_STRING_T:
            for(i=0, t=var.var_un.var_string; i<var.var_len-2; i++, t++) 
               if (*t == '\0') *t = '\n';
            hv_store(hash, k, klen, newSVpv(var.var_un.var_string,0), 0);
            Safefree(var.var_un.var_string);
            break;
         default:
            hv_store(hash, k, klen, &PL_sv_undef, 0);
            break;
      }
   else {
#if defined _WARN
      warning("ndd_name_io failed");
#endif
      hv_store(hash, k, klen, &PL_sv_undef, 0);
   }
   val = hv_fetch(hash, k, klen, FALSE);
   if (val) {
      RETVAL = *val; SvREFCNT_inc(RETVAL);
   } else {
      RETVAL = &PL_sv_undef;
   }
OUTPUT:
   RETVAL
   
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
   ndd_dev_t  *np;
   var_t       var;
CODE:
   hash = (HV*)SvRV(self);
   k    = SvPV(key, klen);

   mg = mg_find(SvRV(self),'~');
   if(!mg) { croak("lost ~ magic"); }
   np = (ndd_dev_t*)SvIVX(mg->mg_obj);
   v = SvPV(value, vlen);

   var.var_name          = k;
   var.var_type          = VAR_STRING_T;
   var.var_un.var_string = v;
   if (ndd_name_io(np, ND_SET, &var) < 0) 
      fatal("ND_SET failed");

   SvREFCNT_inc(value);
   RETVAL = *(hv_store(hash, k, klen, value, 0));
   SvREFCNT_inc(RETVAL);
OUTPUT:
   RETVAL

void
DESTROY(self)
   SV        *self;
PREINIT:
   MAGIC     *mg;
   ndd_dev_t *np;
CODE:
   mg = mg_find(SvRV(self),'~');
   if(!mg) { croak("lost ~ magic"); }
   np = (ndd_dev_t*)SvIVX(mg->mg_obj);
   close(np->ndd_sd);
   free(np->ndd_dev_name);
   Safefree(np);

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
   SV *self;
   SV *key;
PREINIT:
   HV *hash;
   HE *he;
CODE:
   hash = (HV*)SvRV(self);
   RETVAL = hv_delete_ent(hash, key, 0, 0);
   if (RETVAL) { 
      SvREFCNT_inc(RETVAL); 
   }
   else { 
      RETVAL = &PL_sv_undef; 
   }
OUTPUT:
   RETVAL

void
CLEAR(self)
   SV *self;
PREINIT:
   HV *hash;
CODE:
   hash = (HV*)SvRV(self);
   hv_clear(hash);
