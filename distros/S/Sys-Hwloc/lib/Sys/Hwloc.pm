################################################################################
#
#  Copyright 2010 Zuse Institute Berlin
#
#  This package and its accompanying libraries is free software; you can
#  redistribute it and/or modify it under the terms of the GPL version 2.0,
#  or the Artistic License 2.0. Refer to LICENSE for the full license text.
#
#  Please send comments to kallies@zib.de
#
################################################################################
# $Id: Hwloc.pm,v 1.36 2011/01/11 10:49:39 bzbkalli Exp $
################################################################################

package Sys::Hwloc;

use 5.006;
use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
use warnings;
use Carp;

BEGIN {

  $VERSION = '0.10';

  require Exporter;
  use AutoLoader;
  @ISA = qw(Exporter);

  sub HWLOC_API_VERSION   { @HWLOC_API_VERSION@ }
  sub HWLOC_XSAPI_VERSION { HWLOC_API_VERSION() ? HWLOC_API_VERSION() : 0 }

  @EXPORT  = qw(
		HWLOC_API_VERSION
		HWLOC_XSAPI_VERSION
		HWLOC_HAS_XML
		hwloc_get_api_version

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

		hwloc_compare_types

		hwloc_topology_check hwloc_topology_destroy hwloc_topology_init hwloc_topology_load

		hwloc_topology_ignore_type hwloc_topology_ignore_type_keep_structure hwloc_topology_ignore_all_keep_structure
		hwloc_topology_set_flags hwloc_topology_set_fsroot hwloc_topology_set_synthetic hwloc_topology_set_xml

		hwloc_topology_export_xml

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
		hwloc_get_common_ancestor_obj hwloc_obj_is_in_subtree
		hwloc_get_closest_objs

		hwloc_compare_objects
	       );

  if(! HWLOC_XSAPI_VERSION()) {
    push @EXPORT, qw(
		     HWLOC_OBJ_PROC
		     hwloc_get_system_obj
		    );
  } else {
    push @EXPORT, qw(
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
		    );

    if(HWLOC_XSAPI_VERSION() > 0x00010000) {
      push @EXPORT, qw(
		       hwloc_obj_get_info_by_name
		      );
    }

  }

  # --
  # Cpuset API and helpers
  # --

  if(HWLOC_XSAPI_VERSION() <= 0x00010000) {
    $EXPORT_TAGS{cpuset} = [qw(
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

			       hwloc_get_nbobjs_inside_cpuset_by_depth
			       hwloc_get_nbobjs_inside_cpuset_by_type
			       hwloc_get_obj_inside_cpuset_by_depth
			       hwloc_get_obj_inside_cpuset_by_type
			       hwloc_get_next_obj_inside_cpuset_by_depth
			       hwloc_get_next_obj_inside_cpuset_by_type
			       hwloc_get_largest_objs_inside_cpuset
			      )];

    if(! HWLOC_XSAPI_VERSION()) {
      push @{$EXPORT_TAGS{cpuset}}, qw(
				       hwloc_cpuset_andset hwloc_cpuset_orset hwloc_cpuset_xorset
				       hwloc_cpuset_compar hwloc_cpuset_compar_first
				      );
    } else {
      push @{$EXPORT_TAGS{cpuset}}, qw(
				       hwloc_cpuset_clr_range
				       hwloc_cpuset_and hwloc_cpuset_andnot hwloc_cpuset_not
				       hwloc_cpuset_or hwloc_cpuset_xor
				       hwloc_cpuset_next
				       hwloc_cpuset_compare hwloc_cpuset_compare_first

				       hwloc_cpuset_from_liststring
				       hwloc_cpuset_list_sprintf

				       hwloc_topology_get_complete_cpuset hwloc_topology_get_topology_cpuset
				       hwloc_topology_get_online_cpuset hwloc_topology_get_allowed_cpuset

				       hwloc_get_first_largest_obj_inside_cpuset
				      );
    }

    $EXPORT_TAGS{bitmap} = [];

  }

  # --
  # Bitmap API and helpers
  # --

  else {

    $EXPORT_TAGS{cpuset} = [];

    $EXPORT_TAGS{bitmap} = [qw(
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

			       hwloc_bitmap_list_sprintf hwloc_bitmap_list_sscanf

			       hwloc_topology_get_complete_cpuset hwloc_topology_get_topology_cpuset
			       hwloc_topology_get_online_cpuset hwloc_topology_get_allowed_cpuset

			       hwloc_topology_get_complete_nodeset hwloc_topology_get_topology_nodeset
			       hwloc_topology_get_allowed_nodeset

			       hwloc_cpuset_to_nodeset hwloc_cpuset_to_nodeset_strict
			       hwloc_cpuset_from_nodeset hwloc_cpuset_from_nodeset_strict

			       hwloc_get_nbobjs_inside_cpuset_by_depth
			       hwloc_get_nbobjs_inside_cpuset_by_type
			       hwloc_get_obj_inside_cpuset_by_depth
			       hwloc_get_obj_inside_cpuset_by_type
			       hwloc_get_next_obj_inside_cpuset_by_depth
			       hwloc_get_next_obj_inside_cpuset_by_type
			       hwloc_get_first_largest_obj_inside_cpuset
			       hwloc_get_largest_objs_inside_cpuset
			      )];

  }

  Exporter::export_ok_tags('cpuset');
  Exporter::export_ok_tags('bitmap');

  # --
  # Binding API
  # --

  $EXPORT_TAGS{binding} = [qw(
			      HWLOC_CPUBIND_PROCESS
			      HWLOC_CPUBIND_THREAD
			      HWLOC_CPUBIND_STRICT

			      hwloc_set_cpubind hwloc_set_proc_cpubind
			     )];

  if(HWLOC_XSAPI_VERSION()) {
    push @{$EXPORT_TAGS{binding}}, qw(
				      hwloc_get_cpubind hwloc_get_proc_cpubind
				     );
  }
  if(HWLOC_XSAPI_VERSION() > 0x00010000) {
    push @{$EXPORT_TAGS{binding}}, qw(
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

				      hwloc_set_membind hwloc_set_membind_nodeset
				      hwloc_set_proc_membind hwloc_set_proc_membind_nodeset
				      hwloc_get_membind hwloc_get_membind_nodeset
				      hwloc_get_proc_membind hwloc_get_proc_membind_nodeset
				     );
  }

  Exporter::export_ok_tags('binding');

  # --
  # Bootstrap
  # --

  require XSLoader;
  XSLoader::load('Sys::Hwloc', $VERSION);

  # --
  # Check compile-time API version against run-time API version
  # --

  my $runtime_version = hwloc_get_api_version();
  if(defined $runtime_version) {
    if(HWLOC_XSAPI_VERSION() != $runtime_version) {
      warn sprintf("Warning: Sys::Hwloc compiled against libhwloc API version %#010x, but runtime libhwloc API version is %#010x\n",
		   HWLOC_XSAPI_VERSION(), $runtime_version);
    }
  } else {
#    warn sprintf("Warning: Sys::Hwloc compiled against libhwloc API version %#010x, but runtime libhwloc API version cannot be determined\n",
#		 HWLOC_XSAPI_VERSION());
  }

}

sub AUTOLOAD {
  # This AUTOLOAD is used to 'autoload' constants from the constant() XS function.

  my $constname;
  our $AUTOLOAD;
  ($constname = $AUTOLOAD) =~ s/.*:://;
  croak "&Sys::Hwloc::constant not defined" if $constname eq 'constant';
  my ($error, $val) = constant($constname);
  if ($error) { croak $error; }
  {
    no strict 'refs';
    *$AUTOLOAD = sub { $val };
  }
  goto &$AUTOLOAD;
}

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;

=pod

=head1 NAME

Sys::Hwloc - Perl Access to Portable Hardware Locality (hwloc)

=head1 SYNOPSIS

       use Sys::Hwloc;

       # Load topology
       $topology = hwloc_topology_init();
       die "Failed to init topology" unless $topology;
       $rc = hwloc_topology_load($topology);
       die "Failed to load topology" if $rc;

       # Determine number of sockets and processors
       $nProcs   = hwloc_get_nbobjs_by_type($topology, HWLOC_OBJ_PU);
       $nSockets = hwloc_get_nbobjs_by_type($topology, HWLOC_OBJ_SOCKET);
       die "Failed to determine number of processors" unless $nProcs;
       die "Failed to determine number of sockets"    unless $nSockets;
       printf "Topology contains %d processors on %d sockets.\n", $nProcs, $nSockets;

       # Compute the amount of cache of the first logical processor
       $levels = 0;
       $size   = 0;
       for($obj = hwloc_get_obj_by_type($topology, HWLOC_OBJ_PU, 0);
           $obj;
           $obj = $obj->parent
          ) {
         next unless $obj->type == HWLOC_OBJ_CACHE;
         $levels++;
         $size += $obj->attr->{cache}->{size};
       }
       printf "Logical CPU 0 has %d caches with total %dkB.\n", $levels, $size / 1024;

       # Destroy topology
       hwloc_topology_destroy($topology);


or going the OO-ish way:

       use Sys::Hwloc;

       # Load topology
       $topology = Sys::Hwloc::Topology->init;
       die "Failed to init topology" unless $topology;
       $rc = $topology->load;
       die "Failed to load topology" if $rc;

       # Determine number of sockets and processors
       $nProcs   = $topology->get_nbobjs_by_type(HWLOC_OBJ_PU);
       $nSockets = $topology->get_nbobjs_by_type(HWLOC_OBJ_SOCKET);
       die "Failed to determine number of processors" unless $nProcs;
       die "Failed to determine number of sockets"    unless $nSockets;
       printf "Topology contains %d processors on %d sockets.\n", $nProcs, $nSockets;

       # Stringify the left side of the topology tree
       for($obj = $topology->get_obj_by_depth(0,0);
           $obj;
           $obj = $obj->first_child
          ) {
         printf("%*s%s#%d (%s)\n",
	        $obj->depth, '',
	        $obj->sprintf_type,
	        $obj->logical_index,
	        $obj->sprintf_attr('; ',1),
	       );
       }

       # Destroy topology
       $topology->destroy;


=head1 DESCRIPTION

The Sys::Hwloc module provides a Perl wrapper API around the Portable Hardware Locality (hwloc) C API.

Visit L<http://www.open-mpi.org/projects/hwloc> for information about hwloc.

The module provides access to the functions of the hwloc API as well
as an object-oriented interface to I<hwloc_topology>, I<hwloc_obj> and I<hwloc_cpuset> objects.

=head1 EXPORT/IMPORT

The Sys::Hwloc module exports constants and functions of the hwloc core ABI and basic helpers by default.
To import these, load the module with one of the following:

       use Sys::Hwloc;
       use Sys::Hwloc qw(:DEFAULT);

Names of constants and functions belonging to the Cpuset API, the Bitmap API and the Binding API have to be
imported explicitely.

Examples:

       use Sys::Hwloc qw(:DEFAULT :cpuset);
       use Sys::Hwloc qw(:DEFAULT :bitmap :binding);

To get a list of what is exported by default, type:

   perl -MSys::Hwloc -MData::Dumper -e 'print Dumper(\@Sys::Hwloc::EXPORT)'

To get a list of optional symbols, type:

   perl -MSys::Hwloc -MData::Dumper -e 'print Dumper(\%Sys::Hwloc::EXPORT_TAGS)'

=head1 CONSTANTS

The following constants are exported by the Sys::Hwloc module:

=head2 Type of topology objects

       HWLOC_OBJ_MACHINE
       HWLOC_OBJ_NODE
       HWLOC_OBJ_SOCKET
       HWLOC_OBJ_CACHE
       HWLOC_OBJ_CORE
       HWLOC_OBJ_PROC                                     before hwloc-1.0
       HWLOC_OBJ_PU                                       since  hwloc-1.0
       HWLOC_OBJ_GROUP                                    since  hwloc-1.0
       HWLOC_OBJ_MISC

=head2 Topology flags

       HWLOC_TOPOLOGY_FLAG_WHOLE_SYSTEM
       HWLOC_TOPOLOGY_FLAG_IS_THISSYSTEM

=head2 Misc

       HWLOC_API_VERSION                                  undef before hwloc-1.0
       HWLOC_XSAPI_VERSION                                0     before hwloc-1.0
       HWLOC_HAS_XML                                      hwloc built with XML or not
       HWLOC_TYPE_UNORDERED
       HWLOC_TYPE_DEPTH_UNKNOWN
       HWLOC_TYPE_DEPTH_MULTIPLE

=head1 METHODS

The following methods are exported by default.

Each listing contains the methods that conform to the hwloc C API,
and the corresponding Hwloc perl API OO-ish methods, if implemented.

=head2 Create and destroy topologies

       $t    = hwloc_topology_init()
       $rc   = hwloc_topology_load($t)
       hwloc_topology_check($t)
       hwloc_topology_destroy($t)

       $t    = Sys::Hwloc::Topology->init
       $t    = Sys::Hwloc::Topology->new
       $rc   = $t->load
       $t->check
       $t->destroy

=head2 Configure topology detection

       $rc   = hwloc_topology_ignore_type($t,$type)
       $rc   = hwloc_topology_ignore_type_keep_structure($t,$type)
       $rc   = hwloc_topology_ignore_all_keep_structure($t)
       $rc   = hwloc_topology_set_flags($t,$flags)
       $rc   = hwloc_topology_set_fsroot($t,$path)
       $rc   = hwloc_topology_set_pid($t,$pid)                   since  hwloc-1.0
       $rc   = hwloc_topology_set_synthetic($t,$string)
       $rc   = hwloc_topology_set_xml($t,$path)
       $href = hwloc_topology_get_support($t)                    since  hwloc-1.0

       $rc   = $t->ignore_type($type)
       $rc   = $t->ignore_type_keep_structure($type)
       $rc   = $t->ignore_all_keep_structure
       $rc   = $t->set_flags($flags)
       $rc   = $t->set_fsroot($path)
       $rc   = $t->set_pid($pid)                                 since  hwloc-1.0
       $rc   = $t->set_synthetic($string)
       $rc   = $t->set_xml($path)
       $href = $t->get_support                                   since  hwloc-1.0

=head2 Tinker with topologies

       hwloc_topology_export_xml($t,$path)                       if HWLOC_HAS_XML

       $t->export_xml($path)                                     if HWLOC_HAS_XML

=head2 Get some topology information

       $val  = hwloc_topology_get_depth($t)
       $val  = hwloc_topology_get_type_depth($t,$type)
       $val  = hwloc_topology_get_depth_type($t,$depth)
       $val  = hwloc_get_nbobjs_by_depth($t,$depth)
       $val  = hwloc_get_nbobjs_by_type($t,$type)
       $rc   = hwloc_topology_is_thissystem($t)

       $val  = $t->depth
       $val  = $t->get_type_depth($type)
       $val  = $t->get_depth_type($depth)
       $val  = $t->get_nbobjs_by_depth($depth)
       $val  = $t->get_nbobjs_by_type($type)
       $rc   = $t->is_thissystem

=head2 Retrieve topology objects

       $obj  = hwloc_get_obj_by_depth($t,$depth,$idx)
       $obj  = hwloc_get_obj_by_type($t,$type,$idx)

       $obj  = $t->get_obj_by_depth($depth,$idx)
       $obj  = $t->get_obj_by_type($type,$idx)

=head2 Topology object properties

       $val  = $obj->type
       $val  = $obj->os_index
       $val  = $obj->name
       $href = $obj->memory                                      since  hwloc-1.0
       $href = $obj->attr                                        since  hwloc-1.0
       $val  = $obj->depth
       $val  = $obj->logical_index
       $val  = $obj->os_level
       $obj  = $obj->next_cousin
       $obj  = $obj->prev_cousin
       $obj  = $obj->father                                      before hwloc-1.0
       $obj  = $obj->parent                                      since  hwloc-1.0
       $val  = $obj->sibling_rank
       $obj  = $obj->next_sibling
       $obj  = $obj->prev_sibling
       $val  = $obj->arity
       @objs = $obj->children
       $obj  = $obj->first_child
       $obj  = $obj->last_child
       $set  = $obj->cpuset
       $set  = $obj->complete_cpuset                             since  hwloc-1.0
       $set  = $obj->online_cpuset                               since  hwloc-1.0
       $set  = $obj->allowed_cpuset                              since  hwloc-1.0
       $set  = $obj->nodeset                                     since  hwloc-1.0
       $set  = $obj->complete_nodeset                            since  hwloc-1.0
       $set  = $obj->allowed_nodeset                             since  hwloc-1.0
       $href = $obj->infos                                       since  hwloc-1.1

=head2 Object/string conversion

       $val  = hwloc_obj_type_string($type)
       $val  = hwloc_obj_type_of_string($string)
       $val  = hwloc_obj_type_sprintf($obj,$verbose)             since  hwloc-1.0
       $val  = hwloc_obj_attr_sprintf($obj,$separator,$verbose)  since  hwloc-1.0
       $val  = hwloc_obj_cpuset_sprintf($obj1,$obj2,...)
       $val  = hwloc_obj_sprintf($t,$obj,$prefix,$verbose)
       $val  = hwloc_obj_get_info_by_name($obj,$string)          since  hwloc-1.1

       $val  = $obj->sprintf_type($verbose)                      since  hwloc-1.0
       $val  = $obj->sprintf_attr($separator,$verbose)           since  hwloc-1.0
       $val  = $obj->sprintf_cpuset
       $val  = $t->sprintf_obj($obj,$prefix,$verbose)
       $val  = $obj->sprintf($prefix,$verbose)
       $val  = $obj->info_by_name($string)                       since  hwloc-1.1

=head2 Object type helpers

       $val  = hwloc_compare_types($type1,$type2)

       $val  = hwloc_get_type_or_below_depth($t,$type)
       $val  = hwloc_get_type_or_above_depth($t,$type)

       $val  = $t->get_type_or_below_depth($type)
       $val  = $t->get_type_or_above_depth($type)

=head2 Traversal helpers

       $obj  = hwloc_get_system_obj($t)                                   before hwloc-1.0
       $obj  = hwloc_get_root_obj($t)                                     since  hwloc-1.0
       $obj  = hwloc_get_ancestor_obj_by_depth($obj,$depth)               since  hwloc-1.0
       $obj  = hwloc_get_ancestor_obj_by_type($obj,$type)                 since  hwloc-1.0
       $obj  = hwloc_get_next_obj_by_depth($t,$depth,$obj)
       $obj  = hwloc_get_next_obj_by_type($t,$type,$obj)
       $obj  = hwloc_get_pu_obj_by_os_index($t,$idx)                      since  hwloc-1.0
       $obj  = hwloc_get_next_child($obj,$childobj)
       $obj  = hwloc_get_common_ancestor_obj($t,$obj1,$obj2)
       $rc   = hwloc_obj_is_in_subtree($t,$obj1,$obj2)
       @objs = hwloc_get_closest_objs($t,$obj)
       $obj  = hwloc_get_obj_below_by_type($t,$type1,$idx1,$type2,$idx2)  since hwloc-1.0
       $rc   = hwloc_compare_objects($t,$obj1,$obj2)                      not in hwloc

       $obj  = $t->system                                                 before hwloc-1.0
       $obj  = $t->root                                                   since  hwloc-1.0
       $obj  = $obj->ancestor_by_depth($depth)                            since  hwloc-1.0
       $obj  = $obj->ancestor_by_type($type)                              since  hwloc-1.0
       $obj  = $t->get_next_obj_by_depth($depth,$obj)
       $obj  = $t->get_next_obj_by_type($type,$obj)
       $obj  = $t->get_pu_obj_by_os_index($idx)                           since  hwloc-1.0
       $obj  = $obj->next_child($childobj)
       $obj  = $t->get_common_ancestor_obj($obj1,$obj2)
       $obj  = $obj->common_ancestor($obj)
       $rc   = $t->obj_is_in_subtree($obj1,$obj2)
       $rc   = $obj->is_in_subtree($obj)
       @objs = $t->get_closest_objs($obj)
       $obj  = $t->get_obj_below_by_type($type1,$idx1,$type2,$idx2)       since hwloc-1.0
       $rc   = $t->compare_objects($obj1,$obj2)                           not in hwloc
       $rc   = $obj->is_same_obj($obj)                                    not in hwloc

=head1 CPUSET API (before hwloc-1.1)

The hwloc C API of hwloc-0.9 and 1.0 defines the B<Cpuset API>.

The Sys::Hwloc module exports the corresponding methods and some utility functions, when
requested with

       use Sys::Hwloc qw(:DEFAULT :cpuset);

=head2 Cpuset API

       $set  = hwloc_cpuset_alloc
       $seta = hwloc_cpuset_dup($set)
       $set  = hwloc_cpuset_from_string($string)                 before hwloc-1.0
       hwloc_cpuset_free($set)
       hwloc_cpuset_copy($dstset,$srcset)
       hwloc_cpuset_zero($set)
       hwloc_cpuset_fill($set)
       hwloc_cpuset_cpu($set,$id)
       hwloc_cpuset_all_but_cpu($set,$id)
       hwloc_cpuset_from_ulong($set,$mask)
       hwloc_cpuset_from_ith_ulong($set,$i,$mask)
       $rc   = hwloc_cpuset_from_string($set,$string)            since  hwloc-1.0
       $rc   = hwloc_cpuset_from_liststring($set,$string)        not in hwloc
       hwloc_cpuset_set($set,$id)
       hwloc_cpuset_set_range($set,$ida,$ide)
       hwloc_cpuset_set_ith_ulong($set,$i,$mask)
       hwloc_cpuset_clr($set,$id)
       hwloc_cpuset_clr_range($set,$ida1,$ide)                   since  hwloc-1.0
       hwloc_cpuset_singlify($set)
       $val  = hwloc_cpuset_to_ulong($set)
       $val  = hwloc_cpuset_to_ith_ulong($set,$i)
       $val  = hwloc_cpuset_sprintf($set)
       $val  = hwloc_cpuset_list_sprintf($set)                   not in hwloc
       @vals = hwloc_cpuset_ids($set)                            not in hwloc
       $rc   = hwloc_cpuset_isset($set,$id)
       $rc   = hwloc_cpuset_iszero($set)
       $rc   = hwloc_cpuset_isfull($set)
       $val  = hwloc_cpuset_first($set)
       $val  = hwloc_cpuset_next($set,$prev)                     since  hwloc-1.0
       $val  = hwloc_cpuset_last($set)
       $val  = hwloc_cpuset_weight($set)
       hwloc_cpuset_orset($set,$seta)                            before hwloc-1.0
       hwloc_cpuset_andset($set,$seta)                           before hwloc-1.0
       hwloc_cpuset_xorset($set,$seta)                           before hwloc-1.0
       hwloc_cpuset_or($set,$seta,$setb)                         since  hwloc-1.0
       hwloc_cpuset_and($set,$seta,$setb)                        since  hwloc-1.0
       hwloc_cpuset_andnot($set,$seta,$setb)                     since  hwloc-1.0
       hwloc_cpuset_xor($set,$seta,$setb)                        since  hwloc-1.0
       hwloc_cpuset_not($set,$seta)                              since  hwloc-1.0
       $rc   = hwloc_cpuset_intersects($seta,$setb)
       $rc   = hwloc_cpuset_includes($seta,$setb)                not in hwloc
       $rc   = hwloc_cpuset_isincluded($seta,$setb)
       $rc   = hwloc_cpuset_isequal($seta,$setb)
       $rc   = hwloc_cpuset_compar($seta,$setb)                  before hwloc-1.0
       $rc   = hwloc_cpuset_compar_first($seta,$setb)            before hwloc-1.0
       $rc   = hwloc_cpuset_compare($seta,$setb)                 since  hwloc-1.0
       $rc   = hwloc_cpuset_compare_first($seta,$setb)           since  hwloc-1.0

       $set  = Sys::Hwloc::Cpuset->alloc
       $set  = Sys::Hwloc::Cpuset->new
       $seta = $set->dup
       $set->free
       $set->destroy
       $set->copy($seta)
       $set->zero
       $set->fill
       $set->cpu($id)
       $set->all_but_cpu($id)
       $set->from_ulong($mask)
       $set->from_ith_ulong($i,$mask)
       $rc   = $set->from_string($string)                        since  hwloc-1.0
       $rc   = $set->from_liststring($string)                    not in hwloc
       $set->set($id)
       $set->set_range($ida,$ide)
       $set->set_ith_ulong($i,$mask)
       $set->clr($id)
       $set->clr_range($ida,$ide)                                since  hwloc-1.0
       $set->singlify
       $val  = $set->to_ulong
       $val  = $set->to_ith_ulong($i)
       $val  = $set->sprintf
       $val  = $set->sprintf_list                                not in hwloc
       @vals = $set->ids                                         not in hwloc
       $rc   = $set->isset($id)
       $rc   = $set->iszero
       $rc   = $set->isfull
       $val  = $set->first
       $val  = $set->next($prev)
       $val  = $set->last
       $val  = $set->weight
       $set->or($seta)
       $set->and($seta)
       $set->andnot($seta)                                       since  hwloc-1.0
       $set->xor($seta)
       $set->not                                                 since  hwloc-1.0
       $rc   = $set->intersects($seta)
       $rc   = $set->includes($seta)                             not in hwloc
       $rc   = $set->isincluded($seta)
       $rc   = $set->isequal($seta)
       $rc   = $set->compar($seta)                               before hwloc-1.0
       $rc   = $set->compar_first($seta)                         before hwloc-1.0
       $rc   = $set->compare($seta)                              since  hwloc-1.0
       $rc   = $set->compare_first($seta)                        since  hwloc-1.0

=head2 Cpuset and Nodeset helpers

       $set  = hwloc_topology_get_complete_cpuset($t)            since  hwloc-1.0
       $set  = hwloc_topology_get_topology_cpuset($t)            since  hwloc-1.0
       $set  = hwloc_topology_get_online_cpuset($t)              since  hwloc-1.0
       $set  = hwloc_topology_get_allowed_cpuset($t)             since  hwloc-1.0
       $rc   = hwloc_get_nbobjs_inside_cpuset_by_depth($t,$set,$depth)
       $rc   = hwloc_get_nbobjs_inside_cpuset_by_type($t,$set,$type)
       $obj  = hwloc_get_obj_inside_cpuset_by_depth($t,$set,$depth)
       $obj  = hwloc_get_obj_inside_cpuset_by_type($t,$set,$type)
       $obj  = hwloc_get_next_obj_inside_cpuset_by_depth($t,$set,$depth,$prev)
       $obj  = hwloc_get_next_obj_inside_cpuset_by_type($t,$set,$type,$prev)
       $obj  = hwloc_get_first_largest_obj_inside_cpuset($t,$set) since hwloc-1.0
       @objs = hwloc_get_largest_objs_inside_cpuset($t,$set)

       $set  = $t->get_complete_cpuset                           since  hwloc-1.0
       $set  = $t->get_topology_cpuset                           since  hwloc-1.0
       $set  = $t->get_online_cpuset                             since  hwloc-1.0
       $set  = $t->get_allowed_cpuset                            since  hwloc-1.0
       $rc   = $t->get_nbobjs_inside_cpuset_by_depth($set,$depth)
       $rc   = $t->get_nbobjs_inside_cpuset_by_type($set,$type)
       $obj  = $t->get_obj_inside_cpuset_by_depth($set,$depth)
       $obj  = $t->get_obj_inside_cpuset_by_type($set,$type)
       $obj  = $t->get_next_obj_inside_cpuset_by_depth($set,$depth,$prev)
       $obj  = $t->get_next_obj_inside_cpuset_by_type($set,$type,$prev)
       $obj  = $t->get_first_largest_obj_inside_cpuset($set)
       @objs = $t->get_largest_objs_inside_cpuset($set)

=head1 BITMAP API (since hwloc-1.1)

The hwloc C API since hwloc-1.1 defines the B<Bitmap API>, which replaces the B<Cpuset API>.

The Sys::Hwloc module exports the corresponding methods and some utility functions, when
requested with

       use Sys::Hwloc qw(:DEFAULT :bitmap);

=head2 Bitmap API

       $map  = hwloc_bitmap_alloc
       $map  = hwloc_bitmap_alloc_full
       $mapa = hwloc_bitmap_dup($map)
       hwloc_bitmap_free($map)
       hwloc_bitmap_copy($dstmap,$srcmap)
       hwloc_bitmap_zero($map)
       hwloc_bitmap_fill($map)
       hwloc_bitmap_only($map,$id)
       hwloc_bitmap_allbut($map,$id)
       hwloc_bitmap_from_ulong($map,$mask)
       hwloc_bitmap_from_ith_ulong($map,$i,$mask)
       $rc   = hwloc_bitmap_sscanf($map,$string)
       $rc   = hwloc_bitmap_list_sscanf($map,$string)            not in hwloc
       $rc   = hwloc_bitmap_taskset_sscanf($map,$string)
       hwloc_bitmap_set($map,$id)
       hwloc_bitmap_set_range($map,$ida,$ide)
       hwloc_bitmap_set_ith_ulong($map,$i,$mask)
       hwloc_bitmap_clr($map,$id)
       hwloc_bitmap_clr_range($map,$ida1,$ide)
       hwloc_bitmap_singlify($map)
       $val  = hwloc_bitmap_to_ulong($map)
       $val  = hwloc_bitmap_to_ith_ulong($map,$i)
       $val  = hwloc_bitmap_sprintf($map)
       $val  = hwloc_bitmap_list_sprintf($map)                   not in hwloc
       $val  = hwloc_bitmap_taskset_sprintf($map)
       @vals = hwloc_bitmap_ids($map)                            not in hwloc
       $rc   = hwloc_bitmap_isset($map,$id)
       $rc   = hwloc_bitmap_iszero($map)
       $rc   = hwloc_bitmap_isfull($map)
       $val  = hwloc_bitmap_first($map)
       $val  = hwloc_bitmap_next($map,$prev)
       $val  = hwloc_bitmap_last($map)
       $val  = hwloc_bitmap_weight($map)
       hwloc_bitmap_or($map,$mapa,$mapb)
       hwloc_bitmap_and($map,$mapa,$mapb)
       hwloc_bitmap_andnot($map,$mapa,$mapb)
       hwloc_bitmap_xor($map,$mapa,$mapb)
       hwloc_bitmap_not($map,$mapa)
       $rc   = hwloc_bitmap_intersects($mapa,$mapb)
       $rc   = hwloc_bitmap_includes($mapa,$mapb)                not in hwloc
       $rc   = hwloc_bitmap_isincluded($mapa,$mapb)
       $rc   = hwloc_bitmap_isequal($mapa,$mapb)
       $rc   = hwloc_bitmap_compare($mapa,$mapb)
       $rc   = hwloc_bitmap_compare_first($mapa,$mapb)

       $map  = Sys::Hwloc::Bitmap->alloc
       $map  = Sys::Hwloc::Bitmap->new
       $map  = Sys::Hwloc::Bitmap->alloc_full
       $mapa = $map->dup
       $map->free
       $map->destroy
       $map->copy($mapa)
       $map->zero
       $map->fill
       $map->only($id)
       $map->allbut($id)
       $map->from_ulong($mask)
       $map->from_ith_ulong($i,$mask)
       $rc   = $map->sscanf($string)
       $rc   = $map->sscanf_list($string)                        not in hwloc
       $rc   = $map->sscanf_taskset($string)
       $map->set($id)
       $map->set_range($ida,$ide)
       $map->set_ith_ulong($i,$mask)
       $map->clr($id)
       $map->clr_range($ida,$ide)
       $map->singlify
       $val  = $map->to_ulong
       $val  = $map->to_ith_ulong($i)
       $val  = $map->sprintf
       $val  = $map->sprintf_list
       $val  = $map->sprintf_taskset
       @vals = $map->ids                                         not in hwloc
       $rc   = $map->isset($id)
       $rc   = $map->iszero
       $rc   = $map->isfull
       $val  = $map->first
       $val  = $map->next($prev)
       $val  = $map->last
       $val  = $map->weight
       $map->or($mapa)
       $map->and($mapa)
       $map->andnot($mapa)
       $map->xor($mapa)
       $map->not
       $rc   = $map->intersects($mapa)
       $rc   = $map->includes($mapa)                             not in hwloc
       $rc   = $map->isincluded($mapa)
       $rc   = $map->isequal($mapa)
       $rc   = $map->compare($mapa)
       $rc   = $map->compare_first($mapa)

=head2 Cpuset and Nodeset helpers

       $set  = hwloc_topology_get_complete_cpuset($t)
       $set  = hwloc_topology_get_topology_cpuset($t)
       $set  = hwloc_topology_get_online_cpuset($t)
       $set  = hwloc_topology_get_allowed_cpuset($t)
       $set  = hwloc_topology_get_complete_nodeset($t)
       $set  = hwloc_topology_get_topology_nodeset($t)
       $set  = hwloc_topology_get_allowed_nodeset($t)
       hwloc_cpuset_to_nodeset($t,$cpuset,$nodeset)
       hwloc_cpuset_to_nodeset_strict($t,$cpuset,$nodeset)
       hwloc_cpuset_from_nodeset($t,$cpuset,$nodeset)
       hwloc_cpuset_from_nodeset_strict($t,$cpuset,$nodeset)
       $rc   = hwloc_get_nbobjs_inside_cpuset_by_depth($t,$set,$depth)
       $rc   = hwloc_get_nbobjs_inside_cpuset_by_type($t,$set,$type)
       $obj  = hwloc_get_obj_inside_cpuset_by_depth($t,$set,$depth)
       $obj  = hwloc_get_obj_inside_cpuset_by_type($t,$set,$type)
       $obj  = hwloc_get_next_obj_inside_cpuset_by_depth($t,$set,$depth,$prev)
       $obj  = hwloc_get_next_obj_inside_cpuset_by_type($t,$set,$type,$prev)
       $obj  = hwloc_get_first_largest_obj_inside_cpuset($t,$set)
       @objs = hwloc_get_largest_objs_inside_cpuset($t,$set)

       $set  = $t->get_complete_cpuset
       $set  = $t->get_topology_cpuset
       $set  = $t->get_online_cpuset
       $set  = $t->get_allowed_cpuset
       $set  = $t->get_complete_nodeset
       $set  = $t->get_topology_nodeset
       $set  = $t->get_allowed_nodeset
       $t->cpuset_to_nodeset($cpuset,$nodeset)
       $t->cpuset_to_nodeset_strict($cpuset,$nodeset)
       $t->cpuset_from_nodeset($cpuset,$nodeset)
       $t->cpuset_from_nodeset_strict($cpuset,$nodeset)
       $rc   = $t->get_nbobjs_inside_cpuset_by_depth($set,$depth)
       $rc   = $t->get_nbobjs_inside_cpuset_by_type($set,$type)
       $obj  = $t->get_obj_inside_cpuset_by_depth($set,$depth)
       $obj  = $t->get_obj_inside_cpuset_by_type($set,$type)
       $obj  = $t->get_next_obj_inside_cpuset_by_depth($set,$depth,$prev)
       $obj  = $t->get_next_obj_inside_cpuset_by_type($set,$type,$prev)
       $obj  = $t->get_first_largest_obj_inside_cpuset($set)
       @objs = $t->get_largest_objs_inside_cpuset($set)

=head1 BINDING API

The hwloc C API provides constants and functions to bind processes or threads
to cpusets or nodesets.

The Sys::Hwloc module exports the corresponding constants and methods, when
requested with

       use Sys::Hwloc qw(:DEFAULT :binding);

It is required to import Cpuset or Bitmap API functions in addition, when
cpusets or nodesets have to be created or manipulated with the classic (not OO) interface.

=head2 CPU binding

       HWLOC_CPUBIND_PROCESS
       HWLOC_CPUBIND_THREAD
       HWLOC_CPUBIND_STRICT
       HWLOC_CPUBIND_NOMEMBIND                                   since  hwloc-1.1

       $rc   = hwloc_set_cpubind($t,$set,$flags)
       $rc   = hwloc_get_cpubind($t,$set,$flags)                 since  hwloc-1.0
       $rc   = hwloc_set_proc_cpubind($t,$pid,$set,$flags)
       $rc   = hwloc_get_proc_cpubind($t,$set,$pid,$flags)       since  hwloc-1.0

       $rc   = $t->set_cpubind($set,$flags)
       $rc   = $t->set_proc_cpubind($pid,$set,$flags)
       $rc   = $t->get_cpubind($set,$flags)                      since  hwloc-1.0
       $rc   = $t->get_proc_cpubind($pid,$set,$flags)            since  hwloc-1.0

=head2 Memory binding (since hwloc-1.1)

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

       $rc   = hwloc_set_membind($t,$set,$policy,$flags)
       $rc   = hwloc_set_membind_nodeset($t,$set,$policy,$flags)
       $rc   = hwloc_set_proc_membind($t,$pid,$set,$policy,$flags)
       $rc   = hwloc_set_proc_membind_nodeset($t,$pid,$set,$policy,$flags)
       $rc   = hwloc_get_membind($t,$set,\$policy,$flags)
       $rc   = hwloc_get_membind_nodeset($t,$set,\$policy,$flags)
       $rc   = hwloc_get_proc_membind($t,$pid,$set,\$policy,$flags)
       $rc   = hwloc_get_proc_membind_nodeset($t,$pid,$set,\$policy,$flags)

       $rc   = $t->set_membind($set,$policy,$flags)
       $rc   = $t->set_membind_nodeset($set,$policy,$flags)
       $rc   = $t->set_proc_membind($pid,$set,$policy,$flags)
       $rc   = $t->set_proc_membind_nodeset($pid,$set,$policy,$flags)
       $rc   = $t->get_membind($set,\$policy,$flags)
       $rc   = $t->get_membind_nodeset($set,\$policy,$flags)
       $rc   = $t->get_proc_membind($pid,$set,\$policy,$flags)
       $rc   = $t->get_proc_membind_nodeset($pid,$set,\$policy,$flags)

=head1 IMPLEMENTATION SPECIFICS

=head2 Hwloc Version

The Sys::Hwloc Perl module becomes bound at compile time to a
specific hwloc C library version. Depending on the version
of the hwloc C library, different methods are exported.

The compile-time hwloc API version number is available to
a Perl script via the constants B<HWLOC_API_VERSION> and
B<HWLOC_XSAPI_VERSION>. At the time of writing of this document,
the values are as follows:

   hwloc-version  HWLOC_API_VERSION  HWLOC_XSAPI_VERSION
   -------------  -----------------  -------------------
   hwloc-0.9.x    undef              0
   hwloc-1.0.x    0x00010000         0x00010000
   hwloc-1.1.x    0x00010100         0x00010100

To bind a Perl script to a specific hwloc API version, check
it in a BEGIN block:

  BEGIN {
    if(HWLOC_XSAPI_VERSION() < 0x00010100) {
      die "This script needs at least hwloc-1.1";
    }
  }

=head2 Object Oriented Interface

The hwloc C API defines data structures and provides functions
that take pointers to variables of type I<struct> as arguments. The hwloc
C API is not object-oriented.

The Sys::Hwloc Perl module blesses the basic hwloc C data structures into separate name spaces. Thus these become Perl objects.
The relation between hwloc C types and Perl classes is as follows:

  C type            Perl class
  ---------------   --------------------
  hwloc_topology_t  Sys::Hwloc::Topology
  hwloc_obj_t       Sys::Hwloc::Obj
  hwloc_cpuset_t    Sys::Hwloc::Cpuset
  hwloc_bitmap_t    Sys::Hwloc::Bitmap

The Sys::Hwloc module provides methods that have the same name
like their hwloc C API counterparts. This is the classic interface.
A Perl script that uses the classic interface looks almost
the same like the corresponding C source code.

In addition, the Sys::Hwloc module provides aliases to
most hwloc C API functions as methods in Sys::Hwloc classes.
In particular, all C functions that take a I<hwloc_topology_t>
pointer as first argument, are also accessible as methods of
the L<Sys::Hwloc::Topology> class. The same holds for the other
Sys::Hwloc classes.

Examples:

  classic                                 object-oriented
  ----------------------------------      ------------------
  hwloc_topology_load($topo)              $topo->load
  hwloc_topology_get_depth($topo)         $topo->depth
  hwloc_topology_get_root_obj($topo)      $topo->root
  hwloc_obj_type_sprintf($obj,$verbose)   $obj->sprintf_type($verbose)
  hwloc_obj_get_info_by_name($obj,$name)  $obj->info_by_name($name)
  hwloc_cpuset_free($cpuset)              $cpuset->free
  hwloc_cpuset_isequal($set1,$set2)       $set1->isequal($set2)
  hwloc_bitmap_zero($bitmap)              $bitmap->zero
  hwloc_bitmap_only($bitmap,$id)          $bitmap->only($id)

Note that there is no B<DESTROY> method in any Sys::Hwloc class,
that may destroy an object and its underlying C data automatically
when its reference count goes to zero. It is required to
call the free-ing hwloc API functions explicitely, when allocated
memory needs to be freed.

Example:

  $topo = Sys::Hwloc::Topology->init; # allocates memory.
  # $topo = undef;                    # WRONG, does not free!
  $topo->destroy;                     # OK, frees.
  # hwloc_topology_destroy($topo);    # also OK, same as above.

=head2 Cpusets, Nodesets, Bitmaps

In hwloc-0.9 and 1.0 a I<hwloc_obj> struct defines
the struct member I<cpuset> with C type I<hwloc_cpuset>. In hwloc-1.0 the
struct member I<nodeset> was added with C type I<hwloc_cpuset>.
Data of type I<hwloc_cpuset> become created and manipulated with
functions of the B<Cpuset API>.

When build with these hwloc versions, the Sys::Hwloc module exports
the functions of the Cpuset API on request, blesses these data into the
namespace L<Sys::Hwloc::Cpuset>, and provides OO-ish methods for them.
The namespace Sys::Hwloc::Bitmap does not exist.

In hwloc-1.1 a I<hwloc_obj> struct defines struct members with
C type I<hwloc_cpuset>, and struct members with C type I<hwloc_nodeset>.
Both C types are aliases of the C type I<hwloc_bitmap>. These
data become created and manipulated with functions of the B<Bitmap API>.

When built with these hwloc versions, the Sys::Hwloc module
exports the functions of the Bitmap API on request, blesses these data
into the namespace L<Sys::Hwloc::Bitmap>, and provides OO-ish
methods for them. A distrinction between the C types I<hwloc_cpuset>
and I<hwloc_nodeset> is not made. The namespace Sys::Hwloc::Cpuset
does not exist.

Example:

  use Sys::Hwloc qw(:DEFAULT :cpuset :bitmap);

  if(HWLOC_XSAPI_VERSION() <= 0x00010000) {
    $set = hwloc_cpuset_alloc();
    $set->cpu(0);
  } else {
    $set = hwloc_bitmap_alloc();
    $set->only(0);
  }
  $set->free;

=head2 Stringifying Functions

The hwloc C API contains functions that stringify topology objects,
cpusets or bitmaps into something human-readable.
These functions are named B<hwloc_*_snprintf*> or B<hwloc_*_asprintf*>,
and act like B<snprintf> or B<asprintf>, except that they
do not take a format argument.

These functions do not exist in Sys::Hwloc. They were replaced by simple
B<hwloc_*_sprintf*>, which return a new string like the Perl B<sprintf>
function does. In the case of error, I<undef> is returned.

Example:

  /* This is C */
  char s[128];
  int  rc;
  rc = hwloc_obj_type_snprintf(s, sizeof(s), obj, 1);
  printf("%s\n", s);

  # This is Perl
  printf "%s\n", hwloc_obj_type_sprintf($obj, 1); # classic interface
  printf "%s\n", $obj->sprintf_type(1);           # OO interface

=head2 Functions that return arrays

The hwloc C API contains functions, that take a pointer to
a pre-allocated array of topology objects as parameter. The functions
fill the array and return the number of objects in the result array.
On error, -1 is returned. These functions are

  hwloc_get_closest_objs
  hwloc_get_largest_objs_inside_cpuset

The corresponding Sys::Hwloc functions don't take an array pointer parameter,
and return an array of B<Sys::Hwloc::Obj> instances, instead. The result
array will contain zero to max. 1024 objects. On error, the result array
will be empty.

Example:

  /* This is C */
  hwloc_obj_t *objs;
  int          rc;
  objs = (hwloc_obj_t *)malloc(1024 * sizeof(hwloc_obj_t *));
  rc   = hwloc_get_largest_objs_inside_cpuset(topo, set, objs, 1024);
  printf("found %d objects\n", rc);
  free(objs);

  # This is Perl
  @objs = hwloc_get_largest_objs_inside_cpuset($topo, $set);
  printf "found %d objects\n", scalar @objs;

=head2 Functions not in the hwloc C API

The Sys::Hwloc module provides some functions, which are not
part of the hwloc C API. These functions are provided for convenience
with the hope that they are useful somehow. Maybe they occur in
future hwloc versions. These are:

  HWLOC_XSAPI_VERSION         always returns a version number (may be 0)
  HWLOC_HAS_XML               flag if hwloc was built with XML support
  hwloc_compare_objects       compares two Sys::Hwloc::Obj by C pointer value
  hwloc_bitmap_list_sscanf    parses  a list format cpuset ASCII string
  hwloc_bitmap_list_sprintf   outputs a list format cpuset ASCII string
  hwloc_bitmap_ids            returns bitmap bits as list of decimal numbers
  hwloc_bitmap_includes       reverse of hwloc_bitmap_isincluded

=head1 BUGS

Note that the Sys::Hwloc module is a wrapper,
which depends on the underlying hwloc C library.

If you feel that you found a hwloc bug, refer to
L<http://www.open-mpi.org/projects/hwloc/> how to report it.

If you feel that you found a wrapper bug, report it via L<https://rt.cpan.org/>.

=head1 SEE ALSO

L<hwloc>(7),
L<Sys::Hwloc::Topology>(3pm),
L<Sys::Hwloc::Obj>(3pm),
L<Sys::Hwloc::Cpuset>(3pm),
L<Sys::Hwloc::Bitmap>(3pm)

=head1 AUTHOR

Bernd Kallies, E<lt>kallies@zib.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 Zuse Institute Berlin

This package and its accompanying libraries is free software; you can
redistribute it and/or modify it under the terms of the GPL version 2.0,
or the Artistic License 2.0. Refer to LICENSE for the full license text.

=cut

__END__


