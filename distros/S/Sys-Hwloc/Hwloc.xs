/* *******************************************************************
 *
 *  Copyright 2011 Zuse Institute Berlin
 *
 *  This package and its accompanying libraries is free software; you can
 *  redistribute it and/or modify it under the terms of the GPL version 2.0,
 *  or the Artistic License 2.0. Refer to LICENSE for the full license text.
 *
 *  Please send comments to kallies@zib.de
 *
 * *******************************************************************
 * $Id: Hwloc.xs,v 1.40 2011/01/11 10:49:38 bzbkalli Exp $
 * ******************************************************************* */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "hwloc.h"

/*
 * Replacement for non-existing HWLOC_API_VERSION
 */

#ifdef HWLOC_API_VERSION
#  define HWLOC_XSAPI_VERSION HWLOC_API_VERSION
#else
#  define HWLOC_XSAPI_VERSION 0
#endif

/*
 * Hwloc constants
 */

#include "const-c.inc"

/*
 * Macros to store a hash value of given type
 */

#define STOREiv(hv,key,v)  { void *x = hv_store(hv,key,strlen(key),newSViv((IV)v),0);       x = NULL; }
#define STOREuv(hv,key,v)  { void *x = hv_store(hv,key,strlen(key),newSVuv((UV)v),0);       x = NULL; }
#define STOREnv(hv,key,v)  { void *x = hv_store(hv,key,strlen(key),newSVnv((NV)v),0);       x = NULL; }
#define STOREpv(hv,key,v)  { void *x = hv_store(hv,key,strlen(key),newSVpv((char *)v,0),0); x = NULL; }
#define STORErv(hv,key,v)  { void *x = hv_store(hv,key,strlen(key),newRV((SV *)v),0);       x = NULL; }
#define STOREundef(hv,key) { void *x = hv_store(hv,key,strlen(key),&PL_sv_undef,0);         x = NULL; }

/*
 * Static buffer receiving hwloc_snprintf_* output strings
 */

static char sbuf[1024];

/*
 * Convert a hwloc_obj_t into an SV, see also typemap OUTPUT.
 * Used in XSUBs with direct stack manipulation.
 */

static SV *hwlocObj2SV(hwloc_obj_t o) {
  SV *sv = NEWSV(0,0);
  sv_setref_pv(sv, "Sys::Hwloc::Obj", (void *)o);
  return sv;
}

/*
 * Convert an SV into a hwloc_obj_t , see also typemap INPUT
 * If SV is undef and undefIsOK, then NULL is returned.
 * If SV is undef and not undefIsOK, then croak.
 * If SV is not undef and is not a Sys::Hwloc::Obj, then croak.
 * Used in XSUBs with variable argument lists.
 */

static hwloc_obj_t SV2hwlocObj(SV *sv, const char *func, int argi, int undefIsOK) {
  hwloc_obj_t o = NULL;
  if(SvOK(sv)) {
    if(sv_isobject(sv) && sv_derived_from(sv, "Sys::Hwloc::Obj")) {
      o = INT2PTR(hwloc_obj_t, SvIV((SV*)SvRV(sv)));
    } else {
      croak("%s -- arg %d is not a \"Sys::Hwloc::Obj\" object", func, argi);
    }
  } else if(! undefIsOK) {
    croak("%s -- arg %d is not a \"Sys::Hwloc::Obj\" object", func, argi);
  }
  return o;
}

#if HWLOC_XSAPI_VERSION

/*
 * Convert a hwloc_topology_support struct into a HASH.
 */

static HV *hwlocTopologySupport2HV(const struct hwloc_topology_support *s) {
  HV *hv = NULL;
  HV *d  = NULL;
  HV *c  = NULL;
#if HWLOC_XSAPI_VERSION >= 0x00010100
  HV *m  = NULL;
#endif
  if(s) {
    hv = (HV *)sv_2mortal((SV *)newHV());

    d  = (HV *)sv_2mortal((SV *)newHV());
    STOREuv(d, "pu",                     s->discovery->pu);
    STORErv(hv, "discovery", d);

    c  = (HV *)sv_2mortal((SV *)newHV());
    STOREuv(c, "set_thisproc_cpubind",   s->cpubind->set_thisproc_cpubind);
    STOREuv(c, "get_thisproc_cpubind",   s->cpubind->get_thisproc_cpubind);
    STOREuv(c, "set_proc_cpubind",       s->cpubind->set_proc_cpubind);
    STOREuv(c, "get_proc_cpubind",       s->cpubind->get_proc_cpubind);
    STOREuv(c, "set_thisthread_cpubind", s->cpubind->set_thisthread_cpubind);
    STOREuv(c, "get_thisthread_cpubind", s->cpubind->get_thisthread_cpubind);
    STOREuv(c, "set_thread_cpubind",     s->cpubind->set_thread_cpubind);
    STOREuv(c, "get_thread_cpubind",     s->cpubind->get_thread_cpubind);
    STORErv(hv, "cpubind", c);

#if HWLOC_XSAPI_VERSION >= 0x00010100
    m  = (HV *)sv_2mortal((SV *)newHV());
    STOREuv(m, "set_thisproc_membind",   s->membind->set_thisproc_membind);
    STOREuv(m, "get_thisproc_membind",   s->membind->get_thisproc_membind);
    STOREuv(m, "set_proc_membind",       s->membind->set_proc_membind);
    STOREuv(m, "get_proc_membind",       s->membind->get_proc_membind);
    STOREuv(m, "set_thisthread_membind", s->membind->set_thisthread_membind);
    STOREuv(m, "get_thisthread_membind", s->membind->get_thisthread_membind);
    STOREuv(m, "set_area_membind",       s->membind->set_area_membind);
    STOREuv(m, "get_area_membind",       s->membind->get_area_membind);
    STOREuv(m, "alloc_membind",          s->membind->alloc_membind);
    STOREuv(m, "firsttouch_membind",     s->membind->firsttouch_membind);
    STOREuv(m, "bind_membind",           s->membind->bind_membind);
    STOREuv(m, "interleave_membind",     s->membind->interleave_membind);
    STOREuv(m, "replicate_membind",      s->membind->replicate_membind);
    STOREuv(m, "nexttouch_membind",      s->membind->nexttouch_membind);
    STOREuv(m, "migrate_membind",        s->membind->migrate_membind);
    STORErv(hv, "membind", m);
#endif
  }
  return hv;
}

/*
 * Convert a hwloc_obj_memory_page_type_s struct into a HASH.
 */

static HV *hwlocObjMemoryPageType2HV(struct hwloc_obj_memory_page_type_s *s) {
  HV *hv = (HV *)sv_2mortal((SV *)newHV());
  STOREuv(hv, "size",  s->size);
  STOREuv(hv, "count", s->count);
  return hv;
}

/*
 * Convert a hwloc_obj_memory_s struct into a HASH.
 */

static HV *hwlocObjMemory2HV(struct hwloc_obj_memory_s *s) {
  HV *hv = (HV *)sv_2mortal((SV *)newHV());
  AV *av = (AV *)sv_2mortal((SV *)newAV());
  int i;
  STOREuv(hv, "total_memory",   s->total_memory);
  STOREuv(hv, "local_memory",   s->local_memory);
  STOREuv(hv, "page_types_len", s->page_types_len);
  STORErv(hv, "page_types",     av);
  for(i = 0; i < s->page_types_len; i++)
    av_push(av, newRV((SV *)hwlocObjMemoryPageType2HV(&s->page_types[i])));
  return hv;
}
#endif

/*
 * Convert a hwloc_obj_attr union into a HASH.
 * To figure out the needed union member, we need the object type.
 */

static HV *hwlocObjAttr2HV(union hwloc_obj_attr_u *s, hwloc_obj_type_t type) {
  HV *hv = (HV *)sv_2mortal((SV *)newHV());
  HV *a  = NULL;
  if(s) {
    switch(type) {
#if HWLOC_XSAPI_VERSION == 0
      case HWLOC_OBJ_MACHINE:
	a = (HV *)sv_2mortal((SV *)newHV());
	STORErv(hv, "machine", a);
	if(s->machine.dmi_board_vendor) {
	  STOREpv(a, "dmi_board_vendor", s->machine.dmi_board_vendor);
	} else {
	  STOREundef(a, "dmi_board_vendor");
	}
	if(s->machine.dmi_board_name) {
	  STOREpv(a, "dmi_board_name",   s->machine.dmi_board_name);
	} else {
	  STOREundef(a, "dmi_board_name");
	}
        STOREuv(a, "memory_kB",          s->machine.memory_kB);
        STOREuv(a, "huge_page_free",     s->machine.huge_page_free);
        STOREuv(a, "huge_page_size_kB",  s->machine.huge_page_size_kB);
	break;
#else
#if HWLOC_XSAPI_VERSION == 0x00010000
      case HWLOC_OBJ_MACHINE:
	a = (HV *)sv_2mortal((SV *)newHV());
	STORErv(hv, "machine", a);
	if(s->machine.dmi_board_vendor) {
	  STOREpv(a, "dmi_board_vendor", s->machine.dmi_board_vendor);
	} else {
	  STOREundef(a, "dmi_board_vendor");
	}
	if(s->machine.dmi_board_name) {
	  STOREpv(a, "dmi_board_name",   s->machine.dmi_board_name);
	} else {
	  STOREundef(a, "dmi_board_name");
	}
#endif
#endif
      case HWLOC_OBJ_CACHE:
	a = (HV *)sv_2mortal((SV *)newHV());
	STORErv(hv, "cache", a);
	STOREuv(a, "depth",                s->cache.depth);
#if HWLOC_XSAPI_VERSION == 0
	STOREuv(a, "memory_kB",            s->cache.memory_kB);
#else
	STOREuv(a, "size",                 s->cache.size);
#if HWLOC_XSAPI_VERSION >= 0x00010100
	STOREuv(a, "linesize",             s->cache.linesize);
#endif
#endif
        break;
#if HWLOC_XSAPI_VERSION == 0
      case HWLOC_OBJ_MISC:
	a = (HV *)sv_2mortal((SV *)newHV());
	STORErv(hv, "misc", a);
        STOREuv(a, "depth",                 s->misc.depth);
	break;
      case HWLOC_OBJ_NODE:
	a = (HV *)sv_2mortal((SV *)newHV());
	STORErv(hv, "node", a);
        STOREuv(a, "memory_kB",             s->node.memory_kB);
        STOREuv(a, "huge_page_free",        s->node.huge_page_free);
	break;
#endif
#if HWLOC_XSAPI_VERSION
      case HWLOC_OBJ_GROUP:
	a = (HV *)sv_2mortal((SV *)newHV());
	STORErv(hv, "group", a);
        STOREuv(a, "depth",                s->group.depth);
	break;
#endif

      default:
        break;
    }
  }
  return hv;
}

#if HWLOC_XSAPI_VERSION >= 0x00010100

/*
 * Convert an array of hwloc_obj_info_s structs into a HASH.
 */

static HV *hwlocObjInfos2HV(struct hwloc_obj_info_s *s, unsigned n) {
  HV *hv = (HV *)sv_2mortal((SV *)newHV());
  int i;
  for(i = 0; i < n; i++) {
    if(s[i].name) {
      if(s[i].value) {
	STOREpv(hv, s[i].name, s[i].value);
      } else {
	STOREundef(hv, s[i].name);
      }
    }
  }
  return hv;
}
#endif

/*
 * Pretty-print bits set in a cpuset or bitmap.
 * The result string conforms to Linux cpuset(7) list format.
 * Something like that may be present in future hwloc.
 * On success, the number of characters printed is returned (not including trailing '\0').
 * On failure, -1 is returned.
 */

#if HWLOC_XSAPI_VERSION
#if HWLOC_XSAPI_VERSION <= 0x00010000
static int _hwloc_cpuset_list_snprintf(char *buf, size_t buflen, hwloc_const_cpuset_t map) {
  int len = 0;
  int fid, lid, id;

  *buf = '\0';
  fid  = id = hwloc_cpuset_first(map);
  while(id != -1) {
    lid = id;
    id = hwloc_cpuset_next(map, id);
    if((id == -1) || (id > lid + 1)) {
      if(len > 0)
	len += snprintf(buf + len, buflen - len, ",");
      if(fid == lid)
	len += snprintf(buf + len, buflen - len, "%d", fid);
      else if(lid > fid + 1)
	len += snprintf(buf + len, buflen - len, "%d-%d", fid, lid);
      else
	len += snprintf(buf + len, buflen - len, "%d,%d", fid, lid);
      fid = id;
    }
  }
  return len;
}
#else
static int _hwloc_bitmap_list_snprintf(char *buf, size_t buflen, hwloc_const_bitmap_t map) {
  int len = 0;
  int fid, lid, id;

  *buf = '\0';
  fid  = id = hwloc_bitmap_first(map);
  while(id != -1) {
    lid = id;
    id = hwloc_bitmap_next(map, id);
    if((id == -1) || (id > lid + 1)) {
      if(len > 0)
	len += snprintf(buf + len, buflen - len, ",");
      if(fid == lid)
	len += snprintf(buf + len, buflen - len, "%d", fid);
      else if(lid > fid + 1)
	len += snprintf(buf + len, buflen - len, "%d-%d", fid, lid);
      else
	len += snprintf(buf + len, buflen - len, "%d,%d", fid, lid);
      fid = id;
    }
  }
  return len;
}
#endif

/*
 * Convert Linux cpuset(7) list format ASCII string to bitmap.
 * Something like that may be present in future hwloc.
 * Return 0 on success, -1 on error.
 */

#if HWLOC_XSAPI_VERSION <= 0x00010000
static int _hwloc_cpuset_list_sscanf(hwloc_cpuset_t map, const char *s) {
  unsigned a, b;

  if(! s)
    return -1;

  hwloc_cpuset_zero(map);

  do {

    if(! isdigit(*s))
      return -1;

    b = a = strtoul(s, (char **)&s, 10);

    if(*s == '-') {
      s++;
      if(! isdigit(*s))
	return -1;
      b = strtoul(s, (char **)&s, 10);
    }

    if(a > b)
      return -1;

    while(a <= b)
      hwloc_cpuset_set(map, a++);

    if(*s == ',')
      s++;

  } while(*s != '\0' && *s != '\n');

  return 0;

}
#else
static int _hwloc_bitmap_list_sscanf(hwloc_bitmap_t map, const char *s) {
  unsigned a, b;

  if(! map)
    return -1;

  hwloc_bitmap_zero(map);

  do {

    if(! isdigit(*s))
      return -1;

    b = a = strtoul(s, (char **)&s, 10);

    if(*s == '-') {
      s++;
      if(! isdigit(*s))
	return -1;
      b = strtoul(s, (char **)&s, 10);
    }

    if(a > b)
      return -1;

    while(a <= b)
      hwloc_bitmap_set(map, a++);

    if(*s == ',')
      s++;

  } while(*s != '\0' && *s != '\n');

  return 0;

}
#endif
#endif

/* =================================================================== */
/* XS Code below                                                       */
/* =================================================================== */

MODULE = Sys::Hwloc                  PACKAGE = Sys::Hwloc

INCLUDE: const-xs.inc

 # -------------------------------------------------------------------
 # API version (runtime)
 # -------------------------------------------------------------------

#ifdef HAVE_HWLOC_GET_API_VERSION
int
hwloc_get_api_version()
  PROTOTYPE:
  CODE:
    RETVAL = hwloc_get_api_version();
  OUTPUT:
    RETVAL

#else
void
hwloc_get_api_version()
  PROTOTYPE:
  PPCODE:
    XSRETURN_UNDEF;

#endif

 # -------------------------------------------------------------------
 # Topology object types
 # -------------------------------------------------------------------

int
hwloc_compare_types(type1,type2)
  hwloc_obj_type_t type1
  hwloc_obj_type_t type2
  PROTOTYPE: $$
  CODE:
    RETVAL = hwloc_compare_types(type1,type2);
  OUTPUT:
    RETVAL

 # -------------------------------------------------------------------
 # Create and destroy topologies
 # -------------------------------------------------------------------

void
hwloc_topology_check(topo)
  hwloc_topology_t topo
  PROTOTYPE: $
  ALIAS:
    Sys::Hwloc::Topology::check = 1
  PPCODE:
    PERL_UNUSED_VAR(ix);
    hwloc_topology_check(topo);


void
hwloc_topology_destroy(topo)
  hwloc_topology_t topo
  PROTOTYPE: $
  ALIAS:
    Sys::Hwloc::Topology::destroy = 1
  PPCODE:
    PERL_UNUSED_VAR(ix);
    if(topo) {
      hwloc_topology_destroy(topo);
      sv_setref_pv(ST(0), "Sys::Hwloc::Topology", (void *)NULL);
    }


hwloc_topology_t
hwloc_topology_init()
  PROTOTYPE:
  PREINIT:
    hwloc_topology_t t = NULL;
  CODE:  
    if(! hwloc_topology_init(&t))
      RETVAL = t;
    else
      XSRETURN_UNDEF;
  OUTPUT:
     RETVAL


int
hwloc_topology_load(topo)
  hwloc_topology_t topo
  PROTOTYPE: $
  ALIAS:
    Sys::Hwloc::Topology::load = 1
  CODE:
    PERL_UNUSED_VAR(ix);
    RETVAL = hwloc_topology_load(topo);
  OUTPUT:
    RETVAL


 # -------------------------------------------------------------------
 # Configure topology detection
 # -------------------------------------------------------------------

int
hwloc_topology_ignore_type(topo,type)
  hwloc_topology_t topo
  hwloc_obj_type_t type
  PROTOTYPE: $$
  ALIAS:
    Sys::Hwloc::Topology::ignore_type                     = 1
    Sys::Hwloc::hwloc_topology_ignore_type_keep_structure = 10
    Sys::Hwloc::Topology::ignore_type_keep_structure      = 11
  CODE:
    if(ix < 10)
      RETVAL = hwloc_topology_ignore_type(topo,type);
    else if(ix < 20)
      RETVAL = hwloc_topology_ignore_type_keep_structure(topo,type);
    else
      croak("Should not come here in Sys::Hwloc::hwloc_topology_ignore_type, alias = %d", (int)ix);
  OUTPUT:
    RETVAL


int
hwloc_topology_ignore_all_keep_structure(topo)
  hwloc_topology_t topo
  PROTOTYPE: $
  ALIAS:
    Sys::Hwloc::Topology::ignore_all_keep_structure = 1
  CODE:
    PERL_UNUSED_VAR(ix);
    RETVAL = hwloc_topology_ignore_all_keep_structure(topo);
  OUTPUT:
    RETVAL


int
hwloc_topology_set_flags(topo,flags)
  hwloc_topology_t topo
  unsigned         flags
  PROTOTYPE: $$
  ALIAS:
    Sys::Hwloc::Topology::set_flags = 1
  CODE:
    PERL_UNUSED_VAR(ix);
    RETVAL = hwloc_topology_set_flags(topo,flags);
  OUTPUT:
    RETVAL


int
hwloc_topology_set_fsroot(topo,path)
  hwloc_topology_t topo
  const char      *path
  PROTOTYPE: $$
  ALIAS:
    Sys::Hwloc::Topology::set_fsroot = 1
  CODE:
    PERL_UNUSED_VAR(ix);
    RETVAL = hwloc_topology_set_fsroot(topo,path);
  OUTPUT:
    RETVAL


#if HWLOC_XSAPI_VERSION
int
hwloc_topology_set_pid(topo,pid)
  hwloc_topology_t topo
  pid_t            pid
  PROTOTYPE: $$
  ALIAS:
    Sys::Hwloc::Topology::set_pid = 1
  CODE:
    PERL_UNUSED_VAR(ix);
    RETVAL = hwloc_topology_set_pid(topo,pid);
  OUTPUT:
    RETVAL

#endif


int
hwloc_topology_set_synthetic(topo,string)
  hwloc_topology_t  topo
  const char       *string
  PROTOTYPE: $$
  ALIAS:
    Sys::Hwloc::Topology::set_synthetic = 1
  CODE:
    PERL_UNUSED_VAR(ix);
    RETVAL = hwloc_topology_set_synthetic(topo,string);
  OUTPUT:
    RETVAL


int
hwloc_topology_set_xml(topo,path)
  hwloc_topology_t  topo
  const char       *path
  PROTOTYPE: $$
  ALIAS:
    Sys::Hwloc::Topology::set_xml = 1
  CODE:
    PERL_UNUSED_VAR(ix);
    RETVAL = hwloc_topology_set_xml(topo,path);
  OUTPUT:
    RETVAL


#if HWLOC_XSAPI_VERSION
SV *
hwloc_topology_get_support(topo)
  hwloc_topology_t topo
  PROTOTYPE: $
  ALIAS:
    Sys::Hwloc::Topology::get_support = 1
  PREINIT:
    const struct hwloc_topology_support *st = NULL;
  CODE:
    PERL_UNUSED_VAR(ix);
    if((st = hwloc_topology_get_support(topo)))
      RETVAL = newRV((SV *)hwlocTopologySupport2HV(st));
    else
      XSRETURN_UNDEF;
  OUTPUT:
    RETVAL

#endif


 # -------------------------------------------------------------------
 # Tinker with topologies
 # ToDo: hwloc_topology_insert_misc_object_by_cpuset
 # ToDo: hwloc_topology_insert_misc_object_by_parent
 # -------------------------------------------------------------------

#if HWLOC_HAS_XML
void
hwloc_topology_export_xml(topo,path)
  hwloc_topology_t  topo
  const char       *path
  PROTOTYPE: $$
  ALIAS:
    Sys::Hwloc::Topology::export_xml = 1
  PPCODE:
    PERL_UNUSED_VAR(ix);
    hwloc_topology_export_xml(topo,path);

#endif


 # -------------------------------------------------------------------
 # Get some topology information
 # -------------------------------------------------------------------

unsigned
hwloc_topology_get_depth(topo)
  hwloc_topology_t topo
  PROTOTYPE: $
  ALIAS:
    Sys::Hwloc::Topology::get_depth = 1
    Sys::Hwloc::Topology::depth     = 2
  CODE:
    PERL_UNUSED_VAR(ix);
    RETVAL = hwloc_topology_get_depth(topo);
  OUTPUT:
    RETVAL


int
hwloc_get_type_depth(topo,type)
  hwloc_topology_t topo
  hwloc_obj_type_t type
  PROTOTYPE: $$
  ALIAS:
    Sys::Hwloc::Topology::get_type_depth = 1
    Sys::Hwloc::Topology::type_depth     = 2
  CODE:
    PERL_UNUSED_VAR(ix);
    RETVAL = hwloc_get_type_depth(topo,type);
  OUTPUT:
    RETVAL


int
hwloc_get_depth_type(topo,depth)
  hwloc_topology_t topo
  unsigned         depth
  PROTOTYPE: $$
  ALIAS:
    Sys::Hwloc::Topology::get_depth_type = 1
    Sys::Hwloc::Topology::depth_type     = 2
  CODE:
    PERL_UNUSED_VAR(ix);
    RETVAL = hwloc_get_depth_type(topo,depth);
  OUTPUT:
    RETVAL


unsigned
hwloc_get_nbobjs_by_depth(topo,depth)
  hwloc_topology_t topo
  unsigned         depth
  PROTOTYPE: $$
  ALIAS:
    Sys::Hwloc::Topology::get_nbobjs_by_depth = 1
    Sys::Hwloc::Topology::nbobjs_by_depth     = 2
  CODE:
    PERL_UNUSED_VAR(ix);
    RETVAL = hwloc_get_nbobjs_by_depth(topo,depth);
  OUTPUT:
    RETVAL


int
hwloc_get_nbobjs_by_type(topo,type)
  hwloc_topology_t topo
  hwloc_obj_type_t type
  PROTOTYPE: $$
  ALIAS:
    Sys::Hwloc::Topology::get_nbobjs_by_type = 1
    Sys::Hwloc::Topology::nbobjs_by_type     = 2
  CODE:
    PERL_UNUSED_VAR(ix);
    RETVAL = hwloc_get_nbobjs_by_type(topo,type);
  OUTPUT:
    RETVAL


int
hwloc_topology_is_thissystem(topo)
  hwloc_topology_t topo
  PROTOTYPE: $
  ALIAS:
    Sys::Hwloc::Topology::is_thissystem = 1
  CODE:
    PERL_UNUSED_VAR(ix);
    RETVAL = hwloc_topology_is_thissystem(topo);
  OUTPUT:
    RETVAL


 # -------------------------------------------------------------------
 # Retrieve objects
 # -------------------------------------------------------------------

hwloc_obj_t
hwloc_get_obj_by_depth(topo,depth,idx)
  hwloc_topology_t  topo
  unsigned          depth
  unsigned          idx
  PROTOTYPE: $$$
  ALIAS:
    Sys::Hwloc::Topology::get_obj_by_depth = 1
    Sys::Hwloc::Topology::obj_by_depth     = 2
  CODE:
    PERL_UNUSED_VAR(ix);
    RETVAL = hwloc_get_obj_by_depth(topo,depth,idx);
  OUTPUT:
    RETVAL


hwloc_obj_t
hwloc_get_obj_by_type(topo,type,idx)
  hwloc_topology_t  topo
  hwloc_obj_type_t  type
  unsigned          idx
  PROTOTYPE: $$$
  ALIAS:
    Sys::Hwloc::Topology::get_obj_by_type = 1
    Sys::Hwloc::Topology::obj_by_type     = 2
  CODE:
    PERL_UNUSED_VAR(ix);
    RETVAL = hwloc_get_obj_by_type(topo,type,idx);
  OUTPUT:
    RETVAL



 # -------------------------------------------------------------------
 # Object/string conversion
 # -------------------------------------------------------------------

const char *
hwloc_obj_type_string(type)
  hwloc_obj_type_t type
  PROTOTYPE: $
  CODE:
    const char *s;
    if((s = hwloc_obj_type_string(type)))
      RETVAL = s;
    else
      XSRETURN_UNDEF;
  OUTPUT:
    RETVAL


int
hwloc_obj_type_of_string(string)
  const char *string
  PROTOTYPE: $
  CODE:
    RETVAL = hwloc_obj_type_of_string(string);
  OUTPUT:
    RETVAL


#if HWLOC_XSAPI_VERSION
SV *
hwloc_obj_type_sprintf(obj, ...)
  hwloc_obj_t obj
  PROTOTYPE: $;$
  ALIAS:
    Sys::Hwloc::Obj::sprintf_type = 1
  PREINIT:
    int rc;
    int verbose = 0;
  CODE:
    PERL_UNUSED_VAR(ix);
    if((items > 1) && (SvIOK(ST(1))))
      verbose = SvIV(ST(1));
    if((rc = hwloc_obj_type_snprintf(sbuf, sizeof(sbuf), obj, verbose)) == -1)
      XSRETURN_UNDEF;
    else
      RETVAL = newSVpvn(sbuf,(STRLEN)rc);
  OUTPUT:
    RETVAL

#endif


#if HWLOC_XSAPI_VERSION
SV *
hwloc_obj_attr_sprintf(obj, ...)
  hwloc_obj_t obj
  PROTOTYPE: $;$$
  ALIAS:
    Sys::Hwloc::Obj::sprintf_attr = 1
  PREINIT:
    int   rc;
    char *separator = "";
    int   verbose   = 0;
  CODE:
    PERL_UNUSED_VAR(ix);
    if((items > 1) && (SvOK(ST(1))))
      separator = SvPV_nolen(ST(1));
    if((items > 2) && (SvIOK(ST(2))))
      verbose   = SvIV(ST(2));
    if((rc = hwloc_obj_attr_snprintf(sbuf, sizeof(sbuf), obj, separator, verbose)) == -1)
      XSRETURN_UNDEF;
    else
      RETVAL = newSVpvn(sbuf,(STRLEN)rc);
  OUTPUT:
    RETVAL

#endif


SV *
hwloc_obj_sprintf(...)
  PROTOTYPE: DISABLE
  ALIAS:
    Sys::Hwloc::Topology::sprintf_obj = 1
    Sys::Hwloc::Obj::sprintf          = 2
  CODE:
    hwloc_obj_t   obj     = NULL;
    char         *prefix  = NULL;
    int           verbose = 0;
    int           rc;
    if(ix == 0) {
      if(items < 2)
	croak("Not enough arguments for Sys::Hwloc::hwloc_obj_sprintf");
      obj = SV2hwlocObj(ST(1), "Sys::Hwloc::hwloc_obj_sprintf()", 1, 0);
      if((items > 2) && (SvOK(ST(2))))
        prefix  = SvPV_nolen(ST(2));
      if((items > 3) && (SvIOK(ST(3))))
        verbose = SvIV(ST(3));
    } else if(ix == 1) {
      if(items < 2)
	croak("Not enough arguments for Sys::Hwloc::Topology->sprintf_obj");
      obj = SV2hwlocObj(ST(1), "Sys::Hwloc::Topology->sprintf_obj()", 1, 0);
      if((items > 2) && (SvOK(ST(2))))
        prefix  = SvPV_nolen(ST(2));
      if((items > 3) && (SvIOK(ST(3))))
        verbose = SvIV(ST(3));
    } else if(ix == 2) {
      if(items < 1)
        croak("Not enough arguments for Sys::Hwloc::Obj->sprintf");
      obj = SV2hwlocObj(ST(0), "Sys::Hwloc::Obj->sprintf()", 0, 0);
      if((items > 1) && (SvOK(ST(1))))
        prefix  = SvPV_nolen(ST(1));
      if((items > 2) && (SvIOK(ST(2))))
        verbose = SvIV(ST(2));
    } else {
      croak("Should not come here in Sys::Hwloc::hwloc_obj_sprintf");
    }
    if((rc = hwloc_obj_snprintf(sbuf, sizeof(sbuf), NULL, obj, prefix, verbose)) == -1)
      XSRETURN_UNDEF;
    else
      RETVAL = newSVpvn(sbuf,(STRLEN)rc);
  OUTPUT:
    RETVAL


SV *
hwloc_obj_cpuset_sprintf(...)
  PROTOTYPE: DISABLE
  ALIAS:
    Sys::Hwloc::Obj::sprintf_cpuset = 1
  PREINIT:
    hwloc_obj_t *objs = NULL;
    int i;
    int rc;
  CODE:
    if(items > 0) {
      if((ix == 1) && (items > 1))
	croak("Usage: sprintf_cpuset()");
      if((objs = (hwloc_obj_t *)malloc(items * sizeof(hwloc_obj_t *))) == NULL)
	croak("Failed to allocate memory");
      for(i = 0; i < items; i++)
	objs[i] = SV2hwlocObj(ST(i), "Sys::Hwloc::hwloc_obj_cpuset_sprintf()", i, 0);
    } else {
      if(ix)
	croak("Not enough arguments for Sys::Hwloc::Obj->sprintf_cpuset");
    }
    if((rc = hwloc_obj_cpuset_snprintf(sbuf, sizeof(sbuf), items, objs)) == -1) {
      if(objs)
        free(objs);
      XSRETURN_UNDEF;
    } else {
      RETVAL = newSVpvn(sbuf,(STRLEN)rc);
      if(objs)
	free(objs);
    }
  OUTPUT:
    RETVAL


#if HWLOC_XSAPI_VERSION >= 0x00010100
SV *
hwloc_obj_get_info_by_name(obj,name)
  hwloc_obj_t  obj
  const char  *name
  PROTOTYPE: $$
  ALIAS:
    Sys::Hwloc::Obj::get_info_by_name = 1
    Sys::Hwloc::Obj::info_by_name     = 2
  CODE:
    PERL_UNUSED_VAR(ix);
    RETVAL = newSVpv(hwloc_obj_get_info_by_name(obj,name),(STRLEN)0);
  OUTPUT:
    RETVAL

#endif
  

 # -------------------------------------------------------------------
 # CPU Binding
 # -------------------------------------------------------------------

#if HWLOC_XSAPI_VERSION >= 0x00010100
int
hwloc_get_cpubind(topo,set,flags)
  hwloc_topology_t topo
  hwloc_bitmap_t   set
  int              flags
  PROTOTYPE: $$$
  ALIAS:
    Sys::Hwloc::Topology::get_cpubind = 1
    Sys::Hwloc::hwloc_set_cpubind     = 10
    Sys::Hwloc::Topology::set_cpubind = 11
  CODE:
    if(ix < 10)
      RETVAL = hwloc_get_cpubind(topo,set,flags);
    else if(ix < 20)
      RETVAL = hwloc_set_cpubind(topo,set,flags);
    else
      croak("Should not come here in Sys::Hwloc::hwloc_get_cpubind, alias = %d", (int)ix);
  OUTPUT:
    RETVAL


int
hwloc_get_proc_cpubind(topo,pid,set,flags)
  hwloc_topology_t topo
  pid_t            pid
  hwloc_bitmap_t   set
  int              flags
  PROTOTYPE: $$$$
  ALIAS:
    Sys::Hwloc::Topology::get_proc_cpubind = 1
    Sys::Hwloc::hwloc_set_proc_cpubind     = 10
    Sys::Hwloc::Topology::set_proc_cpubind = 11
  CODE:
    if(ix < 10)
      RETVAL = hwloc_get_proc_cpubind(topo,pid,set,flags);
    else if(ix < 20)
      RETVAL = hwloc_set_proc_cpubind(topo,pid,set,flags);
    else
      croak("Should not come here in Sys::Hwloc::hwloc_get_proc_cpubind, alias = %d", (int)ix);
  OUTPUT:
    RETVAL

#else
#if HWLOC_XSAPI_VERSION
int
hwloc_get_cpubind(topo,set,flags)
  hwloc_topology_t topo
  hwloc_cpuset_t   set
  int              flags
  PROTOTYPE: $$$
  ALIAS:
    Sys::Hwloc::Topology::get_cpubind = 1
  CODE:
    PERL_UNUSED_VAR(ix);
    RETVAL = hwloc_get_cpubind(topo,set,flags);
  OUTPUT:
    RETVAL


int
hwloc_get_proc_cpubind(topo,pid,set,flags)
  hwloc_topology_t topo
  pid_t            pid
  hwloc_cpuset_t   set
  int              flags
  PROTOTYPE: $$$$
  ALIAS:
    Sys::Hwloc::Topology::get_proc_cpubind = 1
  CODE:
    PERL_UNUSED_VAR(ix);
    RETVAL = hwloc_get_proc_cpubind(topo,pid,set,flags);
  OUTPUT:
    RETVAL

#endif
int
hwloc_set_cpubind(topo,set,flags)
  hwloc_topology_t topo
  hwloc_cpuset_t   set
  int              flags
  PROTOTYPE: $$$
  ALIAS:
    Sys::Hwloc::Topology::set_cpubind = 1
  CODE:
    PERL_UNUSED_VAR(ix);
    RETVAL = hwloc_set_cpubind(topo,set,flags);
  OUTPUT:
    RETVAL


int
hwloc_set_proc_cpubind(topo,pid,set,flags)
  hwloc_topology_t topo
  pid_t            pid
  hwloc_cpuset_t   set
  int              flags
  PROTOTYPE: $$$$
  ALIAS:
    Sys::Hwloc::Topology::set_proc_cpubind = 1
  CODE:
    PERL_UNUSED_VAR(ix);
    RETVAL = hwloc_set_proc_cpubind(topo,pid,set,flags);
  OUTPUT:
    RETVAL

#endif

 # -------------------------------------------------------------------
 # Memory binding
 # -------------------------------------------------------------------

#if HWLOC_XSAPI_VERSION >= 0x00010100
int
hwloc_set_membind(topo,set,policy,flags)
  hwloc_topology_t topo
  hwloc_bitmap_t   set
  int              policy
  int              flags
  PROTOTYPE: $$$$
  ALIAS:
    Sys::Hwloc::Topology::set_membind         = 1
    Sys::Hwloc::hwloc_set_membind_nodeset     = 10
    Sys::Hwloc::Topology::set_membind_nodeset = 11
  CODE:
    if(ix < 10)
      RETVAL = hwloc_set_membind(topo,set,policy,flags);
    else if(ix < 20)
      RETVAL = hwloc_set_membind_nodeset(topo,set,policy,flags);
    else
      croak("Should not come here in Sys::Hwloc::hwloc_set_membind, alias = %d", (int)ix);
  OUTPUT:
    RETVAL
  

int
hwloc_set_proc_membind(topo,pid,set,policy,flags)
  hwloc_topology_t topo
  pid_t            pid
  hwloc_bitmap_t   set
  int              policy
  int              flags
  PROTOTYPE: $$$$$
  ALIAS:
    Sys::Hwloc::Topology::set_proc_membind         = 1
    Sys::Hwloc::hwloc_set_proc_membind_nodeset     = 10
    Sys::Hwloc::Topology::set_proc_membind_nodeset = 11
  CODE:
    if(ix < 10)
      RETVAL = hwloc_set_proc_membind(topo,pid,set,policy,flags);
    else if(ix < 20)
      RETVAL = hwloc_set_proc_membind_nodeset(topo,pid,set,policy,flags);
    else
      croak("Should not come here in Sys::Hwloc::hwloc_set_proc_membind, alias = %d", (int)ix);
  OUTPUT:
    RETVAL


int
hwloc_get_membind(topo,set,policy,flags)
  hwloc_topology_t topo
  hwloc_bitmap_t   set
  SV              *policy
  int              flags
  PROTOTYPE: $$$$
  ALIAS:
    Sys::Hwloc::Topology::get_membind         = 1
    Sys::Hwloc::hwloc_get_membind_nodeset     = 10
    Sys::Hwloc::Topology::get_membind_nodeset = 11
  PREINIT:
    hwloc_membind_policy_t  p;
    SV                     *pv;
  CODE:
    if(! SvROK(policy))
      croak("Usage: Sys::Hwloc::hwloc_get_membind($topo,$set,\\$policy,$flags)");
    pv = SvRV(policy);
    if(ix < 10)
      RETVAL = hwloc_get_membind(topo,set,&p,flags);
    else if(ix < 20)
      RETVAL = hwloc_get_membind_nodeset(topo,set,&p,flags);
    else
      croak("Should not come here in Sys::Hwloc::hwloc_get_membind, alias = %d", (int)ix);
    sv_setiv(pv, (int)p);
  OUTPUT:
    RETVAL

int
hwloc_get_proc_membind(topo,pid,set,policy,flags)
  hwloc_topology_t topo
  pid_t            pid
  hwloc_bitmap_t   set
  SV              *policy
  int              flags
  PROTOTYPE: $$$$$
  ALIAS:
    Sys::Hwloc::Topology::get_proc_membind         = 1
    Sys::Hwloc::hwloc_get_proc_membind_nodeset     = 10
    Sys::Hwloc::Topology::get_proc_membind_nodeset = 11
  PREINIT:
    hwloc_membind_policy_t  p;
    SV                     *pv;
  CODE:
    if(! SvROK(policy))
      croak("Usage: Sys::Hwloc::hwloc_get_proc_membind($topo,$pid,$set,\\$policy,$flags)");
    pv = SvRV(policy);
    if(ix < 10)
      RETVAL = hwloc_get_proc_membind(topo,pid,set,&p,flags);
    else if(ix < 20)
      RETVAL = hwloc_get_proc_membind_nodeset(topo,pid,set,&p,flags);
    else
      croak("Should not come here in Sys::Hwloc::hwloc_get_proc_membind, alias = %d", (int)ix);
    sv_setiv(pv, (int)p);
  OUTPUT:
    RETVAL

#endif

 # -------------------------------------------------------------------
 # Object type helpers
 # -------------------------------------------------------------------

int
hwloc_get_type_or_below_depth(topo,type)
  hwloc_topology_t topo
  hwloc_obj_type_t type
  PROTOTYPE: $$
  ALIAS:
    Sys::Hwloc::Topology::get_type_or_below_depth = 1
    Sys::Hwloc::Topology::type_or_below_depth     = 2
    Sys::Hwloc::hwloc_get_type_or_above_depth     = 10
    Sys::Hwloc::Topology::get_type_or_above_depth = 11
    Sys::Hwloc::Topology::type_or_above_depth     = 12
  CODE:
    if(ix < 10)
      RETVAL = hwloc_get_type_or_below_depth(topo,type);
    else if(ix < 20)
      RETVAL = hwloc_get_type_or_above_depth(topo,type);
    else
      croak("Should not come here in Sys::Hwloc::hwloc_get_type_or_below_depth, alias = %d", (int)ix);
  OUTPUT:
    RETVAL


 # -------------------------------------------------------------------
 # Basic traversal helpers
 # -------------------------------------------------------------------


#if HWLOC_XSAPI_VERSION == 0
hwloc_obj_t
hwloc_get_system_obj(topo)
  hwloc_topology_t topo
  PROTOTYPE: $
  ALIAS:
    Sys::Hwloc::Topology::system_obj = 1
    Sys::Hwloc::Topology::system     = 2
  CODE:
    PERL_UNUSED_VAR(ix);
    RETVAL = hwloc_get_system_obj(topo);
  OUTPUT:
    RETVAL

#else
hwloc_obj_t
hwloc_get_root_obj(topo)
  hwloc_topology_t topo
  PROTOTYPE: $
  ALIAS:
    Sys::Hwloc::Topology::root_obj   = 1
    Sys::Hwloc::Topology::root       = 2
  CODE:
    PERL_UNUSED_VAR(ix);
    RETVAL = hwloc_get_root_obj(topo);
  OUTPUT:
    RETVAL

#endif


#if HWLOC_XSAPI_VERSION
hwloc_obj_t
hwloc_get_ancestor_obj_by_depth(obj,depth)
  hwloc_obj_t obj
  unsigned    depth
  PROTOTYPE: $$
  ALIAS:
    Sys::Hwloc::Obj::get_ancestor_by_depth = 1
    Sys::Hwloc::Obj::ancestor_by_depth     = 2
  CODE:
    PERL_UNUSED_VAR(ix);
    RETVAL = hwloc_get_ancestor_obj_by_depth(NULL,depth,obj);
  OUTPUT:
    RETVAL


hwloc_obj_t
hwloc_get_ancestor_obj_by_type(obj,type)
  hwloc_obj_t      obj
  hwloc_obj_type_t type
  PROTOTYPE: $$
  ALIAS:
    Sys::Hwloc::Obj::get_ancestor_by_type = 1
    Sys::Hwloc::Obj::ancestor_by_type     = 2
  CODE:
    PERL_UNUSED_VAR(ix);
    RETVAL = hwloc_get_ancestor_obj_by_type(NULL,type,obj);
  OUTPUT:
    RETVAL

#endif


hwloc_obj_t
hwloc_get_next_obj_by_depth(topo,depth,prev)
  hwloc_topology_t topo
  unsigned         depth
  SV              *prev
  PROTOTYPE: $$$
  ALIAS:
    Sys::Hwloc::Topology::get_next_obj_by_depth = 1
    Sys::Hwloc::Topology::next_obj_by_depth     = 2
  PREINIT:
    hwloc_obj_t    o = NULL;
  CODE:
    PERL_UNUSED_VAR(ix);
    o      = SV2hwlocObj(prev, "Sys::Hwloc::hwloc_get_next_obj_by_depth()", 3, 1);
    RETVAL = hwloc_get_next_obj_by_depth(topo,depth,o);
  OUTPUT:
    RETVAL


hwloc_obj_t
hwloc_get_next_obj_by_type(topo,type,prev)
  hwloc_topology_t topo
  hwloc_obj_type_t type
  SV              *prev
  PROTOTYPE: $$$
  ALIAS:
    Sys::Hwloc::Topology::get_next_obj_by_type = 1
    Sys::Hwloc::Topology::next_obj_by_type     = 2
  PREINIT:
    hwloc_obj_t    o = NULL;
  CODE:
    PERL_UNUSED_VAR(ix);
    o      = SV2hwlocObj(prev, "Sys::Hwloc::hwloc_get_next_obj_by_type()", 3, 1);
    RETVAL = hwloc_get_next_obj_by_type(topo,type,o);
  OUTPUT:
    RETVAL


#if HWLOC_XSAPI_VERSION
hwloc_obj_t
hwloc_get_pu_obj_by_os_index(topo,idx)
  hwloc_topology_t topo
  unsigned         idx
  PROTOTYPE: $$
  ALIAS:
    Sys::Hwloc::Topology::get_pu_obj_by_os_index = 1
    Sys::Hwloc::Topology::pu_obj_by_os_index     = 2
  CODE:
    PERL_UNUSED_VAR(ix);
    RETVAL = hwloc_get_pu_obj_by_os_index(topo,idx);
  OUTPUT:
    RETVAL

#endif


hwloc_obj_t
hwloc_get_next_child(obj,prev)
  hwloc_obj_t   obj
  SV           *prev
  PROTOTYPE: $$
  ALIAS:
    Sys::Hwloc::Obj::get_next_child = 1
    Sys::Hwloc::Obj::next_child     = 2
  PREINIT:
    hwloc_obj_t o = NULL;
  CODE:
    PERL_UNUSED_VAR(ix);
    o      = SV2hwlocObj(prev, "Sys::Hwloc::hwloc_get_next_child()", 2, 1);
    RETVAL = hwloc_get_next_child(NULL,obj,o);
  OUTPUT:
    RETVAL


hwloc_obj_t
hwloc_get_common_ancestor_obj(topo,obj1,obj2)
  hwloc_topology_t topo
  hwloc_obj_t      obj1
  hwloc_obj_t      obj2
  PROTOTYPE: $$$
  ALIAS:
    Sys::Hwloc::Topology::get_common_ancestor_obj = 1
    Sys::Hwloc::Topology::common_ancestor_obj     = 2
  CODE:
    PERL_UNUSED_VAR(ix);
    RETVAL = hwloc_get_common_ancestor_obj(NULL,obj1,obj2);
  OUTPUT:
    RETVAL


int
hwloc_obj_is_in_subtree(topo,obj1,obj2)
  hwloc_topology_t topo
  hwloc_obj_t      obj1
  hwloc_obj_t      obj2
  PROTOTYPE: $$$
  ALIAS:
    Sys::Hwloc::Topology::obj_is_in_subtree = 1
  CODE:
    PERL_UNUSED_VAR(ix);
    RETVAL = hwloc_obj_is_in_subtree(NULL,obj1,obj2);
  OUTPUT:
    RETVAL


int
hwloc_compare_objects(topo,obj1,obj2)
  hwloc_topology_t  topo
  SV               *obj1
  SV               *obj2
  PROTOTYPE: $$$
  ALIAS:
    Sys::Hwloc::Topology::compare_objects = 1
  PREINIT:
    hwloc_obj_t o1 = NULL;
    hwloc_obj_t o2 = NULL;
  CODE:
    PERL_UNUSED_VAR(ix);
    o1 = SV2hwlocObj(obj1, "Sys::Hwloc::hwloc_compare_objects", 1, 1);
    o2 = SV2hwlocObj(obj2, "Sys::Hwloc::hwloc_compare_objects", 2, 1);
    RETVAL = (o1 == o2) ? 1 : 0;
  OUTPUT:
    RETVAL


 # -------------------------------------------------------------------
 # Advanced traversal helpers
 # -------------------------------------------------------------------

void
hwloc_get_closest_objs(topo,obj)
  hwloc_topology_t topo
  hwloc_obj_t      obj
  PROTOTYPE: $$
  ALIAS:
    Sys::Hwloc::Topology::get_closest_objs = 1
  PREINIT:
    int rc;
    int i;
    hwloc_obj_t *objs = NULL;
  PPCODE:
    PERL_UNUSED_VAR(ix);
    if((objs = (hwloc_obj_t *)malloc(1024 * sizeof(hwloc_obj_t *))) == NULL)
      croak("Failed to allocate memory");
    rc = hwloc_get_closest_objs(topo,obj,objs,1024);
    if(rc < 0)
      rc = 0;
    EXTEND(SP, rc);
    for(i = 0; i < rc; i++)
      PUSHs(sv_2mortal(hwlocObj2SV(objs[i])));
    free(objs);
    XSRETURN(rc);


#if HWLOC_XSAPI_VERSION
hwloc_obj_t
hwloc_get_obj_below_by_type(topo,type1,idx1,type2,idx2)
  hwloc_topology_t topo
  int              type1
  unsigned         idx1
  int              type2
  unsigned         idx2
  PROTOTYPE: $$$$$
  ALIAS:
    Sys::Hwloc::Topology::get_obj_below_by_type = 1
  CODE:
    PERL_UNUSED_VAR(ix);
    RETVAL = hwloc_get_obj_below_by_type(topo,type1,idx1,type2,idx2);
  OUTPUT:
    RETVAL

#endif


 # -------------------------------------------------------------------
 # Cpuset/Bitmap API
 # -------------------------------------------------------------------

#if HWLOC_XSAPI_VERSION <= 0x00010000
INCLUDE: hwloc_cpuset.xsh

#else
INCLUDE: hwloc_bitmap.xsh

#endif
    

 # ===================================================================
 # PACKAGE Sys::Hwloc::Topology, OO interface of hwloc_topology_t
 # ===================================================================

MODULE = Sys::Hwloc                  PACKAGE = Sys::Hwloc::Topology

 # -------------------------------------------------------------------
 # Constructor only, other methods are aliased from package Sys::Hwloc
 # -------------------------------------------------------------------

hwloc_topology_t
init(void)
  PROTOTYPE:
  ALIAS:
    new = 1
  PREINIT:
    hwloc_topology_t t = NULL;
  CODE:
    PERL_UNUSED_VAR(ix);
    if(! hwloc_topology_init(&t))
      RETVAL = t;
    else
      XSRETURN_UNDEF;
  OUTPUT:
     RETVAL



 # ===================================================================
 # PACKAGE Sys::Hwloc::Obj, OO interface of hwloc_obj_t
 # ===================================================================

MODULE = Sys::Hwloc                  PACKAGE = Sys::Hwloc::Obj

hwloc_obj_type_t
type(o)
  hwloc_obj_t o
  PROTOTYPE: $
  CODE:
    RETVAL = o->type;
  OUTPUT:
    RETVAL


unsigned
os_index(o)
  hwloc_obj_t o
  PROTOTYPE: $
  CODE:
    RETVAL = o->os_index;
  OUTPUT:
    RETVAL


SV *
name(o)
  hwloc_obj_t o
  PROTOTYPE: $
  CODE:
    if(o->name)
      RETVAL = newSVpv(o->name,0);
    else
      XSRETURN_UNDEF;
  OUTPUT:
    RETVAL


#if HWLOC_XSAPI_VERSION
SV *
memory(o)
  hwloc_obj_t o
  PROTOTYPE: $
  CODE:
    RETVAL = newRV((SV *)hwlocObjMemory2HV(&o->memory));
  OUTPUT:
    RETVAL

#endif


SV *
attr(o)
  hwloc_obj_t o
  PROTOTYPE: $
  PREINIT:
    HV *hv = NULL;
  CODE:
    if((hv = hwlocObjAttr2HV(o->attr, o->type)))
      RETVAL = newRV((SV *)hv);
    else
      XSRETURN_UNDEF;
  OUTPUT:
    RETVAL


unsigned
depth(o)
  hwloc_obj_t o
  PROTOTYPE: $
  CODE:
    RETVAL = o->depth;
  OUTPUT:
    RETVAL


unsigned
logical_index(o)
  hwloc_obj_t o
  PROTOTYPE: $
  CODE:
    RETVAL = o->logical_index;
  OUTPUT:
    RETVAL


int
os_level(o)
  hwloc_obj_t o
  PROTOTYPE: $
  CODE:
    RETVAL = o->os_level;
  OUTPUT:
    RETVAL


hwloc_obj_t
next_cousin(o)
  hwloc_obj_t o
  PROTOTYPE: $
  CODE:
    RETVAL = o->next_cousin;
  OUTPUT:
    RETVAL


hwloc_obj_t
prev_cousin(o)
  hwloc_obj_t o
  PROTOTYPE: $
  CODE:
    RETVAL = o->prev_cousin;
  OUTPUT:
    RETVAL


#if HWLOC_XSAPI_VERSION == 0
hwloc_obj_t
father(o)
  hwloc_obj_t o
  PROTOTYPE: $
  CODE:
    RETVAL = o->father;
  OUTPUT:
    RETVAL

#else
hwloc_obj_t
parent(o)
  hwloc_obj_t o
  PROTOTYPE: $
  CODE:
    RETVAL = o->parent;
  OUTPUT:
    RETVAL

#endif


unsigned
sibling_rank(o)
  hwloc_obj_t o
  PROTOTYPE: $
  CODE:
    RETVAL = o->sibling_rank;
  OUTPUT:
    RETVAL


hwloc_obj_t
next_sibling(o)
  hwloc_obj_t o
  PROTOTYPE: $
  CODE:
    RETVAL = o->next_sibling;
  OUTPUT:
    RETVAL


hwloc_obj_t
prev_sibling(o)
  hwloc_obj_t o
  PROTOTYPE: $
  CODE:
    RETVAL = o->prev_sibling;
  OUTPUT:
    RETVAL


unsigned
arity(o)
  hwloc_obj_t o
  PROTOTYPE: $
  CODE:
    RETVAL = o->arity;
  OUTPUT:
    RETVAL


void
children(o)
  hwloc_obj_t o
  PROTOTYPE: $
  PREINIT:
    int i;
  PPCODE:
    EXTEND(SP, o->arity);
    for(i = 0; i < o->arity; i++)
      PUSHs(sv_2mortal(hwlocObj2SV(o->children[i])));
    XSRETURN(o->arity);


hwloc_obj_t
first_child(o)
  hwloc_obj_t o
  PROTOTYPE: $
  CODE:
    RETVAL = o->first_child;
  OUTPUT:
    RETVAL


hwloc_obj_t
last_child(o)
  hwloc_obj_t o
  PROTOTYPE: $
  CODE:
    RETVAL = o->last_child;
  OUTPUT:
    RETVAL


#if HWLOC_XSAPI_VERSION < 0x00010100
hwloc_cpuset_t
cpuset(o)
  hwloc_obj_t o
  PROTOTYPE: $
  CODE:
    RETVAL = o->cpuset;
  OUTPUT:
    RETVAL

#if HWLOC_XSAPI_VERSION
hwloc_cpuset_t
complete_cpuset(o)
  hwloc_obj_t o
  PROTOTYPE: $
  ALIAS:
    Sys::Hwloc::Obj::online_cpuset   = 1
    Sys::Hwloc::Obj::allowed_cpuset  = 2
  CODE:
    if(ix == 0)
      RETVAL = o->complete_cpuset;
    else if(ix == 1)
      RETVAL = o->online_cpuset;
    else if(ix == 2)
      RETVAL = o->allowed_cpuset;
    else
      croak("Should not come here in Sys::Hwloc::Obj->complete_cpuset, alias = %d", (int)ix);
  OUTPUT:
    RETVAL

#endif

#else
hwloc_bitmap_t
cpuset(o)
  hwloc_obj_t o
  PROTOTYPE: $
  ALIAS:
    Sys::Hwloc::Obj::complete_cpuset = 1
    Sys::Hwloc::Obj::online_cpuset   = 2
    Sys::Hwloc::Obj::allowed_cpuset  = 3
  CODE:
    if(ix == 0)
      RETVAL = o->cpuset;
    else if(ix == 1)
      RETVAL = o->complete_cpuset;
    else if(ix == 2)
      RETVAL = o->online_cpuset;
    else if(ix == 3)
      RETVAL = o->allowed_cpuset;
    else
      croak("Should not come here in Sys::Hwloc::Obj->cpuset, alias = %d", (int)ix);
  OUTPUT:
    RETVAL

#endif


#if HWLOC_XSAPI_VERSION
#if HWLOC_XSAPI_VERSION < 0x00010100
hwloc_cpuset_t
nodeset(o)
  hwloc_obj_t o
  PROTOTYPE: $
  ALIAS:
    Sys::Hwloc::Obj::complete_nodeset = 1
    Sys::Hwloc::Obj::allowed_nodeset  = 3
  CODE:
    if(ix == 0)
      RETVAL = o->nodeset;
    else if(ix == 1)
      RETVAL = o->complete_nodeset;
    else if(ix == 3)
      RETVAL = o->allowed_nodeset;
    else
      croak("Should not come here in Sys::Hwloc::Obj->nodeset, alias = %d", (int)ix);
  OUTPUT:
    RETVAL

#else
hwloc_bitmap_t
nodeset(o)
  hwloc_obj_t o
  PROTOTYPE: $
  ALIAS:
    Sys::Hwloc::Obj::complete_nodeset = 1
    Sys::Hwloc::Obj::allowed_nodeset  = 3
  CODE:
    if(ix == 0)
      RETVAL = o->nodeset;
    else if(ix == 1)
      RETVAL = o->complete_nodeset;
    else if(ix == 3)
      RETVAL = o->allowed_nodeset;
    else
      croak("Should not come here in Sys::Hwloc::Obj->nodeset, alias = %d", (int)ix);
  OUTPUT:
    RETVAL

#endif
#endif


#if HWLOC_XSAPI_VERSION >= 0x00010100
SV *
infos(o)
  hwloc_obj_t o
  PROTOTYPE: $
  PREINIT:
    HV *hv = NULL;
  CODE:
    if((hv = hwlocObjInfos2HV(o->infos, o->infos_count)))
      RETVAL = newRV((SV *)hv);
    else
      XSRETURN_UNDEF;
  OUTPUT:
    RETVAL

#endif


hwloc_obj_t
get_common_ancestor(o1,o2)
  hwloc_obj_t o1
  hwloc_obj_t o2
  PROTOTYPE: $$
  ALIAS:
    common_ancestor = 1
  CODE:
    PERL_UNUSED_VAR(ix);
    RETVAL = hwloc_get_common_ancestor_obj(NULL,o1,o2);
  OUTPUT:
    RETVAL


int
is_in_subtree(o1,o2)
  hwloc_obj_t o1
  hwloc_obj_t o2
  PROTOTYPE: $$
  CODE:
    RETVAL = hwloc_obj_is_in_subtree(NULL,o1,o2);
  OUTPUT:
    RETVAL


int
is_same_obj(o1,o2)
  hwloc_obj_t   o1
  SV           *o2
  PROTOTYPE: $$
  PREINIT:
    hwloc_obj_t o = NULL;
  CODE:
    o = SV2hwlocObj(o2, "Sys::Hwloc::Obj->is_same_obj()", 1, 1);
    RETVAL = (o1 == o) ? 1 : 0;
  OUTPUT:
    RETVAL


#if HWLOC_XSAPI_VERSION <= 0x00010000

 # ===================================================================
 # PACKAGE Sys::Hwloc::Cpuset, OO interface of hwloc_cpuset_t
 # ===================================================================

MODULE = Sys::Hwloc                  PACKAGE = Sys::Hwloc::Cpuset

hwloc_cpuset_t
alloc(void)
  PROTOTYPE:
  ALIAS:
    new = 1
  PREINIT:
    hwloc_cpuset_t s = NULL;
  CODE:
    PERL_UNUSED_VAR(ix);
    if((s = hwloc_cpuset_alloc()) == NULL)
      XSRETURN_UNDEF;
    else
      RETVAL = s;
  OUTPUT:
      RETVAL


void
copy(set,dst)
  hwloc_cpuset_t set
  hwloc_cpuset_t dst
  PROTOTYPE: $$
  PPCODE:
    hwloc_cpuset_copy(dst,set);


#if HWLOC_XSAPI_VERSION
void
and(set,seta)
  hwloc_cpuset_t set
  hwloc_cpuset_t seta
  PROTOTYPE: $$
  ALIAS:
    Sys::Hwloc::Cpuset::andnot = 1
    Sys::Hwloc::Cpuset::or     = 2
    Sys::Hwloc::Cpuset::xor    = 3
  PREINIT:
    hwloc_cpuset_t res = NULL;
  PPCODE:
    if((res = hwloc_cpuset_alloc()) == NULL)
      croak("Failed to create temporary cpuset in Sys::Hwloc::Cpuset->and alias %d", (int)ix);
    if(ix == 0)
      hwloc_cpuset_and(res,set,seta);
    else if(ix == 1)
      hwloc_cpuset_andnot(res,set,seta);
    else if(ix == 2)
      hwloc_cpuset_or(res,set,seta);
    else if(ix == 3)
      hwloc_cpuset_xor(res,set,seta);
    else
      croak("Should not come here in Sys::Hwloc::Cpuset->and, alias = %d", (int)ix);
    hwloc_cpuset_free(set);
    sv_setref_pv(ST(0), "Sys::Hwloc::Cpuset", (void *)res);


void
not(set)
  hwloc_cpuset_t set
  PROTOTYPE: $
  PREINIT:
    hwloc_cpuset_t res = NULL;
  PPCODE:
    if((res = hwloc_cpuset_alloc()) == NULL)
      croak("Failed to create temporary cpuset in Sys::Hwloc::Cpuset->not");
    hwloc_cpuset_not(res,set);
    hwloc_cpuset_free(set);
    sv_setref_pv(ST(0), "Sys::Hwloc::Cpuset", (void *)res);

#else
void
and(set,seta)
  hwloc_cpuset_t set
  hwloc_cpuset_t seta
  PROTOTYPE: $$
  ALIAS:
    Sys::Hwloc::Cpuset::or     = 2
    Sys::Hwloc::Cpuset::xor    = 3
  PPCODE:
    if(ix == 0)
      hwloc_cpuset_andset(set,seta);
    else if(ix == 2)
      hwloc_cpuset_orset(set,seta);
    else if(ix == 3)
      hwloc_cpuset_xorset(set,seta);
    else
      croak("Should not come here in Sys::Hwloc::Cpuset->and, alias = %d", (int)ix);

#endif
#endif


#if HWLOC_XSAPI_VERSION >= 0x00010100

 # ===================================================================
 # PACKAGE Sys::Hwloc::Bitmap, OO interface of hwloc_bitmap_t
 # ===================================================================

MODULE = Sys::Hwloc                  PACKAGE = Sys::Hwloc::Bitmap

hwloc_bitmap_t
alloc(void)
  PROTOTYPE:
  ALIAS:
    new = 1
  PREINIT:
    hwloc_bitmap_t s = NULL;
  CODE:
    PERL_UNUSED_VAR(ix);
    if((s = hwloc_bitmap_alloc()) == NULL)
      XSRETURN_UNDEF;
    else
      RETVAL = s;
  OUTPUT:
      RETVAL


hwloc_bitmap_t
alloc_full(void)
  PROTOTYPE:
  PREINIT:
    hwloc_bitmap_t s = NULL;
  CODE:
    if((s = hwloc_bitmap_alloc_full()) == NULL)
      XSRETURN_UNDEF;
    else
      RETVAL = s;
  OUTPUT:
      RETVAL


void
copy(map,dst)
  hwloc_bitmap_t map
  hwloc_bitmap_t dst
  PROTOTYPE: $$
  PPCODE:
    hwloc_bitmap_copy(dst,map);


void
and(map,mapa)
  hwloc_bitmap_t map
  hwloc_bitmap_t mapa
  PROTOTYPE: $$
  ALIAS:
    Sys::Hwloc::Bitmap::andnot = 1
    Sys::Hwloc::Bitmap::or     = 2
    Sys::Hwloc::Bitmap::xor    = 3
  PREINIT:
    hwloc_bitmap_t res = NULL;
  PPCODE:
    if((res = hwloc_bitmap_alloc()) == NULL)
      croak("Failed to create temporary bitmap in Sys::Hwloc::Bitmap->and alias %d", (int)ix);
    if(ix == 0)
      hwloc_bitmap_and(res,map,mapa);
    else if(ix == 1)
      hwloc_bitmap_andnot(res,map,mapa);
    else if(ix == 2)
      hwloc_bitmap_or(res,map,mapa);
    else if(ix == 3)
      hwloc_bitmap_xor(res,map,mapa);
    else
      croak("Should not come here in Sys::Hwloc::Bitmap->and, alias = %d", (int)ix);
    hwloc_bitmap_free(map);
    sv_setref_pv(ST(0), "Sys::Hwloc::Bitmap", (void *)res);


void
not(map)
  hwloc_bitmap_t map
  PROTOTYPE: $
  PREINIT:
    hwloc_bitmap_t res = NULL;
  PPCODE:
    if((res = hwloc_bitmap_alloc()) == NULL)
      croak("Failed to create temporary bitmap in Sys::Hwloc::Bitmap->not");
    hwloc_bitmap_not(res,map);
    hwloc_bitmap_free(map);
    sv_setref_pv(ST(0), "Sys::Hwloc::Bitmap", (void *)res);

#endif

