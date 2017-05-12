################################################################################
#
#  Copyright 2011 Zuse Institute Berlin
#
#  This package and its accompanying libraries is free software; you can
#  redistribute it and/or modify it under the terms of the GPL version 2.0,
#  or the Artistic License 2.0. Refer to LICENSE for the full license text.
#
#  Please send comments to kallies@zib.de
#
################################################################################
#
# Test if Hwloc module can do in principle what is expected
#
# $Id: 01-api.t,v 1.28 2011/01/11 10:49:40 bzbkalli Exp $
#
################################################################################

use Test::More;
use strict;
use Sys::Hwloc 0.09 qw(:DEFAULT :binding);

# --
# Sys::Hwloc methods
# --

my @names = qw(
	       HWLOC_OBJ_CACHE
	       HWLOC_OBJ_CORE
	       HWLOC_OBJ_MACHINE
	       HWLOC_OBJ_MISC
	       HWLOC_OBJ_NODE
	       HWLOC_OBJ_SOCKET
	       HWLOC_OBJ_SYSTEM
	       HWLOC_TOPOLOGY_FLAG_IS_THISSYSTEM
	       HWLOC_TOPOLOGY_FLAG_WHOLE_SYSTEM
	       HWLOC_TYPE_DEPTH_MULTIPLE
	       HWLOC_TYPE_DEPTH_UNKNOWN
	       HWLOC_TYPE_UNORDERED
	       HWLOC_CPUBIND_PROCESS
	       HWLOC_CPUBIND_THREAD
	       HWLOC_CPUBIND_STRICT

	       hwloc_compare_types

	       hwloc_topology_check hwloc_topology_destroy hwloc_topology_init hwloc_topology_load

	       hwloc_topology_ignore_type hwloc_topology_ignore_type_keep_structure hwloc_topology_ignore_all_keep_structure
	       hwloc_topology_set_flags hwloc_topology_set_fsroot hwloc_topology_set_synthetic hwloc_topology_set_xml

	       hwloc_topology_get_depth hwloc_get_type_depth hwloc_get_depth_type
	       hwloc_get_nbobjs_by_depth hwloc_get_nbobjs_by_type
	       hwloc_topology_is_thissystem

	       hwloc_get_obj_by_depth hwloc_get_obj_by_type

	       hwloc_obj_type_string hwloc_obj_type_of_string
	       hwloc_obj_cpuset_sprintf
	       hwloc_obj_sprintf

	       hwloc_get_type_or_below_depth hwloc_get_type_or_above_depth
	       hwloc_get_next_obj_by_depth hwloc_get_next_obj_by_type
	       hwloc_get_next_child
	       hwloc_get_common_ancestor_obj
	       hwloc_obj_is_in_subtree
	       hwloc_get_closest_objs
	       hwloc_compare_objects

	       hwloc_get_nbobjs_inside_cpuset_by_depth
	       hwloc_get_nbobjs_inside_cpuset_by_type
	       hwloc_get_obj_inside_cpuset_by_depth
	       hwloc_get_obj_inside_cpuset_by_type
	       hwloc_get_next_obj_inside_cpuset_by_depth
	       hwloc_get_next_obj_inside_cpuset_by_type
	       hwloc_get_largest_objs_inside_cpuset

	       hwloc_set_cpubind hwloc_set_proc_cpubind
	      );

if(! HWLOC_API_VERSION()) {
  push @names, qw(
		  HWLOC_OBJ_PROC
		  hwloc_get_system_obj
		 );
}

else {
  push @names, qw(
		  HWLOC_OBJ_GROUP
		  HWLOC_OBJ_PU

		  hwloc_topology_set_pid
		  hwloc_topology_get_support
		  hwloc_obj_type_sprintf
		  hwloc_obj_attr_sprintf
		  hwloc_get_root_obj
		  hwloc_get_ancestor_obj_by_depth
		  hwloc_get_ancestor_obj_by_type
		  hwloc_get_pu_obj_by_os_index
		  hwloc_get_obj_below_by_type

		  hwloc_topology_get_complete_cpuset hwloc_topology_get_topology_cpuset
		  hwloc_topology_get_online_cpuset hwloc_topology_get_allowed_cpuset

		  hwloc_get_first_largest_obj_inside_cpuset

		  hwloc_get_cpubind hwloc_get_proc_cpubind
		 );
}

if(HWLOC_XSAPI_VERSION() <= 0x00010000) {
  push @names, qw(
		  hwloc_cpuset_alloc hwloc_cpuset_dup hwloc_cpuset_free
		  hwloc_cpuset_all_but_cpu hwloc_cpuset_clr
		  hwloc_cpuset_copy hwloc_cpuset_cpu hwloc_cpuset_fill
		  hwloc_cpuset_from_ith_ulong hwloc_cpuset_from_string
		  hwloc_cpuset_from_ulong hwloc_cpuset_set hwloc_cpuset_set_range
		  hwloc_cpuset_singlify hwloc_cpuset_zero
		  hwloc_cpuset_first hwloc_cpuset_last hwloc_cpuset_ids
		  hwloc_cpuset_sprintf hwloc_cpuset_to_ith_ulong hwloc_cpuset_to_ulong
		  hwloc_cpuset_weight
		  hwloc_cpuset_includes hwloc_cpuset_intersects hwloc_cpuset_isequal
		  hwloc_cpuset_isfull hwloc_cpuset_isincluded
		  hwloc_cpuset_isset hwloc_cpuset_iszero
		 );

  if(! HWLOC_XSAPI_VERSION()) {
    push @names, qw(
		    hwloc_cpuset_andset hwloc_cpuset_orset hwloc_cpuset_xorset
		    hwloc_cpuset_compar hwloc_cpuset_compar_first
		   );
  } else {
    push @names, qw(
		    hwloc_cpuset_and hwloc_cpuset_andnot hwloc_cpuset_not
		    hwloc_cpuset_or hwloc_cpuset_xor
		    hwloc_cpuset_clr_range hwloc_cpuset_next
		    hwloc_cpuset_compare hwloc_cpuset_compare_first

		    hwloc_cpuset_from_liststring hwloc_cpuset_list_sprintf
		   );
  }
}

if(HWLOC_XSAPI_VERSION() >= 0x00010100) {
  push @names, qw(
		  HWLOC_CPUBIND_NOMEMBIND

		  HWLOC_MEMBIND_PROCESS
		  HWLOC_MEMBIND_THREAD
		  HWLOC_MEMBIND_STRICT
		  HWLOC_MEMBIND_MIGRATE
		  HWLOC_MEMBIND_NOCPUBIND
		  HWLOC_MEMBIND_DEFAULT
		  HWLOC_MEMBIND_FIRSTTOUCH
		  HWLOC_MEMBIND_BIND
		  HWLOC_MEMBIND_INTERLEAVE
		  HWLOC_MEMBIND_REPLICATE
		  HWLOC_MEMBIND_NEXTTOUCH

		  hwloc_obj_get_info_by_name

		  hwloc_bitmap_alloc hwloc_bitmap_alloc_full hwloc_bitmap_dup hwloc_bitmap_free
		  hwloc_bitmap_fill hwloc_bitmap_singlify hwloc_bitmap_zero
		  hwloc_bitmap_allbut hwloc_bitmap_clr hwloc_bitmap_only hwloc_bitmap_set
		  hwloc_bitmap_clr_range hwloc_bitmap_set_range
		  hwloc_bitmap_copy
		  hwloc_bitmap_from_ith_ulong hwloc_bitmap_set_ith_ulong hwloc_bitmap_sscanf hwloc_bitmap_from_ulong
		  hwloc_bitmap_and hwloc_bitmap_andnot hwloc_bitmap_or hwloc_bitmap_xor hwloc_bitmap_not
		  hwloc_bitmap_first hwloc_bitmap_last hwloc_bitmap_next hwloc_bitmap_ids
		  hwloc_bitmap_sprintf hwloc_bitmap_to_ith_ulong hwloc_bitmap_to_ulong hwloc_bitmap_weight
		  hwloc_bitmap_compare hwloc_bitmap_isequal hwloc_bitmap_compare_first hwloc_bitmap_intersects
		  hwloc_bitmap_isincluded hwloc_bitmap_includes
		  hwloc_bitmap_isfull hwloc_bitmap_iszero hwloc_bitmap_isset
		  hwloc_bitmap_taskset_sscanf hwloc_bitmap_taskset_sprintf

		  hwloc_bitmap_list_sscanf hwloc_bitmap_list_sprintf

		  hwloc_cpuset_to_nodeset hwloc_cpuset_to_nodeset_strict
		  hwloc_cpuset_from_nodeset hwloc_cpuset_from_nodeset_strict

		  hwloc_topology_get_complete_nodeset
		  hwloc_topology_get_topology_nodeset
		  hwloc_topology_get_allowed_nodeset

		  hwloc_set_membind hwloc_set_membind_nodeset
		  hwloc_set_proc_membind hwloc_set_proc_membind_nodeset
		  hwloc_get_membind hwloc_get_membind_nodeset
		  hwloc_get_proc_membind hwloc_get_proc_membind_nodeset
		 );
}

if(HWLOC_HAS_XML()) {
  push @names, qw(
		  hwloc_topology_export_xml
		 );
}


# --
# Sys::Hwloc::Topology methods with aliases
# --

my @topoMethods = qw(
		     check destroy init load
		     ignore_type ignore_type_keep_structure ignore_all_keep_structure
		     set_flags set_fsroot set_synthetic set_xml

		     get_depth depth
		     get_type_depth type_depth
		     get_depth_type depth_type
		     get_nbobjs_by_depth nbobjs_by_depth
		     get_nbobjs_by_type nbobjs_by_type
		     is_thissystem
		     get_obj_by_depth obj_by_depth
		     get_obj_by_type obj_by_type

		     sprintf_obj

		     get_type_or_below_depth type_or_below_depth
		     get_type_or_above_depth type_or_above_depth
		     get_next_obj_by_depth next_obj_by_depth
		     get_next_obj_by_type next_obj_by_type
		     get_common_ancestor_obj common_ancestor_obj
		     obj_is_in_subtree
		     get_closest_objs
		     compare_objects

		     get_nbobjs_inside_cpuset_by_depth
		     get_nbobjs_inside_cpuset_by_type
		     get_obj_inside_cpuset_by_depth
		     get_obj_inside_cpuset_by_type
		     get_next_obj_inside_cpuset_by_depth
		     get_next_obj_inside_cpuset_by_type
		     get_largest_objs_inside_cpuset

		     set_cpubind set_proc_cpubind
		    );

if(! HWLOC_API_VERSION()) {
  push @topoMethods, qw(
			system_obj system
		       );
} else {
  push @topoMethods, qw(
			set_pid
			get_support
			root_obj root
			get_pu_obj_by_os_index pu_obj_by_os_index
			get_obj_below_by_type

			get_complete_cpuset get_topology_cpuset
			get_online_cpuset get_allowed_cpuset

			get_first_largest_obj_inside_cpuset

			get_cpubind get_proc_cpubind
		       );

  if(HWLOC_XSAPI_VERSION() >= 0x00010100) {
    push @topoMethods, qw(
			  cpuset_to_nodeset cpuset_to_nodeset_strict
			  cpuset_from_nodeset cpuset_from_nodeset_strict

			  get_complete_nodeset get_topology_nodeset get_allowed_nodeset

			  set_membind set_membind_nodeset
			  set_proc_membind set_proc_membind_nodeset
			  get_membind get_membind_nodeset
			  get_proc_membind get_proc_membind_nodeset
			 );
  }
}

if(HWLOC_HAS_XML()) {
  push @topoMethods, qw(
			export_xml
		       );
}

# --
# Sys::Hwloc::Obj methods with aliases
# --

my @objMethods = qw(
		    type os_index name attr depth logical_index os_level
		    next_cousin prev_cousin
		    sibling_rank next_sibling prev_sibling
		    arity children first_child last_child
		    sprintf sprintf_cpuset
		    get_next_child next_child
		    get_common_ancestor common_ancestor
		    is_in_subtree
		    is_same_obj
		    cpuset
		   );

if(! HWLOC_API_VERSION()) {
  push @objMethods, qw(
		       father
		      );
} else {
  push @objMethods, qw(
		       memory
		       parent
		       sprintf_type
		       sprintf_attr
		       ancestor_by_depth
		       ancestor_by_type
		       complete_cpuset online_cpuset allowed_cpuset
		       nodeset complete_nodeset allowed_nodeset
		      );

  if(HWLOC_API_VERSION() > 0x00010000) {
    push @objMethods, qw(
			 infos
			 get_info_by_name info_by_name
			);
  }

}

# --
# Sys::Hwloc::Cpuset methods with aliases
# --

my @cpusetMethods = ();

if(HWLOC_XSAPI_VERSION() <= 0x00010000) {
  @cpusetMethods = qw(
		      alloc new dup free destroy

		      all_but_cpu clr
		      copy cpu fill
		      from_ith_ulong from_ulong
		      set set_range singlify zero

		      first last ids
		      sprintf to_ith_ulong to_ulong weight

		      includes intersects isequal isfull isincluded
		      isset iszero
		     );
  if(! HWLOC_XSAPI_VERSION()) {
    push @cpusetMethods, qw(
			    and or xor
			    compar compar_first
			   );
  } else {
    push @cpusetMethods, qw(
			    from_string from_liststring
			    clr_range
			    and andnot not or xor
			    next
			    compare compare_first
			    sprintf_list
			   );
  }
}

# --
# Sys::Hwloc::Bitmap methods with aliases
# --

my @bitmapMethods = ();

if(HWLOC_XSAPI_VERSION() >= 0x00010100) {
  @bitmapMethods = qw(
		      alloc alloc_full new dup free destroy
		      fill singlify zero
		      allbut clr only set
		      clr_range set_range
		      copy
		      from_ith_ulong set_ith_ulong sscanf from_ulong
		      and andnot or xor not
		      first last next ids
		      sprintf to_ith_ulong to_ulong weight
		      compare isequal compare_first intersects
		      isincluded includes
		      isfull iszero isset
		      sscanf_taskset sprintf_taskset
		      sprintf_list sscanf_list
		     );
}

# -----------------------------------------------------------------------------
# HERE STARTS THE REAL WORK
# -----------------------------------------------------------------------------

plan tests => (scalar @names)         +
              (scalar @topoMethods)   +
              (scalar @objMethods)    +
              (scalar @cpusetMethods) +
              (scalar @bitmapMethods);

foreach my $name (@names) {
  can_ok('Sys::Hwloc', $name);
}

foreach my $name (@topoMethods) {
  can_ok('Sys::Hwloc::Topology', $name);
}

foreach my $name (@objMethods) {
  can_ok('Sys::Hwloc::Obj', $name);
}

foreach my $name (@cpusetMethods) {
  can_ok('Sys::Hwloc::Cpuset', $name);
}

foreach my $name (@bitmapMethods) {
  can_ok('Sys::Hwloc::Bitmap', $name);
}

