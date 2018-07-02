#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <libpkgconf/libpkgconf.h>

struct my_client_t {
  pkgconf_client_t client;
  FILE *auditf;
  int maxdepth;
  SV *error_handler;
};

typedef struct my_client_t my_client_t;

static bool
my_error_handler(const char *msg, const pkgconf_client_t *_, const void *data)
{
  dSP;

  int count;
  bool value;
  const my_client_t *client = (const my_client_t*)data;
    
  ENTER;
  SAVETMPS;
  
  PUSHMARK(SP);
  EXTEND(SP, 1);
  PUSHs(sv_2mortal(newSVpv(msg, 0)));
  PUTBACK;
  
  count = call_sv(client->error_handler, G_SCALAR);
  
  SPAGAIN;
  
  value = count > 0 && POPi;
  
  PUTBACK;
  FREETMPS;
  LEAVE;

  return value;
}

static bool
my_pkg_iterator(const pkgconf_pkg_t *pkg, void *data)
{
  dSP;
  
  int count;
  bool value;
  SV *callback = (SV*)data;
  
  ENTER;
  SAVETMPS;
  
  PUSHMARK(SP);
  EXTEND(SP,1);
  PUSHs(sv_2mortal(newSViv(PTR2IV(pkg))));
  PUTBACK;
  
  count = call_sv(callback, G_SCALAR);
  
  SPAGAIN;
  
  value = count > 0 && POPi;
  
  PUTBACK;
  FREETMPS;
  LEAVE;
  
  return value;
}

static bool
directory_filter(const pkgconf_client_t *client, const pkgconf_fragment_t *frag, void *data)
{
  if(pkgconf_fragment_has_system_dir(client, frag))
    return false;
  return true;
}

MODULE = PkgConfig::LibPkgConf  PACKAGE = PkgConfig::LibPkgConf::Client


void
_init(object, error_handler, maxdepth)
    SV *object
    SV *error_handler
    int maxdepth
  INIT:
    my_client_t *self;
  CODE:
    Newxz(self, 1, my_client_t);
    self->auditf = NULL;
    self->error_handler = SvREFCNT_inc(error_handler);
    self->maxdepth = maxdepth;
    pkgconf_client_init(&self->client, my_error_handler, self, pkgconf_cross_personality_default());
    pkgconf_client_set_flags(&self->client, PKGCONF_PKG_PKGF_NONE);
    hv_store((HV*)SvRV(object), "ptr", 3, newSViv(PTR2IV(self)), 0);


void
audit_set_log(self, filename, mode)
    my_client_t *self
    const char *filename
    const char *mode
  CODE:
    if(self->auditf != NULL)
    {
      fclose(self->auditf);
      self->auditf = NULL;
    }
    self->auditf = fopen(filename, mode);
    if(self->auditf != NULL)
    {
      pkgconf_audit_set_log(&self->client, self->auditf);
    }
    else
    {
      /* TODO: call error ? */
    }


const char *
sysroot_dir(self, ...)
    my_client_t *self
  CODE:
    if(items > 1)
    {
      pkgconf_client_set_sysroot_dir(&self->client, SvPV_nolen(ST(1)));
    }
    RETVAL = pkgconf_client_get_sysroot_dir(&self->client);
  OUTPUT:
    RETVAL


const char *
buildroot_dir(self, ...)
    my_client_t *self
  CODE:
    if(items > 1)
    {
      pkgconf_client_set_buildroot_dir(&self->client, SvPV_nolen(ST(1)));
    }
    RETVAL = pkgconf_client_get_buildroot_dir(&self->client);
  OUTPUT:
    RETVAL


int
maxdepth(self, ...)
    my_client_t *self
  CODE:
    if(items > 1)
    {
      self->maxdepth = SvIV(ST(1));
    }
    RETVAL = self->maxdepth;
  OUTPUT:
    RETVAL


void
path(self)
    my_client_t *self
  INIT:
    pkgconf_node_t *n;
    pkgconf_path_t *pnode;
    int count = 0;
  CODE:
    PKGCONF_FOREACH_LIST_ENTRY(self->client.dir_list.head, n)
    {
      pnode = n->data;
      ST(count++) = sv_2mortal(newSVpv(pnode->path, 0));
    }
    XSRETURN(count);


void
filter_lib_dirs(self)
    my_client_t *self
  INIT:
    pkgconf_node_t *n;
    pkgconf_path_t *pnode;
    int count = 0;
  CODE:
    PKGCONF_FOREACH_LIST_ENTRY(self->client.filter_libdirs.head, n)
    {
      pnode = n->data;
      ST(count++) = sv_2mortal(newSVpv(pnode->path, 0));
    }
    XSRETURN(count);    


void
filter_include_dirs(self)
    my_client_t *self
  INIT:
    pkgconf_node_t *n;
    pkgconf_path_t *pnode;
    int count = 0;
  CODE:
    PKGCONF_FOREACH_LIST_ENTRY(self->client.filter_includedirs.head, n)
    {
      pnode = n->data;
      ST(count++) = sv_2mortal(newSVpv(pnode->path, 0));
    }
    XSRETURN(count);    


void
DESTROY(self)
    my_client_t *self;
  CODE:
    if(self->auditf != NULL)
    {
      fclose(self->auditf);
      self->auditf = NULL;
    }
    pkgconf_client_deinit(&self->client);
    SvREFCNT_dec(self->error_handler);
    Safefree(self);


IV
_find(self, name)
    my_client_t *self
    const char *name
  CODE:
    RETVAL = PTR2IV(pkgconf_pkg_find(&self->client, name));
  OUTPUT:
    RETVAL


IV
_package_from_file(self, filename)
    my_client_t *self
    const char *filename
  INIT:
    FILE *fp;
  CODE:
    fp = fopen(filename, "r");
    if(fp != NULL)
      RETVAL = PTR2IV(pkgconf_pkg_new_from_file(&self->client, filename, fp));
    else
      RETVAL = 0;
  OUTPUT:
    RETVAL


void
_scan_all(self, sub)
    my_client_t *self
    SV* sub
  CODE:
    pkgconf_scan_all(&self->client, sub, my_pkg_iterator);
        

void
_dir_list_build(self, env_only)
    my_client_t *self
    int env_only
  INIT:
    int old_flags;
  CODE:
    if(env_only)
    {
      old_flags = pkgconf_client_get_flags(&self->client);
      pkgconf_client_set_flags(&self->client, old_flags | PKGCONF_PKG_PKGF_ENV_ONLY);
    }
    pkgconf_client_dir_list_build(&self->client, pkgconf_cross_personality_default());
    if(env_only)
    {
      pkgconf_client_set_flags(&self->client, old_flags);
    }


void
_set_global(self, kv)
    my_client_t *self
    const char *kv
  CODE:
    pkgconf_tuple_define_global(&self->client, kv);


const char *
_get_global(self, key)
    my_client_t *self
    const char *key
  INIT:
    const char *val;
  CODE:
    val = pkgconf_tuple_find_global(&self->client, key);
    if(val == NULL)
      XSRETURN_EMPTY;
    else
      RETVAL = val;
  OUTPUT:
    RETVAL
    


MODULE = PkgConfig::LibPkgConf  PACKAGE = PkgConfig::LibPkgConf::Package


int
refcount(self)
    pkgconf_pkg_t* self
  CODE:
    RETVAL = self->refcount;
  OUTPUT:
    RETVAL


const char *
id(self)
    pkgconf_pkg_t* self
  CODE:
    RETVAL = self->id;
  OUTPUT:
    RETVAL


const char *
filename(self)
    pkgconf_pkg_t* self
  CODE:
    RETVAL = self->filename;
  OUTPUT:
    RETVAL


const char *
realname(self)
    pkgconf_pkg_t* self
  CODE:
    RETVAL = self->realname;
  OUTPUT:
    RETVAL


const char *
version(self)
    pkgconf_pkg_t* self
  CODE:
    RETVAL = self->version;
  OUTPUT:
    RETVAL


const char *
description(self)
    pkgconf_pkg_t* self
  CODE:
    RETVAL = self->description;
  OUTPUT:
    RETVAL


const char *
url(self)
    pkgconf_pkg_t* self
  CODE:
    RETVAL = self->url;
  OUTPUT:
    RETVAL


const char *
pc_filedir(self)
    pkgconf_pkg_t* self
  CODE:
    RETVAL = self->pc_filedir;
  OUTPUT:
    RETVAL


SV *
_get_string(self, client, type)
    pkgconf_pkg_t *self
    my_client_t *client
    int type
  INIT:
    pkgconf_list_t unfiltered_list = PKGCONF_LIST_INITIALIZER;
    pkgconf_list_t filtered_list   = PKGCONF_LIST_INITIALIZER;
    size_t len;
    int eflag;
    int flags;
    int old_flags;
    bool escape = true;
  CODE:
    old_flags = flags = pkgconf_client_get_flags(&client->client);
    if(type % 2)
      flags = flags | PKGCONF_PKG_PKGF_MERGE_PRIVATE_FRAGMENTS;
    pkgconf_client_set_flags(&client->client, flags);
    /*
     * TODO: attribute for max depth (also in the list version below)
     */
    eflag = type > 1
      ? pkgconf_pkg_cflags(&client->client, self, &unfiltered_list, client->maxdepth)
      : pkgconf_pkg_libs(&client->client,   self, &unfiltered_list, client->maxdepth);
    pkgconf_client_set_flags(&client->client, old_flags);   
    /*
     * TODO: throw an exception (also in the list verson below)
     */
    if(eflag != PKGCONF_PKG_ERRF_OK)
      XSRETURN_EMPTY;
    pkgconf_fragment_filter(&client->client, &filtered_list, &unfiltered_list, directory_filter, NULL);
    len = pkgconf_fragment_render_len(&filtered_list, escape, NULL);
    RETVAL = newSV(len == 1 ? len : len-1);
    SvPOK_on(RETVAL);
    SvCUR_set(RETVAL, len-1);
    pkgconf_fragment_render_buf(&filtered_list, SvPVX(RETVAL), len, escape, NULL);
    pkgconf_fragment_free(&filtered_list);
    pkgconf_fragment_free(&unfiltered_list);
  OUTPUT:
    RETVAL


void
_get_list(self, client, type)
    pkgconf_pkg_t *self
    my_client_t *client
    int type
  INIT:
    pkgconf_list_t unfiltered_list = PKGCONF_LIST_INITIALIZER;
    pkgconf_list_t filtered_list   = PKGCONF_LIST_INITIALIZER;
    pkgconf_node_t *node;
    pkgconf_fragment_t *frag;
    int count = 0;
    HV *h;
    int eflag;
    int flags;
    int old_flags;
  CODE:
    old_flags = flags = pkgconf_client_get_flags(&client->client);
    if(type % 2)
      flags = flags | PKGCONF_PKG_PKGF_MERGE_PRIVATE_FRAGMENTS;
    pkgconf_client_set_flags(&client->client, flags);
    /*
     * TODO: attribute for max depth
     */
    eflag = type > 1
      ? pkgconf_pkg_cflags(&client->client, self, &unfiltered_list, client->maxdepth)
      : pkgconf_pkg_libs(&client->client,   self, &unfiltered_list, client->maxdepth);
    pkgconf_client_set_flags(&client->client, old_flags);   
    /*
     * TODO: throw an exception
     */
    if(eflag != PKGCONF_PKG_ERRF_OK)
      XSRETURN_EMPTY;
    pkgconf_fragment_filter(&client->client, &filtered_list, &unfiltered_list, directory_filter, NULL);
    PKGCONF_FOREACH_LIST_ENTRY(filtered_list.head, node)
    {
      h = newHV();
      frag = node->data;
      if(frag->type)
        hv_store(h, "type", 4, newSVpvf("%c", frag->type), 0);
      else
        hv_store(h, "type",  4, newSVsv(&PL_sv_undef), 0);
      if(frag->data)
        hv_store(h, "data", 4, newSVpv(frag->data, strlen(frag->data)), 0);
      else
        hv_store(h, "data",  4, newSVsv(&PL_sv_undef), 0);
      ST(count++) = newRV_noinc((SV*) h);
    }
    pkgconf_fragment_free(&filtered_list);
    pkgconf_fragment_free(&unfiltered_list);
    XSRETURN(count);


void
_get_variable(self, client, key)
    pkgconf_pkg_t *self
    my_client_t *client
    const char *key
  INIT:
    pkgconf_node_t *node;
    pkgconf_tuple_t *tup;
  CODE:
    PKGCONF_FOREACH_LIST_ENTRY(self->vars.head, node)
    {
      tup = node->data;
      if(!strcmp(tup->key, key))
      {
        XSRETURN_PV(tup->value);
      }
    }
    XSRETURN_EMPTY;
      

MODULE = PkgConfig::LibPkgConf  PACKAGE = PkgConfig::LibPkgConf::Util


void
argv_split(src)
    const char *src
  INIT:
    int argc, ret, i;
    char **argv;
  PPCODE:
    ret = pkgconf_argv_split(src, &argc, &argv);
    if(ret == 0)
    {
      for(i=0; i<argc; i++)
      {
        XPUSHs(sv_2mortal(newSVpv(argv[i],0)));
      }
      pkgconf_argv_free(argv);
    }
    else
    {
      croak("error in argv_split");
    }


int
compare_version(a,b)
    const char *a
    const char *b
  CODE:
    RETVAL = pkgconf_compare_version(a,b);
  OUTPUT:
    RETVAL


char *
path_sep()
  CODE:
    RETVAL = PKG_CONFIG_PATH_SEP_S;
  OUTPUT:
    RETVAL


#define STRINGIZE(x) #x
#define STRINGIZE_VALUE_OF(x) STRINGIZE(x)


const char *
version()
  CODE:
    RETVAL = STRINGIZE_VALUE_OF(MY_PKGCONF_VERSION);
  OUTPUT:
    RETVAL


SV *
path_relocate(in)
    const char *in;
  INIT:
    char out[PKGCONF_BUFSIZE];
    bool ok;
  CODE:
    strncpy(out, in, PKGCONF_BUFSIZE-1);
    ok = pkgconf_path_relocate(out, sizeof out);
    RETVAL = newSVpv(ok ? out : in, 0);
  OUTPUT:
    RETVAL


MODULE = PkgConfig::LibPkgConf  PACKAGE = PkgConfig::LibPkgConf::Test


IV
send_error(client, msg)
    my_client_t *client
    const char *msg
  CODE:
    RETVAL = pkgconf_error(&client->client, "%s", msg);
  OUTPUT:
    RETVAL
  

void
send_log(client, msg)
    my_client_t *client
    const char *msg
  CODE:
    pkgconf_audit_log(&client->client, "%s", msg);

