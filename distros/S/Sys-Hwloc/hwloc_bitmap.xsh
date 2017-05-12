
 # -------------------------------------------------------------------
 # Bitmap API, see Sys::Hwloc::Bitmap for accessors
 # $Id: hwloc_bitmap.xsh,v 1.8 2011/01/05 17:16:12 bzbkalli Exp $
 # -------------------------------------------------------------------

 # -- new/destroy

hwloc_bitmap_t
hwloc_bitmap_alloc()
  PROTOTYPE:
  PREINIT:
    hwloc_bitmap_t map = NULL;
  CODE:
    if((map = hwloc_bitmap_alloc()) == NULL)
      XSRETURN_UNDEF;
    else
      RETVAL = map;
  OUTPUT:
    RETVAL


hwloc_bitmap_t
hwloc_bitmap_alloc_full()
  PROTOTYPE:
  PREINIT:
    hwloc_bitmap_t map = NULL;
  CODE:
    if((map = hwloc_bitmap_alloc_full()) == NULL)
      XSRETURN_UNDEF;
    else
      RETVAL = map;
  OUTPUT:
    RETVAL


hwloc_bitmap_t
hwloc_bitmap_dup(map)
  hwloc_bitmap_t map
  ALIAS:
    Sys::Hwloc::Bitmap::dup = 1
  PREINIT:
    hwloc_bitmap_t s = NULL;
  CODE:
    PERL_UNUSED_VAR(ix);
    if((s = hwloc_bitmap_dup(map)) == NULL)
      XSRETURN_UNDEF;
    else
      RETVAL = s;
  OUTPUT:
    RETVAL


void
hwloc_bitmap_free(map)
  hwloc_bitmap_t map
  PROTOTYPE: $
  ALIAS:
    Sys::Hwloc::Bitmap::free          = 1
    Sys::Hwloc::Bitmap::destroy       = 2
    Sys::Hwloc::hwloc_bitmap_fill     = 10
    Sys::Hwloc::Bitmap::fill          = 11
    Sys::Hwloc::hwloc_bitmap_singlify = 20
    Sys::Hwloc::Bitmap::singlify      = 21
    Sys::Hwloc::hwloc_bitmap_zero     = 30
    Sys::Hwloc::Bitmap::zero          = 31
  PPCODE:
    if(ix < 10) {
      hwloc_bitmap_free(map);
      sv_setref_pv(ST(0), "Sys::Hwloc::Bitmap", (void *)NULL);
    }
    else if(ix < 20)
      hwloc_bitmap_fill(map);
    else if(ix < 30)
      hwloc_bitmap_singlify(map);
    else if(ix < 40)
      hwloc_bitmap_zero(map);
    else
      croak("Should not come here in Sys::Hwloc::hwloc_bitmap_free, alias = %d", (int)ix);


 # -- set

void
hwloc_bitmap_allbut(map,id)
  hwloc_bitmap_t map
  unsigned       id
  PROTOTYPE: $$
  ALIAS:
    Sys::Hwloc::Bitmap::allbut      = 1
    Sys::Hwloc::hwloc_bitmap_clr    = 10
    Sys::Hwloc::Bitmap::clr         = 11
    Sys::Hwloc::hwloc_bitmap_only   = 20
    Sys::Hwloc::Bitmap::only        = 21
    Sys::Hwloc::hwloc_bitmap_set    = 30
    Sys::Hwloc::Bitmap::set         = 31
  PPCODE:
    if(ix < 10)
      hwloc_bitmap_allbut(map,id);
    else if(ix < 20)
      hwloc_bitmap_clr(map,id);
    else if(ix < 30)
      hwloc_bitmap_only(map,id);
    else if(ix < 40)
      hwloc_bitmap_set(map,id);
    else
      croak("Should not come here in Sys::Hwloc::hwloc_bitmap_allbut, alias = %d", (int)ix);


void
hwloc_bitmap_clr_range(map,begin,end)
  hwloc_bitmap_t map
  unsigned       begin
  unsigned       end
  PROTOTYPE: $$$
  ALIAS:
    Sys::Hwloc::Bitmap::clr_range      = 1
    Sys::Hwloc::hwloc_bitmap_set_range = 10
    Sys::Hwloc::Bitmap::set_range      = 11
  PPCODE:
    if(ix < 10)
      hwloc_bitmap_clr_range(map,begin,end);
    else if(ix < 20)
      hwloc_bitmap_set_range(map,begin,end);
    else
      croak("Should not come here in Sys::Hwloc::hwloc_bitmap_clr_range, alias = %d", (int)ix);


void
hwloc_bitmap_copy(dst,src)
  hwloc_bitmap_t dst
  hwloc_bitmap_t src
  PROTOTYPE: $$
  PPCODE:
    hwloc_bitmap_copy(dst,src);


void
hwloc_bitmap_from_ith_ulong(map,i,mask)
  hwloc_bitmap_t map
  unsigned       i
  unsigned long  mask
  PROTOTYPE: $$$
  ALIAS:
    Sys::Hwloc::Bitmap::from_ith_ulong     = 1
    Sys::Hwloc::hwloc_bitmap_set_ith_ulong = 10
    Sys::Hwloc::Bitmap::set_ith_ulong      = 11
  PREINIT:
    unsigned long lmask = mask;
  PPCODE:
    if(ix < 10)
      hwloc_bitmap_from_ith_ulong(map,i,lmask);
    else if(ix < 20)
      hwloc_bitmap_set_ith_ulong(map,i,lmask);
    else
      croak("Should not come here in Sys::Hwloc::hwloc_bitmap_from_ith_ulong, alias = %d", (int)ix);


int
hwloc_bitmap_sscanf(map,string)
  hwloc_bitmap_t  map
  const char     *string
  PROTOTYPE: $$
  ALIAS:
    Sys::Hwloc::Bitmap::sscanf              = 1
    Sys::Hwloc::hwloc_bitmap_taskset_sscanf = 10
    Sys::Hwloc::Bitmap::sscanf_taskset      = 11
    Sys::Hwloc::hwloc_bitmap_list_sscanf    = 20
    Sys::Hwloc::Bitmap::sscanf_list         = 21
  CODE:
    if(ix < 10)
      RETVAL = hwloc_bitmap_sscanf(map,string);
    else if(ix < 20)
      RETVAL = hwloc_bitmap_taskset_sscanf(map,string);
    else if(ix < 30)
      RETVAL = _hwloc_bitmap_list_sscanf(map,string);
    else
      croak("Should not come here in Sys::Hwloc::hwloc_bitmap_sscanf, alias = %d", (int)ix);
  OUTPUT:
    RETVAL


void
hwloc_bitmap_from_ulong(map,mask)
  hwloc_bitmap_t map
  unsigned long  mask
  PROTOTYPE: $$
  ALIAS:
    Sys::Hwloc::Bitmap::from_ulong = 1
  PREINIT:
    unsigned long lmask = mask;
  PPCODE:
    PERL_UNUSED_VAR(ix);
    hwloc_bitmap_from_ulong(map,lmask);


 # -- setlogic

void
hwloc_bitmap_and(res,map1,map2)
  hwloc_bitmap_t res
  hwloc_bitmap_t map1
  hwloc_bitmap_t map2
  PROTOTYPE: $$$
  ALIAS:
    Sys::Hwloc::hwloc_bitmap_andnot = 1
    Sys::Hwloc::hwloc_bitmap_or     = 2
    Sys::Hwloc::hwloc_bitmap_xor    = 3
  PPCODE:
    if(ix == 0)
      hwloc_bitmap_and(res,map1,map2);
    else if(ix == 1)
      hwloc_bitmap_andnot(res,map1,map2);
    else if(ix == 2)
      hwloc_bitmap_or(res,map1,map2);
    else if(ix == 3)
      hwloc_bitmap_xor(res,map1,map2);
    else
      croak("Should not come here in Sys::Hwloc::hwloc_bitmap_and, alias = %d", (int)ix);


void
hwloc_bitmap_not(res,map)
  hwloc_bitmap_t res
  hwloc_bitmap_t map
  PROTOTYPE: $$
  PPCODE:
    hwloc_bitmap_not(res,map);


 # -- get

int
hwloc_bitmap_first(map)
  hwloc_bitmap_t map
  PROTOTYPE: $
  ALIAS:
    Sys::Hwloc::Bitmap::first     = 1
    Sys::Hwloc::hwloc_bitmap_last = 10
    Sys::Hwloc::Bitmap::last      = 11
  CODE:
    if(ix < 10)
      RETVAL = hwloc_bitmap_first(map);
    else if(ix < 20)
      RETVAL = hwloc_bitmap_last(map);
    else
      croak("Should not come here in Sys::Hwloc::hwloc_bitmap_first, alias = %d", (int)ix);
  OUTPUT:
    RETVAL


int
hwloc_bitmap_next(map,prev)
  hwloc_bitmap_t map
  unsigned       prev
  PROTOTYPE: $$
  ALIAS:
    Sys::Hwloc::Bitmap::next = 1
  CODE:
    PERL_UNUSED_VAR(ix);
    RETVAL = hwloc_bitmap_next(map,prev);
  OUTPUT:
    RETVAL


void
hwloc_bitmap_ids(map)
  hwloc_bitmap_t map
  PROTOTYPE: $
  ALIAS:
  Sys::Hwloc::Bitmap::ids = 1
  PREINIT:
    unsigned id;
    int      count = 0;
  PPCODE:
    PERL_UNUSED_VAR(ix);
    hwloc_bitmap_foreach_begin(id,map) {
      mXPUSHu(id);
      count++;
    }
    hwloc_bitmap_foreach_end();
    XSRETURN(count);


SV *
hwloc_bitmap_sprintf(map)
  hwloc_bitmap_t map
  PROTOTYPE: $
  ALIAS:
    Sys::Hwloc::Bitmap::sprintf              = 1
    Sys::Hwloc::hwloc_bitmap_taskset_sprintf = 10
    Sys::Hwloc::Bitmap::sprintf_taskset      = 11
    Sys::Hwloc::hwloc_bitmap_list_sprintf    = 20
    Sys::Hwloc::Bitmap::sprintf_list         = 21
  PREINIT:
    int   rc;
  CODE:
    if(ix < 10)
      rc = hwloc_bitmap_snprintf(sbuf, sizeof(sbuf), map);
    else if(ix < 20)
      rc = hwloc_bitmap_taskset_snprintf(sbuf, sizeof(sbuf), map);
    else if(ix < 30)
      rc = _hwloc_bitmap_list_snprintf(sbuf, sizeof(sbuf), map);
    else
      croak("Should not come here in Sys::Hwloc::hwloc_bitmap_sprintf, alias = %d", (int)ix);
    if(rc == -1)
      XSRETURN_UNDEF;
    else
      RETVAL = newSVpvn(sbuf,(STRLEN)rc);
  OUTPUT:
    RETVAL


unsigned long
hwloc_bitmap_to_ith_ulong(map,i)
  hwloc_bitmap_t map
  unsigned       i
  PROTOTYPE: $$
  ALIAS:
    Sys::Hwloc::Bitmap::to_ith_ulong = 1
  CODE:
    PERL_UNUSED_VAR(ix);
    RETVAL = hwloc_bitmap_to_ith_ulong(map,i);
  OUTPUT:
    RETVAL


unsigned long
hwloc_bitmap_to_ulong(map)
  hwloc_bitmap_t map
  PROTOTYPE: $
  ALIAS:
    Sys::Hwloc::Bitmap::to_ulong = 1
  CODE:
    PERL_UNUSED_VAR(ix);
    RETVAL = hwloc_bitmap_to_ulong(map);
  OUTPUT:
    RETVAL


int
hwloc_bitmap_weight(map)
  hwloc_bitmap_t map
  PROTOTYPE: $
  ALIAS:
    Sys::Hwloc::Bitmap::weight = 1
  CODE:
    PERL_UNUSED_VAR(ix);
    RETVAL = hwloc_bitmap_weight(map);
  OUTPUT:
    RETVAL


 # -- test

int
hwloc_bitmap_compare(map1,map2)
  hwloc_bitmap_t map1
  hwloc_bitmap_t map2
  PROTOTYPE: $$
  ALIAS:
    Sys::Hwloc::Bitmap::compare            = 1
    Sys::Hwloc::hwloc_bitmap_isequal       = 10
    Sys::Hwloc::Bitmap::isequal            = 11
    Sys::Hwloc::hwloc_bitmap_compare_first = 20
    Sys::Hwloc::Bitmap::compare_first      = 21
    Sys::Hwloc::hwloc_bitmap_intersects    = 30
    Sys::Hwloc::Bitmap::intersects         = 31
  CODE:
    if(ix < 10)
      RETVAL = hwloc_bitmap_compare(map1,map2);
    else if(ix < 20)
      RETVAL = hwloc_bitmap_isequal(map1,map2);
    else if(ix < 30)
      RETVAL =  hwloc_bitmap_compare_first(map1,map2);
    else if(ix < 40)
      RETVAL = hwloc_bitmap_intersects(map1,map2);
    else
      croak("Should not come here in Sys::Hwloc::hwloc_bitmap_compare, alias = %d", (int)ix);
  OUTPUT:
    RETVAL


int
hwloc_bitmap_isincluded(submap,supermap)
  hwloc_bitmap_t submap
  hwloc_bitmap_t supermap
  PROTOTYPE: $$
  ALIAS:
    Sys::Hwloc::Bitmap::isincluded = 1
  CODE:
    PERL_UNUSED_VAR(ix);
    RETVAL = hwloc_bitmap_isincluded(submap,supermap);
  OUTPUT:
    RETVAL


int
hwloc_bitmap_includes(supermap,submap)
  hwloc_bitmap_t submap
  hwloc_bitmap_t supermap
  PROTOTYPE: $$
  ALIAS:
    Sys::Hwloc::Bitmap::includes = 1
  CODE:
    PERL_UNUSED_VAR(ix);
    RETVAL = hwloc_bitmap_isincluded(submap,supermap);
  OUTPUT:
    RETVAL


int
hwloc_bitmap_isfull(map)
  hwloc_bitmap_t map
  PROTOTYPE: $
  ALIAS:
    Sys::Hwloc::Bitmap::isfull      = 1
    Sys::Hwloc::hwloc_bitmap_iszero = 10
    Sys::Hwloc::Bitmap::iszero      = 11
  CODE:
    if(ix < 10)
      RETVAL = hwloc_bitmap_isfull(map);
    else if(ix < 20)
      RETVAL = hwloc_bitmap_iszero(map);
    else
      croak("Should not come here in Sys::Hwloc::hwloc_bitmap_isfull, alias = %d", (int)ix);
  OUTPUT:
    RETVAL


int
hwloc_bitmap_isset(map,id)
  hwloc_bitmap_t map
  unsigned       id
  PROTOTYPE: $$
  ALIAS:
    Sys::Hwloc::Bitmap::isset = 1
  CODE:
    PERL_UNUSED_VAR(ix);
    RETVAL = hwloc_bitmap_isset(map,id);
  OUTPUT:
    RETVAL


void
hwloc_cpuset_to_nodeset(topo,cpuset,nodeset)
  hwloc_topology_t topo
  hwloc_bitmap_t   cpuset
  hwloc_bitmap_t   nodeset
  PROTOTYPE: $$$
  ALIAS:
    Sys::Hwloc::Topology::cpuset_to_nodeset          = 1
    Sys::Hwloc::hwloc_cpuset_to_nodeset_strict       = 10
    Sys::Hwloc::Topology::cpuset_to_nodeset_strict   = 11
    Sys::Hwloc::hwloc_cpuset_from_nodeset            = 20
    Sys::Hwloc::Topology::cpuset_from_nodeset        = 21
    Sys::Hwloc::hwloc_cpuset_from_nodeset_strict     = 30
    Sys::Hwloc::Topology::cpuset_from_nodeset_strict = 31
  PPCODE:
    if(ix < 10)
      hwloc_cpuset_to_nodeset(topo,cpuset,nodeset);
    else if(ix < 20)
      hwloc_cpuset_to_nodeset_strict(topo,cpuset,nodeset);
    else if(ix < 30)
      hwloc_cpuset_from_nodeset(topo,cpuset,nodeset);
    else if(ix < 40)
      hwloc_cpuset_from_nodeset_strict(topo,cpuset,nodeset);
    else
      croak("Should not come here in Sys::Hwloc::hwloc_cpuset_to_nodeset, alias = %d", (int)ix);


hwloc_bitmap_t
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
      RETVAL = (hwloc_bitmap_t)hwloc_topology_get_complete_cpuset(topo);
    else if(ix < 20)
      RETVAL = (hwloc_bitmap_t)hwloc_topology_get_topology_cpuset(topo);
    else if(ix < 30)
      RETVAL = (hwloc_bitmap_t)hwloc_topology_get_online_cpuset(topo);
    else if(ix < 40)
      RETVAL = (hwloc_bitmap_t)hwloc_topology_get_allowed_cpuset(topo);
    else
      croak("Should not come here in Sys::Hwloc::hwloc_topology_get_complete_cpuset, alias = %d", (int)ix);
  OUTPUT:
    RETVAL


hwloc_bitmap_t
hwloc_topology_get_complete_nodeset(topo)
  hwloc_topology_t topo
  PROTOTYPE: $
  ALIAS:
    Sys::Hwloc::Topology::get_complete_nodeset      = 1
    Sys::Hwloc::hwloc_topology_get_topology_nodeset = 10
    Sys::Hwloc::Topology::get_topology_nodeset      = 11
    Sys::Hwloc::hwloc_topology_get_allowed_nodeset  = 20
    Sys::Hwloc::Topology::get_allowed_nodeset       = 21
  CODE:
    if(ix < 10)
      RETVAL = (hwloc_bitmap_t)hwloc_topology_get_complete_nodeset(topo);
    else if(ix < 20)
      RETVAL = (hwloc_bitmap_t)hwloc_topology_get_topology_nodeset(topo);
    else if(ix < 30)
      RETVAL = (hwloc_bitmap_t)hwloc_topology_get_allowed_nodeset(topo);
    else
      croak("Should not come here in Sys::Hwloc::hwloc_topology_get_complete_nodeset, alias = %d", (int)ix);
  OUTPUT:
    RETVAL

 # -------------------------------------------------------------------
 # Finding objects inside cpusets
 # -------------------------------------------------------------------

unsigned
hwloc_get_nbobjs_inside_cpuset_by_depth(topo,set,depth)
  hwloc_topology_t topo
  hwloc_bitmap_t   set
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
  hwloc_bitmap_t   set
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
  hwloc_bitmap_t   set
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
  hwloc_bitmap_t   set
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


hwloc_obj_t
hwloc_get_first_largest_obj_inside_cpuset(topo,set)
  hwloc_topology_t topo
  hwloc_bitmap_t   set
  PROTOTYPE: $$
  ALIAS:
    Sys::Hwloc::Topology::get_first_largest_obj_inside_cpuset = 1
  CODE:
    PERL_UNUSED_VAR(ix);
    RETVAL = hwloc_get_first_largest_obj_inside_cpuset(topo,set);
  OUTPUT:
    RETVAL


hwloc_obj_t
hwloc_get_next_obj_inside_cpuset_by_depth(topo,set,depth,prev)
  hwloc_topology_t topo
  hwloc_bitmap_t   set
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
  hwloc_bitmap_t   set
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
  hwloc_bitmap_t   set
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

