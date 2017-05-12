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
# Retrieve topology information
#
# $Id: 03-topoinfo.t,v 1.5 2011/01/11 10:49:40 bzbkalli Exp $
#
################################################################################

use Test::More;
use strict;
use Sys::Hwloc 0.04;

my $apiVersion = HWLOC_API_VERSION();
my $proc_t     = $apiVersion ? HWLOC_OBJ_PU() : HWLOC_OBJ_PROC();
my ($t, $rc, $ok, $depth, $nprocs);

plan tests => 16;

# --
# Init topology, stop testing if this fails
# --

$t = hwloc_topology_init();
isa_ok($t, 'Sys::Hwloc::Topology', 'hwloc_topology_init()') or
  BAIL_OUT("Failed to initialize topology context via hwloc_topology_init()");

# --
# Load topology, stop testing if this fails
# --

$rc = hwloc_topology_load($t);
is($rc, 0, 'hwloc_topology_load()') or
  BAIL_OUT("Failed to load topology context");

# --
# Topology info
# --

$depth = hwloc_topology_get_depth($t);
cmp_ok($depth, '>', 0, 'hwloc_topology_get_depth()') or
  $depth = undef;

$rc = hwloc_get_depth_type($t,0);
is($rc, $apiVersion ? HWLOC_OBJ_MACHINE : HWLOC_OBJ_SYSTEM, 'hwloc_get_depth_type(0)');

SKIP: {

  skip 'Topology has curious depth, cannot check PROC objects', 5 unless $depth;

  $rc = hwloc_get_depth_type($t,$depth-1);
  is($rc, $proc_t, sprintf("hwloc_get_depth_type(%d)", $depth-1));

  $rc = hwloc_get_depth_type($t,$depth);
  is($rc, -1, sprintf("hwloc_get_depth_type(%d)", $depth));

  $rc = hwloc_get_type_depth($t,$proc_t);
  is($rc, $depth-1, sprintf("hwloc_get_type_depth(%d)", $proc_t));

  $nprocs = hwloc_get_nbobjs_by_depth($t,$depth-1);
  cmp_ok($nprocs, '>', 0, sprintf("hwloc_topology_get_nbobjs_by_depth(%d)", $depth-1)) or
    $nprocs = undef;

 SKIP: {

    skip "Topology contains no PROC objects at highest depth, cannot check hwloc_get_nbobjs_by_type(PROC)", 1 unless $nprocs;

    $rc = hwloc_get_nbobjs_by_type($t,$proc_t);
    is($rc, $nprocs, sprintf("hwloc_get_nbobjs_by_type(%d)", $proc_t));

  };

};

# --
# Now try OO
# --

SKIP: {

  skip "Topology has curious depth, cannot check OO interface consistency", 7 unless $depth;

  $rc = $t->depth;
  is($rc, $depth, 't->depth');

  $rc = $t->depth_type(0);
  is($rc, $apiVersion ? HWLOC_OBJ_MACHINE : HWLOC_OBJ_SYSTEM, 't->depth_type(0)');

  $rc = $t->depth_type($depth-1);
  is($rc, $proc_t, sprintf("t->depth_type(%d)", $depth-1));

  $rc = $t->depth_type($depth);
  is($rc, -1, sprintf("t->depth_type(%d)", $depth));

  $rc = $t->type_depth($proc_t);
  is($rc, $depth-1, sprintf("t->type_depth(%d)", $proc_t));

 SKIP: {

    skip "Topology contains no PROC objects at highest depth, cannot check t->get_nbobjs", 2 unless $nprocs;

    $rc = $t->get_nbobjs_by_depth($depth-1);
    is($rc, $nprocs, sprintf("t->get_nbobjs_by_depth(%d)", $depth-1));

    $rc = $t->get_nbobjs_by_type($proc_t);
    is($rc, $nprocs, sprintf("t->get_nbobjs_by_type(%d)", $proc_t));

  };

};

# --
# Destroy topology
# --

hwloc_topology_destroy($t);
