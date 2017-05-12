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
# Do some high-level tests with cpusets of topology objects
#
# $Id: 09-sets.t,v 1.6 2011/01/11 10:49:40 bzbkalli Exp $
#
################################################################################

use Test::More 0.94;
use strict;
use Sys::Hwloc 0.08 qw(:DEFAULT :cpuset :bitmap);

plan tests => 14;

my $apiVersion = HWLOC_XSAPI_VERSION();
my $proc_t     = $apiVersion ? HWLOC_OBJ_PU() : HWLOC_OBJ_PROC();
my $cpuset_c   = $apiVersion <= 0x00010000 ? 'Sys::Hwloc::Cpuset' : 'Sys::Hwloc::Bitmap';
my ($t, $o, $rc, $root, $rootset, $test, $nobjs);

SKIP: {

  skip "Topology cpusets and nodesets", 6 unless $apiVersion;

  # --
  # Init topology, stop testing if this fails
  # --

  $t = hwloc_topology_init();
  BAIL_OUT("Failed to initialize topology context via hwloc_topology_init()") unless $t;

  # --
  # Load topology, stop testing if this fails
  # --

  $rc = hwloc_topology_load($t);
  BAIL_OUT("Failed to load topology context") if $rc;

  # --
  # Load root object, stop testing if this fails
  # --

  $root = $t->root;
  BAIL_OUT("Failed to load root object") unless $root;

  $rootset = $root->cpuset;
  isa_ok($rootset, $cpuset_c, 'root->cpuset') or
    BAIL_OUT("Cannot base checks on root->cpuset");

  # Check hwloc_topology_get_allowed_cpuset
  $test = "hwloc_topology_get_allowed_cpuset";
  subtest $test => sub {

    plan tests => 4;

    $rc = hwloc_topology_get_allowed_cpuset($t);
    isa_ok($rc, $cpuset_c, $test);
    is($rootset->isequal($rc),1, "$test eq root->cpuset");

    $rc = $t->get_allowed_cpuset;
    isa_ok($rc, $cpuset_c, "t->get_allowed_cpuset");
    is($rootset->isequal($rc),1, "t->get_allowed_cpuset eq root->cpuset");

  };

  # Walk through PU, see if their cpusets contain their os_index,
  # are contained in root, and do not overlap

  $nobjs = $t->get_nbobjs_by_type($proc_t);

 SKIP: {

    skip "System contains no PU", 1 unless $nobjs;

    subtest "puobj->cpusets" => sub {

      plan tests => $nobjs * 5 + 1;

      my @objs = ();
      $o = undef;
      while($o = $t->get_next_obj_by_type($proc_t, $o)) {
	$test = sprintf("pu[%d]->cpuset", $o->os_index);
	$rc = $o->cpuset;
	push @objs, $o if isa_ok($rc, $cpuset_c, $test);
	my @ids = $rc->ids;
	is(scalar @ids, 1, "$test has exactly one bit set");
	ok($rc->isset($o->os_index), "$test has os_index set");
	ok($rootset->includes($rc), "rootset includes $test");

	if($o->prev_sibling) {
	  is($o->cpuset->intersects($o->prev_sibling->cpuset), 0, "$test does not intersect with prev_sibling");
	} else {
	  pass("$test intersects with prev_sibling");
	}
      }

      # generate string containing all PU sets,
      # should be equal to stringified root cpuset
      is(hwloc_obj_cpuset_sprintf(@objs), $rootset->sprintf, "joined PU sets stringify to rootset");

    }

  };

 SKIP: {

    skip "Topology nodesets", 3 unless $apiVersion >= 0x00010100;

    $rootset = $root->allowed_nodeset;
    isa_ok($rootset, $cpuset_c, 'root->nodeset') or
      BAIL_OUT("Cannot base checks on root->nodeset");

    # Check hwloc_topology_get_allowed_nodeset
    $test = "hwloc_topology_get_allowed_nodeset";
    subtest $test => sub {

      plan tests => 4;

      $rc = hwloc_topology_get_allowed_nodeset($t);
      isa_ok($rc, $cpuset_c, $test);
      is($rootset->isequal($rc),1, "$test eq root->nodeset");

      $rc = $t->get_allowed_nodeset;
      isa_ok($rc, $cpuset_c, "t->get_allowed_nodeset");
      is($rootset->isequal($rc),1, "t->get_allowed_nodeset eq root->nodeset");

    };

    # Walk through PU, see if their cpusets contain their os_index,
    # are contained in root, and do not overlap

    $nobjs = $t->get_nbobjs_by_type(HWLOC_OBJ_NODE);

    if($nobjs) {

      subtest "nodeobj->nodesets" => sub {

	plan tests => $nobjs * 5 + 1;

	my $set = Sys::Hwloc::Bitmap->new;

	$o = undef;
	while($o = $t->get_next_obj_by_type(HWLOC_OBJ_NODE, $o)) {
	  $test = sprintf("node[%d]->nodeset", $o->os_index);
	  $rc = $o->nodeset;
	  $set->or($rc) if isa_ok($rc, $cpuset_c, $test);
	  my @ids = $rc->ids;
	  is(scalar @ids, 1, "$test has exactly one bit set");
	  ok($rc->isset($o->os_index), "$test has os_index set");
	  ok($rootset->includes($rc), "rootset includes $test");

	  if($o->prev_sibling) {
	    is($o->nodeset->intersects($o->prev_sibling->nodeset), 0, "$test does not intersect with prev_sibling");
	  } else {
	    pass("$test intersects with prev_sibling");
	  }
	}

	# generate string containing all NODE sets,
	# should be equal to stringified root nodeset
	is($set->sprintf, $rootset->sprintf, "ORed NODE sets stringify to rootset");

	$set->free;

      };

    } else {

      ok($rootset->isfull, "root->nodeset should be infinite");

    }

  };

  hwloc_topology_destroy($t);

};

# ===================================
# Following tests use a fake topology
# ===================================

$t = hwloc_topology_init();
BAIL_OUT("Failed to initialize topology context via hwloc_topology_init()") unless $t;

# --
# Topology contains: 1 NUMANode with 1 Socket, 2 L2 per socket, 2 cores per L2, 2 PU per core
# --

$rc = hwloc_topology_set_synthetic($t, "1 1 2 2 2");
BAIL_OUT("Failed to fake topology context") if $rc;
$rc = hwloc_topology_load($t);
BAIL_OUT("Failed to load topology context") if $rc;
if($apiVersion) {
  $root = $t->root;
} else {
  $root = $t->system;
}
BAIL_OUT("Failed to load root object") unless $root;
$rootset = $root->cpuset;
BAIL_OUT("Failed to get root->cpuset") unless $rootset;

# --
# Traverse by depth, check hwloc_get_nbobjs_inside_cpuset_by_depth for rootset
# --

$test = "hwloc_get_nbobjs_inside_cpuset_by_depth";
subtest $test => sub {

  plan tests => ($t->depth + 1) * 2;

  for(my $i = 0; $i <= $t->depth; $i++) {

    $rc = hwloc_get_nbobjs_inside_cpuset_by_depth($t,$rootset,$i);
    is($rc, hwloc_get_nbobjs_by_depth($t,$i), "hwloc_get_nbobjs_inside_cpuset_by_depth(rootset,$i) == hwloc_get_nbobjs_by_depth($i)");
    $rc = $t->get_nbobjs_inside_cpuset_by_depth($rootset,$i);
    is($rc, $t->get_nbobjs_by_depth($i), "t->get_nbobjs_inside_cpuset_by_depth(rootset,$i) == t->get_nbobjs_by_depth($i)");

  }

};

# --
# Traverse by type, check hwloc_get_nbobjs_inside_cpuset_by_type for rootset
# --

$test = "hwloc_get_nbobjs_inside_cpuset_by_type";
subtest $test => sub {

  my @types = (
	       HWLOC_OBJ_CACHE(),
	       HWLOC_OBJ_CORE(),
	       HWLOC_OBJ_MACHINE(),
	       HWLOC_OBJ_MISC(),
	       HWLOC_OBJ_NODE(),
	       HWLOC_OBJ_SOCKET(),
	       HWLOC_OBJ_SYSTEM(),
	       $proc_t,
	      );

  plan tests => 2 * scalar @types;

  foreach(@types) {

    $rc = hwloc_get_nbobjs_inside_cpuset_by_type($t,$rootset,$_);
    is($rc, hwloc_get_nbobjs_by_type($t,$_), "hwloc_get_nbobjs_inside_cpuset_by_type(rootset,$_) == hwloc_get_nbobjs_by_type($_)");
    $rc = $t->get_nbobjs_inside_cpuset_by_type($rootset,$_);
    is($rc, $t->get_nbobjs_by_type($_), "t->get_nbobjs_inside_cpuset_by_type(rootset,$_) == t->get_nbobjs_by_type($_)");

  }

};

# --
# Check hwloc_get_obj_inside_cpuset_by_depth
# --

$test = "hwloc_get_obj_inside_cpuset_by_depth";
subtest $test => sub {

  plan tests => $t->depth + 2;

  for (my $depth = 0; $depth < $t->depth; $depth++) {

    subtest "$test($depth)" => sub {

      $nobjs = $t->get_nbobjs_by_depth($depth);

      plan tests => $nobjs * 6;

      for (my $i = 0; $i < $nobjs; $i++) {

	$o = hwloc_get_obj_inside_cpuset_by_depth($t,$rootset,$depth,$i);
	isa_ok($o, 'Sys::Hwloc::Obj', "hwloc_get_obj_inside_cpuset_by_depth(rootset,$depth,$i)");
	is($o->depth, $depth,     "obj->depth == $depth");
	is($o->logical_index, $i, "obj->logical_index == $i");

	$o = $t->get_obj_inside_cpuset_by_depth($rootset,$depth,$i);
	isa_ok($o, 'Sys::Hwloc::Obj', "t->get_obj_inside_cpuset_by_depth(rootset,$depth,$i)");
	is($o->depth, $depth,     "obj->depth == $depth");
	is($o->logical_index, $i, "obj->logical_index == $i");

      }

    };

  }

  $o = hwloc_get_obj_inside_cpuset_by_depth($t,$rootset,hwloc_topology_get_depth($t) + 1,0);
  is($o, undef, "hwloc_get_obj_inside_cpuset_by_depth(rootset,<unk>)");
  $o = $t->get_obj_inside_cpuset_by_depth($rootset,$t->depth + 1,0);
  is($o, undef, "t->get_obj_inside_cpuset_by_depth(rootset,<unk>)");

};

# --
# Check hwloc_get_obj_inside_cpuset_by_type
# --

$test = "hwloc_get_obj_inside_cpuset_by_type";
subtest $test => sub {

  my @types = (
	       HWLOC_OBJ_CACHE(),
	       HWLOC_OBJ_CORE(),
	       HWLOC_OBJ_MACHINE(),
	       HWLOC_OBJ_MISC(),
	       HWLOC_OBJ_NODE(),
	       HWLOC_OBJ_SOCKET(),
	       HWLOC_OBJ_SYSTEM(),
	       $proc_t,
	      );

  plan tests => scalar @types;

  foreach my $type (@types) {

    $nobjs = $t->get_nbobjs_by_type($type);

    if ($nobjs) {

      subtest "$test($type)" => sub {

	plan tests => 6 * $nobjs;

	for (my $i = 0; $i < $nobjs; $i++) {

	  $o = hwloc_get_obj_inside_cpuset_by_type($t,$rootset,$type,$i);
	  isa_ok($o, 'Sys::Hwloc::Obj', "hwloc_get_obj_inside_cpuset_by_type(rootset,$type,$i)");
	  is($o->type, $type,       "obj->type == $type");
	  is($o->logical_index, $i, "obj->logical_index == $i");

	  $o = $t->get_obj_inside_cpuset_by_type($rootset,$type,$i);
	  isa_ok($o, 'Sys::Hwloc::Obj', "t->get_obj_inside_cpuset_by_type(rootset,$type,$i)");
	  is($o->type, $type,       "obj->type == $type");
	  is($o->logical_index, $i, "obj->logical_index == $i");

	}

      };
    } else {

      subtest "$test($type)" => sub {

	plan tests => 2;

	$o = hwloc_get_obj_inside_cpuset_by_type($t,$rootset,$type,0);
	is($o, undef, "hwloc_get_obj_inside_cpuset_by_type(rootset,$type)");
	$o = $t->get_obj_inside_cpuset_by_type($rootset,$type,0);
	is($o, undef, "t->get_obj_inside_cpuset_by_type(rootset,$type)");

      };

    }

  }

};

# --
# Check hwloc_get_next_obj_inside_cpuset_by_depth
# --

$test = "hwloc_get_next_obj_inside_cpuset_by_depth";
subtest $test => sub {

  my $depth = $t->depth - 3;
  $nobjs = $t->get_nbobjs_by_depth($depth);

  plan tests => $nobjs * 4;

  for ($o = hwloc_get_next_obj_inside_cpuset_by_depth($t,$rootset,$depth,undef);
       $o;
       $o = hwloc_get_next_obj_inside_cpuset_by_depth($t,$rootset,$depth,$o)) {
    isa_ok($o, 'Sys::Hwloc::Obj', "hwloc_get_next_obj_inside_cpuset_by_depth(rootset,$depth)");
    is($o->depth, $depth, "obj->depth == $depth");
  }

  for ($o = $t->get_next_obj_inside_cpuset_by_depth($rootset,$depth,undef);
       $o;
       $o = $t->get_next_obj_inside_cpuset_by_depth($rootset,$depth,$o)) {
    isa_ok($o, 'Sys::Hwloc::Obj', "t->get_next_obj_inside_cpuset_by_depth(rootset,$depth)");
    is($o->depth, $depth, "obj->depth == $depth");
  }

};

# --
# Check hwloc_get_next_obj_inside_cpuset_by_type
# --

$test = "hwloc_get_next_obj_inside_cpuset_by_type";
subtest $test => sub {

  my $type = HWLOC_OBJ_CORE();
  $nobjs = $t->get_nbobjs_by_type($type);

  plan tests => $nobjs * 4;

  for ($o = hwloc_get_next_obj_inside_cpuset_by_type($t,$rootset,$type,undef);
       $o;
       $o = hwloc_get_next_obj_inside_cpuset_by_type($t,$rootset,$type,$o)) {
    isa_ok($o, 'Sys::Hwloc::Obj', "hwloc_get_next_obj_inside_cpuset_by_type(rootset,$type)");
    is($o->type, $type, "obj->type == $type");
  }

  for ($o = $t->get_next_obj_inside_cpuset_by_type($rootset,$type,undef);
       $o;
       $o = $t->get_next_obj_inside_cpuset_by_type($rootset,$type,$o)) {
    isa_ok($o, 'Sys::Hwloc::Obj', "t->get_next_obj_inside_cpuset_by_type(rootset,$type)");
    is($o->type, $type, "obj->type == $type");
  }

};

# --
# Construct a cpuset containing the first PU of each core,
# check hwloc_get_largest_objs_inside_cpuset
# --

$o = hwloc_get_obj_by_type($t, $proc_t, 0);
my $set = $o->cpuset->dup;
while ($o = hwloc_get_next_obj_by_type($t, $proc_t, $o)) {
  next if $o->sibling_rank;
  $set->or($o->cpuset);
}

$test = "hwloc_get_largest_objs_inside_cpuset";
if (is($set->weight, 4, "cpuset containing 1st PU of each core")) {

  subtest $test => sub {

    plan tests => 5;

    my @objs = hwloc_get_largest_objs_inside_cpuset($t, $set);
    if (is(scalar @objs, 4, "$test(<testset>) returns 4 values")) {

      subtest "check each $test" => sub {

	plan tests => 3 * scalar @objs;

	for (my $i = 0; $i <= $#objs; $i++) {
	  $o = $objs[$i];
	  isa_ok($o, 'Sys::Hwloc::Obj', "$test(<testset>,$i)");
	  is($o->type,         $proc_t, "$test(<testset>,$i)->type");
	  is($o->sibling_rank, 0,       "$test(<testset>,$i)->sibling_rank");
	}

      };

    } else {
      fail("check each $test");
    }

  SKIP: {

      skip "hwloc_get_first_largest_obj_inside_cpuset", 3 unless $apiVersion;

      $o = hwloc_get_first_largest_obj_inside_cpuset($t, $set);
      isa_ok($o, 'Sys::Hwloc::Obj', "hwloc_get_first_largest_obj_inside_cpuset(<testset>)");
      is($o->type,         $proc_t, "hwloc_get_first_largest_obj_inside_cpuset(<testset>)->type");
      is($o->sibling_rank, 0,       "hwloc_get_first_largest_obj_inside_cpuset(<testset>)->sibling_rank");

    };

  };

} else {
  fail($test);
}

hwloc_topology_destroy($t);

