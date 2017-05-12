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
# Test String <-> Object conversion
#
# $Id: 05-strings.t,v 1.8 2011/01/11 10:49:40 bzbkalli Exp $
#
################################################################################

use Test::More 0.94;
use strict;
use Sys::Hwloc 0.04;

my $apiVersion = HWLOC_API_VERSION();
my $proc_t     = $apiVersion ? HWLOC_OBJ_PU() : HWLOC_OBJ_PROC();
my ($t, $o, $rc, $nobjs, $depth, $test);

# --
# Init object types lookup table
# --

my %obj_types = ();
foreach(
	HWLOC_OBJ_CACHE(),
	HWLOC_OBJ_CORE(),
	HWLOC_OBJ_MACHINE(),
	HWLOC_OBJ_MISC(),
	HWLOC_OBJ_NODE(),
	HWLOC_OBJ_SOCKET(),
	HWLOC_OBJ_SYSTEM(),
	$proc_t,
	-1,
       ) {
  $obj_types{$_} = '';
}
if($apiVersion) {
  $obj_types{HWLOC_OBJ_GROUP()} = '';
}


plan tests => (scalar keys %obj_types) * 2 + 4;

# --
# Check hwloc_obj_type_string, hwloc_obj_type_of_string
# --

foreach my $type (sort { $a <=> $b } keys %obj_types) {
  $rc = hwloc_obj_type_string($type);
  if(like($rc, qr/\S/, "hwloc_obj_type_string($type)")) {
    $obj_types{$type} = $rc;
    is(hwloc_obj_type_of_string($rc), $type, "hwloc_obj_type_of_string($rc)");
  } else {
    fail("hwloc_obj_type_of_string($rc)");
  }
}

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
# Count number of objects, stop testing if there are none
# --

$nobjs = 0;
$depth = hwloc_topology_get_depth($t);
$depth = 0 unless defined $depth;
for(my $i = 0; $i < $depth; $i++) {
  my $n = hwloc_get_nbobjs_by_depth($t,$i);
  if(! defined $n) {
    printf STDERR "#fail: hwloc_get_nbobjs_by_depth(%d) returns (undef)\n", $i;
    next;
  }
  $nobjs += $n;
}

# --
# Check each object
# --

SKIP: {

  skip "Topology seems to contain no objects", 4 unless $nobjs;

  # --
  # Check hwloc_obj_type_sprintf
  # --

 SKIP: {

    skip "hwloc_obj_type_sprintf()", 1 unless $apiVersion;

    subtest "hwloc_obj_type_sprintf()" => sub {

      plan tests => $nobjs * 3;

      for(my $i = 0; $i < $depth; $i++) {
	my $n = hwloc_get_nbobjs_by_depth($t,$i);
	for(my $j = 0; $j < $n; $j++) {
	  $test = sprintf("hwloc_get_obj_by_depth(%d,%d)", $i, $j);
	  $o = hwloc_get_obj_by_depth($t,$i,$j);
	  if(isa_ok($o, 'Sys::Hwloc::Obj', $test)) {
	    $rc = hwloc_obj_type_sprintf($o,1);
	    like($rc, qr/$obj_types{$o->type}/, "hwloc_obj_type_sprintf($test)");
	    is($o->sprintf_type(1), $rc,           $test."->sprintf_type(1)");
	  } else {
	    fail("hwloc_obj_type_sprintf($test)");
	    fail($test."->sprintf_type(1)");
	  }
	}
      }

    };

  };

  # --
  # Check hwloc_obj_attr_sprintf
  # --

 SKIP: {

    skip "hwloc_obj_attr_sprintf()", 1 unless $apiVersion;

    subtest "hwloc_obj_attr_sprintf()" => sub {

      plan tests => $nobjs * 3;

      for(my $i = 0; $i < $depth; $i++) {
	my $n = hwloc_get_nbobjs_by_depth($t,$i);
	for(my $j = 0; $j < $n; $j++) {
	  $test = sprintf("hwloc_get_obj_by_depth(%d,%d)", $i, $j);
	  $o = hwloc_get_obj_by_depth($t,$i,$j);
	  if(isa_ok($o, 'Sys::Hwloc::Obj', $test)) {
	    $rc = hwloc_obj_attr_sprintf($o,1);
	  CASE: {
	      $o->type == HWLOC_OBJ_MACHINE() && do {
		like($rc, qr/\S/, "hwloc_obj_attr_sprintf($test)");
		last CASE;
	      };
	      $o->type == HWLOC_OBJ_CACHE() && do {
		like($rc, qr/\S/, "hwloc_obj_attr_sprintf($test)");
		last CASE;
	      };
	      $o->type == HWLOC_OBJ_NODE() && do {
		like($rc, qr/\S/, "hwloc_obj_attr_sprintf($test)");
		last CASE;
	      };
	      $o->type == HWLOC_OBJ_GROUP() && do {
		like($rc, qr/\S/, "hwloc_obj_attr_sprintf($test)");
		last CASE;
	      };
	      is($rc, '', "hwloc_obj_attr_sprintf($test)");
	    }
	    is($o->sprintf_attr(1), $rc, $test."->sprintf_attr(1)");
	  } else {
	    fail("hwloc_obj_attr_sprintf($test)");
	    fail($test."->sprintf_attr(1)");
	  }
	}
      }

    };

  };

  # --
  # Check hwloc_obj_sprintf
  # --

  subtest "hwloc_obj_sprintf()" => sub {

    plan tests => $nobjs * 4;

    for(my $i = 0; $i < $depth; $i++) {
      my $n = hwloc_get_nbobjs_by_depth($t,$i);
      for(my $j = 0; $j < $n; $j++) {
	$test = sprintf("hwloc_get_obj_by_depth(%d,%d)", $i, $j);
	$o = hwloc_get_obj_by_depth($t,$i,$j);
	if(isa_ok($o, 'Sys::Hwloc::Obj', $test)) {
	  $rc = hwloc_obj_sprintf($t,$o,undef,1);
	CASE: {
	    $o->type == $proc_t && do {
	      like($rc, qr/#/, "hwloc_obj_sprintf($test)");
	      last CASE;
	    };
	    $o->type == HWLOC_OBJ_CORE() && do {
	      like($rc, qr/#/, "hwloc_obj_sprintf($test)");
	      last CASE;
	    };
	    $o->type == HWLOC_OBJ_SOCKET() && do {
	      like($rc, qr/#/, "hwloc_obj_sprintf($test)");
	      last CASE;
	    };
	    $o->type == HWLOC_OBJ_NODE() && do {
	      like($rc, qr/#/, "hwloc_obj_sprintf($test)");
	      last CASE;
	    };
	    like($rc, qr/\S/, "hwloc_obj_sprintf($test)");
	  }
	  is($t->sprintf_obj($o,undef,1), $rc, "t->sprintf_obj($test)");
	  is($o->sprintf(undef,1),        $rc, $test."->sprintf()");
	} else {
	  fail("hwloc_obj_sprintf($test)");
	  fail("t->sprintf_obj($test)");
	  fail($test."->sprintf()");
	}
      }
    }

  };

  # --
  # Check hwloc_obj_cpuset_sprintf
  # --

  subtest "hwloc_obj_cpuset_sprintf()" => sub {

    plan tests => $nobjs * 3 + 1;

    my @objs        = ();
    my $root_cpuset = undef;

    for(my $i = 0; $i < $depth; $i++) {
      my $n = hwloc_get_nbobjs_by_depth($t,$i);
      for(my $j = 0; $j < $n; $j++) {
	$test = sprintf("hwloc_get_obj_by_depth(%d,%d)", $i, $j);
	$o = hwloc_get_obj_by_depth($t,$i,$j);
	if(isa_ok($o, 'Sys::Hwloc::Obj', $test)) {
	  $rc = hwloc_obj_cpuset_sprintf($o);
	  like($rc, qr/\S/, "hwloc_obj_cpuset_sprintf($test)");
	  is($o->sprintf_cpuset, $rc, $test."->sprintf_cpuset");
	  push @objs, $o;
	  $root_cpuset = $rc if($i == 0 && $j == 0);
	} else {
	  fail("hwloc_obj_cpuset_sprintf($test)");
	  fail($test."->sprintf_cpuset");
	}
      }
    }

    $test = "hwloc_obj_cpuset_sprintf(<all-objs>) eq hwloc_obj_cpuset_sprintf(<root>)";
    if($root_cpuset) {
      is(hwloc_obj_cpuset_sprintf(@objs), $root_cpuset, $test);
    } else {
      fail($test);
    }

  };

};

# --
# Destroy topology
# --

hwloc_topology_destroy($t);
