
 # -------------------------------------------------------------------
 # Cpuset API, see Sys::Hwloc::Cpuset for accessors
 # $Id: hwloc_cpuset.xsh,v 1.9 2011/01/05 18:08:55 bzbkalli Exp $
 # -------------------------------------------------------------------

 # -- new/destroy

hwloc_cpuset_t
hwloc_cpuset_alloc()
  PROTOTYPE:
  PREINIT:
    hwloc_cpuset_t set = NULL;
  CODE:
    if((set = hwloc_cpuset_alloc()) == NULL)
      XSRETURN_UNDEF;
    else
      RETVAL = set;
  OUTPUT:
    RETVAL


hwloc_cpuset_t
hwloc_cpuset_dup(set)
  hwloc_cpuset_t set
  ALIAS:
    Sys::Hwloc::Cpuset::dup = 1
  PREINIT:
    hwloc_cpuset_t s = NULL;
  CODE:
    PERL_UNUSED_VAR(ix);
    if((s = hwloc_cpuset_dup(set)) == NULL)
      XSRETURN_UNDEF;
    else
      RETVAL = s;
  OUTPUT:
    RETVAL


void
hwloc_cpuset_free(set)
  hwloc_cpuset_t set
  PROTOTYPE: $
  ALIAS:
    Sys::Hwloc::Cpuset::free          = 1
    Sys::Hwloc::Cpuset::destroy       = 2
    Sys::Hwloc::hwloc_cpuset_fill     = 10
    Sys::Hwloc::Cpuset::fill          = 11
    Sys::Hwloc::hwloc_cpuset_singlify = 20
    Sys::Hwloc::Cpuset::singlify      = 21
    Sys::Hwloc::hwloc_cpuset_zero     = 30
    Sys::Hwloc::Cpuset::zero          = 31
  PPCODE:
    if(ix < 10) {
      hwloc_cpuset_free(set);
      sv_setref_pv(ST(0), "Sys::Hwloc::Cpuset", (void *)NULL);
    }
    else if(ix < 20)
      hwloc_cpuset_fill(set);
    else if(ix < 30)
      hwloc_cpuset_singlify(set);
    else if(ix < 40)
      hwloc_cpuset_zero(set);
    else
      croak("Should not come here in Sys::Hwloc::hwloc_cpuset_free, alias = %d", (int)ix);


 # -- set

void
hwloc_cpuset_all_but_cpu(set,cpu)
  hwloc_cpuset_t set
  unsigned       cpu
  PROTOTYPE: $$
  ALIAS:
    Sys::Hwloc::Cpuset::all_but_cpu = 1
    Sys::Hwloc::hwloc_cpuset_clr    = 10
    Sys::Hwloc::Cpuset::clr         = 11
    Sys::Hwloc::hwloc_cpuset_cpu    = 20
    Sys::Hwloc::Cpuset::cpu         = 21
    Sys::Hwloc::hwloc_cpuset_set    = 30
    Sys::Hwloc::Cpuset::set         = 31
  PPCODE:
    if(ix < 10)
      hwloc_cpuset_all_but_cpu(set,cpu);
    else if(ix < 20)
      hwloc_cpuset_clr(set,cpu);
    else if(ix < 30)
      hwloc_cpuset_cpu(set,cpu);
    else if(ix < 40)
      hwloc_cpuset_set(set,cpu);
    else
      croak("Should not come here in Sys::Hwloc::hwloc_cpuset_all_but_cpu, alias = %d", (int)ix);


#if HWLOC_XSAPI_VERSION
void
hwloc_cpuset_clr_range(set,cpua,cpue)
  hwloc_cpuset_t set
  unsigned       cpua
  unsigned       cpue
  PROTOTYPE: $$$
  ALIAS:
    Sys::Hwloc::Cpuset::clr_range      = 1
  PPCODE:
    PERL_UNUSED_VAR(ix);
    hwloc_cpuset_clr_range(set,cpua,cpue);

#endif


void
hwloc_cpuset_set_range(set,cpua,cpue)
  hwloc_cpuset_t set
  unsigned       cpua
  unsigned       cpue
  PROTOTYPE: $$$
  ALIAS:
    Sys::Hwloc::Cpuset::set_range      = 1
  PPCODE:
    PERL_UNUSED_VAR(ix);
    hwloc_cpuset_set_range(set,cpua,cpue);


void
hwloc_cpuset_copy(dst,src)
  hwloc_cpuset_t dst
  hwloc_cpuset_t src
  PROTOTYPE: $$
  PPCODE:
    hwloc_cpuset_copy(dst,src);


void
hwloc_cpuset_from_ith_ulong(set,i,mask)
  hwloc_cpuset_t set
  unsigned       i
  unsigned long  mask
  PROTOTYPE: $$$
  ALIAS:
    Sys::Hwloc::Cpuset::from_ith_ulong = 1
  PREINIT:
    unsigned long lmask = mask;
  PPCODE:
    PERL_UNUSED_VAR(ix);
    hwloc_cpuset_from_ith_ulong(set,i,lmask);


#if HWLOC_XSAPI_VERSION
int
hwloc_cpuset_from_string(set,string)
  hwloc_cpuset_t  set
  const char     *string
  PROTOTYPE: $$
  ALIAS:
    Sys::Hwloc::Cpuset::from_string = 1
  CODE:
    PERL_UNUSED_VAR(ix);
    RETVAL = hwloc_cpuset_from_string(set,string);
  OUTPUT:
    RETVAL


int
hwloc_cpuset_from_liststring(set,string)
  hwloc_cpuset_t  set
  const char     *string
  PROTOTYPE: $$
  ALIAS:
    Sys::Hwloc::Cpuset::from_liststring = 1
  CODE:
    PERL_UNUSED_VAR(ix);
    RETVAL = _hwloc_cpuset_list_sscanf(set,string);
  OUTPUT:
    RETVAL


#else
hwloc_cpuset_t
hwloc_cpuset_from_string(string)
  const char     *string
  PROTOTYPE: $
  CODE:
    RETVAL = hwloc_cpuset_from_string(string);
  OUTPUT:
    RETVAL

#endif


void
hwloc_cpuset_from_ulong(set,mask)
  hwloc_cpuset_t set
  unsigned long  mask
  PROTOTYPE: $$
  ALIAS:
    Sys::Hwloc::Cpuset::from_ulong = 1
  PREINIT:
    unsigned long lmask = mask;
  PPCODE:
    PERL_UNUSED_VAR(ix);
    hwloc_cpuset_from_ulong(set,lmask);


 # -- setlogic

#if HWLOC_XSAPI_VERSION
void
hwloc_cpuset_and(res,set1,set2)
  hwloc_cpuset_t res
  hwloc_cpuset_t set1
  hwloc_cpuset_t set2
  PROTOTYPE: $$$
  ALIAS:
    Sys::Hwloc::hwloc_cpuset_andnot = 1
    Sys::Hwloc::hwloc_cpuset_or     = 2
    Sys::Hwloc::hwloc_cpuset_xor    = 3
  PPCODE:
    if(ix == 0)
      hwloc_cpuset_and(res,set1,set2);
    else if(ix == 1)
      hwloc_cpuset_andnot(res,set1,set2);
    else if(ix == 2)
      hwloc_cpuset_or(res,set1,set2);
    else if(ix == 3)
      hwloc_cpuset_xor(res,set1,set2);
    else
      croak("Should not come here in Sys::Hwloc::hwloc_cpuset_and, alias = %d", (int)ix);


void
hwloc_cpuset_not(res,set)
  hwloc_cpuset_t res
  hwloc_cpuset_t set
  PROTOTYPE: $$
  PPCODE:
    hwloc_cpuset_not(res,set);

#else
void
hwloc_cpuset_andset(set1,set2)
  hwloc_cpuset_t set1
  hwloc_cpuset_t set2
  PROTOTYPE: $$
  ALIAS:
    Sys::Hwloc::hwloc_cpuset_orset  = 2
    Sys::Hwloc::hwloc_cpuset_xorset = 3
  PPCODE:
    if(ix == 0)
      hwloc_cpuset_andset(set1,set2);
    else if(ix == 2)
      hwloc_cpuset_orset(set1,set2);
    else if(ix == 3)
      hwloc_cpuset_xorset(set1,set2);
    else
      croak("Should not come here in Sys::Hwloc::hwloc_cpuset_andset, alias = %d", (int)ix);

#endif


 # -- get

int
hwloc_cpuset_first(set)
  hwloc_cpuset_t set
  PROTOTYPE: $
  ALIAS:
    Sys::Hwloc::Cpuset::first     = 1
    Sys::Hwloc::hwloc_cpuset_last = 10
    Sys::Hwloc::Cpuset::last      = 11
  CODE:
    if(ix < 10)
      RETVAL = hwloc_cpuset_first(set);
    else if(ix < 20)
      RETVAL = hwloc_cpuset_last(set);
    else
      croak("Should not come here in Sys::Hwloc::hwloc_cpuset_first, alias = %d", (int)ix);
  OUTPUT:
    RETVAL


#if HWLOC_XSAPI_VERSION
int
hwloc_cpuset_next(set,prev_cpu)
  hwloc_cpuset_t set
  unsigned       prev_cpu
  PROTOTYPE: $$
  ALIAS:
    Sys::Hwloc::Cpuset::next = 1
  CODE:
    PERL_UNUSED_VAR(ix);
    RETVAL = hwloc_cpuset_next(set,prev_cpu);
  OUTPUT:
    RETVAL

#endif


void
hwloc_cpuset_ids(set)
  hwloc_cpuset_t set
  PROTOTYPE: $
  ALIAS:
  Sys::Hwloc::Cpuset::ids = 1
  PREINIT:
    unsigned id;
    int      count = 0;
  PPCODE:
    PERL_UNUSED_VAR(ix);
    hwloc_cpuset_foreach_begin(id,set) {
      mXPUSHu(id);
      count++;
    }
    hwloc_cpuset_foreach_end();
    XSRETURN(count);


SV *
hwloc_cpuset_sprintf(set)
  hwloc_cpuset_t set
  PROTOTYPE: $
  ALIAS:
    Sys::Hwloc::Cpuset::sprintf = 1
  PREINIT:
    int   rc;
  CODE:
    PERL_UNUSED_VAR(ix);
    if((rc = hwloc_cpuset_snprintf(sbuf, sizeof(sbuf), set)) == -1)
      XSRETURN_UNDEF;
    else
      RETVAL = newSVpvn(sbuf,(STRLEN)rc);
  OUTPUT:
    RETVAL


#if HWLOC_XSAPI_VERSION
SV *
hwloc_cpuset_list_sprintf(set)
  hwloc_cpuset_t set
  PROTOTYPE: $
  ALIAS:
    Sys::Hwloc::Cpuset::sprintf_list      = 1
    Sys::Hwloc::hwloc_cpuset_sprintf_list = 2
  PREINIT:
    int   rc;
  CODE:
    PERL_UNUSED_VAR(ix);
    if((rc = _hwloc_cpuset_list_snprintf(sbuf, sizeof(sbuf), set)) == -1)
      XSRETURN_UNDEF;
    else
      RETVAL = newSVpvn(sbuf,(STRLEN)rc);
  OUTPUT:
    RETVAL

#endif


unsigned long
hwloc_cpuset_to_ith_ulong(set,i)
  hwloc_cpuset_t set
  unsigned       i
  PROTOTYPE: $$
  ALIAS:
    Sys::Hwloc::Cpuset::to_ith_ulong = 1
  CODE:
    PERL_UNUSED_VAR(ix);
    RETVAL = hwloc_cpuset_to_ith_ulong(set,i);
  OUTPUT:
    RETVAL


unsigned long
hwloc_cpuset_to_ulong(set)
  hwloc_cpuset_t set
  PROTOTYPE: $
  ALIAS:
    Sys::Hwloc::Cpuset::to_ulong = 1
  CODE:
    PERL_UNUSED_VAR(ix);
    RETVAL = hwloc_cpuset_to_ulong(set);
  OUTPUT:
    RETVAL


int
hwloc_cpuset_weight(set)
  hwloc_cpuset_t set
  PROTOTYPE: $
  ALIAS:
    Sys::Hwloc::Cpuset::weight = 1
  CODE:
    PERL_UNUSED_VAR(ix);
    RETVAL = hwloc_cpuset_weight(set);
  OUTPUT:
    RETVAL


 # -- test

#if HWLOC_XSAPI_VERSION
int
hwloc_cpuset_compare(set1,set2)
  hwloc_cpuset_t set1
  hwloc_cpuset_t set2
  PROTOTYPE: $$
  ALIAS:
    Sys::Hwloc::Cpuset::compare            = 1
    Sys::Hwloc::hwloc_cpuset_isequal       = 10
    Sys::Hwloc::Cpuset::isequal            = 11
    Sys::Hwloc::hwloc_cpuset_compare_first = 20
    Sys::Hwloc::Cpuset::compare_first      = 21
    Sys::Hwloc::hwloc_cpuset_intersects    = 30
    Sys::Hwloc::Cpuset::intersects         = 31
  CODE:
    if(ix < 10)
      RETVAL = hwloc_cpuset_compare(set1,set2);
    else if(ix < 20)
      RETVAL = hwloc_cpuset_isequal(set1,set2);
    else if(ix < 30)
      RETVAL =  hwloc_cpuset_compare_first(set1,set2);
    else if(ix < 40)
      RETVAL = hwloc_cpuset_intersects(set1,set2);
    else
      croak("Should not come here in Sys::Hwloc::hwloc_cpuset_compare, alias = %d", (int)ix);
  OUTPUT:
    RETVAL

#else
int
hwloc_cpuset_compar(set1,set2)
  hwloc_cpuset_t set1
  hwloc_cpuset_t set2
  PROTOTYPE: $$
  ALIAS:
    Sys::Hwloc::Cpuset::compar             = 1
    Sys::Hwloc::hwloc_cpuset_isequal       = 10
    Sys::Hwloc::Cpuset::isequal            = 11
    Sys::Hwloc::hwloc_cpuset_compar_first  = 20
    Sys::Hwloc::Cpuset::compar_first       = 21
    Sys::Hwloc::hwloc_cpuset_intersects    = 30
    Sys::Hwloc::Cpuset::intersects         = 31
  CODE:
    if(ix < 10)
      RETVAL = hwloc_cpuset_compar(set1,set2);
    else if(ix < 20)
      RETVAL = hwloc_cpuset_isequal(set1,set2);
    else if(ix < 30)
      RETVAL =  hwloc_cpuset_compar_first(set1,set2);
    else if(ix < 40)
      RETVAL = hwloc_cpuset_intersects(set1,set2);
    else
      croak("Should not come here in Sys::Hwloc::hwloc_cpuset_compar, alias = %d", (int)ix);
  OUTPUT:
    RETVAL

#endif


int
hwloc_cpuset_isincluded(subset,superset)
  hwloc_cpuset_t subset
  hwloc_cpuset_t superset
  PROTOTYPE: $$
  ALIAS:
    Sys::Hwloc::Cpuset::isincluded = 1
  CODE:
    PERL_UNUSED_VAR(ix);
    RETVAL = hwloc_cpuset_isincluded(subset,superset);
  OUTPUT:
    RETVAL


int
hwloc_cpuset_includes(superset,subset)
  hwloc_cpuset_t subset
  hwloc_cpuset_t superset
  PROTOTYPE: $$
  ALIAS:
    Sys::Hwloc::Cpuset::includes = 1
  CODE:
    PERL_UNUSED_VAR(ix);
    RETVAL = hwloc_cpuset_isincluded(subset,superset);
  OUTPUT:
    RETVAL


int
hwloc_cpuset_isfull(set)
  hwloc_cpuset_t set
  PROTOTYPE: $
  ALIAS:
    Sys::Hwloc::Cpuset::isfull      = 1
    Sys::Hwloc::hwloc_cpuset_iszero = 10
    Sys::Hwloc::Cpuset::iszero      = 11
  CODE:
    if(ix < 10)
      RETVAL = hwloc_cpuset_isfull(set);
    else if(ix < 20)
      RETVAL = hwloc_cpuset_iszero(set);
    else
      croak("Should not come here in Sys::Hwloc::hwloc_cpuset_isfull, alias = %d", (int)ix);
  OUTPUT:
    RETVAL


int
hwloc_cpuset_isset(set,cpu)
  hwloc_cpuset_t set
  unsigned       cpu
  PROTOTYPE: $$
  ALIAS:
    Sys::Hwloc::Cpuset::isset = 1
  CODE:
    PERL_UNUSED_VAR(ix);
    RETVAL = hwloc_cpuset_isset(set,cpu);
  OUTPUT:
    RETVAL


#if HWLOC_XSAPI_VERSION
hwloc_cpuset_t
hwloc_topology_get_complete_cpuset(topo)
  hwloc_topology_t topo
  PROTOTYPE: $
  ALIAS:
    Sys::Hwloc::Topology::get_complete_cpuset      = 1
    Sys::Hwloc::hwloc_topology_get_topology_cpuset = 10
    Sys::Hwloc::Topology::get_topology_cpuset      = 11
    Sys::Hwloc::hwloc_topology_get_online_cpuset   = 20
    Sys::Hwloc::Topology::get_online_cpuset        = 21
    Sys::Hwloc::hwloc_topology_get_allowed_cpuset  = 30
    Sys::Hwloc::Topology::get_allowed_cpuset       = 31
  CODE:
    if(ix < 10)
      RETVAL = (hwloc_cpuset_t)hwloc_topology_get_complete_cpuset(topo);
    else if(ix < 20)
      RETVAL = (hwloc_cpuset_t)hwloc_topology_get_topology_cpuset(topo);
    else if(ix < 30)
      RETVAL = (hwloc_cpuset_t)hwloc_topology_get_online_cpuset(topo);
    else if(ix < 40)
      RETVAL = (hwloc_cpuset_t)hwloc_topology_get_allowed_cpuset(topo);
    else
      croak("Should not come here in Sys::Hwloc::hwloc_topology_get_complete_cpuset, alias = %d", (int)ix);
  OUTPUT:
    RETVAL

#endif

 # -------------------------------------------------------------------
 # Finding objects inside cpusets
 # -------------------------------------------------------------------

unsigned
hwloc_get_nbobjs_inside_cpuset_by_depth(topo,set,depth)
  hwloc_topology_t topo
  hwloc_cpuset_t   set
  unsigned         depth
  PROTOTYPE: $$$
  ALIAS:
    Sys::Hwloc::Topology::get_nbobjs_inside_cpuset_by_depth = 1
  CODE:
    PERL_UNUSED_VAR(ix);
    RETVAL = hwloc_get_nbobjs_inside_cpuset_by_depth(topo,set,depth);
  OUTPUT:
    RETVAL


int
hwloc_get_nbobjs_inside_cpuset_by_type(topo,set,type)
  hwloc_topology_t topo
  hwloc_cpuset_t   set
  int              type
  PROTOTYPE: $$$
  ALIAS:
    Sys::Hwloc::Topology::get_nbobjs_inside_cpuset_by_type = 1
  CODE:
    PERL_UNUSED_VAR(ix);
    RETVAL = hwloc_get_nbobjs_inside_cpuset_by_type(topo,set,type);
  OUTPUT:
    RETVAL


hwloc_obj_t
hwloc_get_obj_inside_cpuset_by_depth(topo,set,depth,idx)
  hwloc_topology_t topo
  hwloc_cpuset_t   set
  unsigned         depth
  unsigned         idx
  PROTOTYPE: $$$$
  ALIAS:
    Sys::Hwloc::Topology::get_obj_inside_cpuset_by_depth = 1
  CODE:
    PERL_UNUSED_VAR(ix);
    RETVAL = hwloc_get_obj_inside_cpuset_by_depth(topo,set,depth,idx);
  OUTPUT:
    RETVAL


hwloc_obj_t
hwloc_get_obj_inside_cpuset_by_type(topo,set,type,idx)
  hwloc_topology_t topo
  hwloc_cpuset_t   set
  int              type
  unsigned         idx
  PROTOTYPE: $$$$
  ALIAS:
    Sys::Hwloc::Topology::get_obj_inside_cpuset_by_type = 1
  CODE:
    PERL_UNUSED_VAR(ix);
    RETVAL = hwloc_get_obj_inside_cpuset_by_type(topo,set,type,idx);
  OUTPUT:
    RETVAL


#if HWLOC_XSAPI_VERSION
hwloc_obj_t
hwloc_get_first_largest_obj_inside_cpuset(topo,set)
  hwloc_topology_t topo
  hwloc_cpuset_t   set
  PROTOTYPE: $$
  ALIAS:
    Sys::Hwloc::Topology::get_first_largest_obj_inside_cpuset = 1
  CODE:
    PERL_UNUSED_VAR(ix);
    RETVAL = hwloc_get_first_largest_obj_inside_cpuset(topo,set);
  OUTPUT:
    RETVAL

#endif

hwloc_obj_t
hwloc_get_next_obj_inside_cpuset_by_depth(topo,set,depth,prev)
  hwloc_topology_t topo
  hwloc_cpuset_t   set
  unsigned         depth
  SV              *prev
  PROTOTYPE: $$$$
  ALIAS:
    Sys::Hwloc::Topology::get_next_obj_inside_cpuset_by_depth = 1
  PREINIT:
    hwloc_obj_t o = NULL;
  CODE:
    PERL_UNUSED_VAR(ix);
    o      = SV2hwlocObj(prev, "Sys::Hwloc::hwloc_get_next_obj_inside_cpuset_by_depth()", 4, 1);
    RETVAL = hwloc_get_next_obj_inside_cpuset_by_depth(topo,set,depth,o);
  OUTPUT:
    RETVAL


hwloc_obj_t
hwloc_get_next_obj_inside_cpuset_by_type(topo,set,type,prev)
  hwloc_topology_t topo
  hwloc_cpuset_t   set
  int              type
  SV              *prev
  PROTOTYPE: $$$$
  ALIAS:
    Sys::Hwloc::Topology::get_next_obj_inside_cpuset_by_type = 1
  PREINIT:
    hwloc_obj_t o = NULL;
  CODE:
    PERL_UNUSED_VAR(ix);
    o      = SV2hwlocObj(prev, "Sys::Hwloc::hwloc_get_next_obj_inside_cpuset_by_type()", 4, 1);
    RETVAL = hwloc_get_next_obj_inside_cpuset_by_type(topo,set,type,o);
  OUTPUT:
    RETVAL


void
hwloc_get_largest_objs_inside_cpuset(topo,set)
  hwloc_topology_t topo
  hwloc_cpuset_t   set
  PROTOTYPE: $$
  ALIAS:
    Sys::Hwloc::Topology::get_largest_objs_inside_cpuset = 1
  PREINIT:
    int rc;
    int i;
    hwloc_obj_t *objs = NULL;
  PPCODE:
    PERL_UNUSED_VAR(ix);
    if((objs = (hwloc_obj_t *)malloc(1024 * sizeof(hwloc_obj_t *))) == NULL)
      croak("Failed to allocate memory");
    rc = hwloc_get_largest_objs_inside_cpuset(topo,set,objs,1024);
    if(rc < 0)
      rc = 0;
    EXTEND(SP, rc);
    for(i = 0; i < rc; i++)
      PUSHs(sv_2mortal(hwlocObj2SV(objs[i])));
    free(objs);
    XSRETURN(rc);

