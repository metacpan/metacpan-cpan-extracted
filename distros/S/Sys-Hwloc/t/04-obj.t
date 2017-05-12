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
# Retrieve topology objects of this machine, check object properties
#
# $Id: 04-obj.t,v 1.14 2011/01/11 10:49:40 bzbkalli Exp $
#
################################################################################

use Test::More 0.94;
use strict;
use Sys::Hwloc 0.05;

my $apiVersion = HWLOC_XSAPI_VERSION();
my $proc_t     = $apiVersion ? HWLOC_OBJ_PU() : HWLOC_OBJ_PROC();
my ($t, $o, $rc, $nobjs, $nnodes, $depth, $test);

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
BAIL_OUT("Topology seems to contain no objects") unless $nobjs;

# --
# Number of HWLOC_OBJ_NODE objects, needed for some tests
# --

$nnodes = hwloc_get_nbobjs_by_type($t,HWLOC_OBJ_NODE);

plan tests => $nobjs * 30 + 1;

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
       ) {
  $obj_types{$_} = {};
}
if($apiVersion) {
  $obj_types{HWLOC_OBJ_GROUP()} = {};
}


# --
# Traverse through topology, check each object
# --

for(my $i = 0; $i < $depth; $i++) {
  my $n = hwloc_get_nbobjs_by_depth($t,$i);
  for(my $j = 0; $j < $n; $j++) {

    # Retrieve object at $i, $j by depth
    #   Should be a Sys::Hwloc::Obj

    $o = hwloc_get_obj_by_depth($t,$i,$j);
    isa_ok($o, 'Sys::Hwloc::Obj', sprintf("hwloc_get_obj_by_depth(%d,%d)", $i, $j)) or
      BAIL_OUT("hwloc_get_obj_by_depth() returns curious data");

    # $o->type
    #   Should be hwloc_get_depth_type()

    $test = sprintf("hwloc_get_depth_type(%d)", $i);
    $rc   = hwloc_get_depth_type($t,$i);
    cmp_ok($rc, '>=', 0, $test);

    $test = sprintf("hwloc_get_obj_by_depth(%d,%d)->type", $i, $j);
    my $type = $o->type;
    if(is($type, $rc, $test)) {
      $obj_types{$type}->{$i}++;
    }

    # $o->os_index
    #   Should be unsigned

    $test = sprintf("hwloc_get_obj_by_depth(%d,%d)->os_index", $i, $j);
    $rc = $o->type;
    cmp_ok($rc, '>=', 0, $test);

  SKIP: {

      skip 'Sys::Hwloc::Obj->memory', 2 unless $apiVersion;

      # $o->memory
      #   Should be HASH
      #   Should contain total_memory   (unsigned)
      #   Should contain local_memory   (unsigned)
      #   Should contain page_types_len (unsigned)
      #   Should contain page_types     (ARRAY with length page_types_len)
      # @{$o->memory->{page_types}}
      #   Should be HASH
      #   Should contain size  (unsigned)
      #   Should contain count (unsigned)

      $test = sprintf("hwloc_get_obj_by_depth(%d,%d)->memory", $i, $j);
      $rc = $o->memory;
      if(isa_ok($rc, 'HASH', $test)) {

	subtest "\%{$test}" => sub {

	  plan tests => 6;

	  foreach(qw(
		     total_memory
		     local_memory
		     page_types_len
		    )) {
	    cmp_ok($rc->{$_}, '>=', 0, $test."->{$_}");
	  }
	  if(isa_ok($rc->{page_types}, 'ARRAY', $test.'->{page_types}')) {
	    is((scalar @{$rc->{page_types}}), $rc->{page_types_len}, '@{Sys::Hwloc::Obj->memory->{page_types}} == Sys::Hwloc::Obj->memory->{page_types_len}');

	    if(@{$rc->{page_types}}) {
	      subtest 'Sys::Hwloc::Obj->memory->{page_types}' => sub {

		plan tests => (scalar @{$rc->{page_types}}) * 2;

		for(my $k = 0; $k <= $#{$rc->{page_types}}; $k++) {
		  $test         = sprintf("hwloc_get_obj_by_depth(%d,%d)->memory->{page_types}->[%d]", $i, $j, $k);
		  my $page_type = $rc->{page_types}->[$k];
		  if(isa_ok($page_type, 'HASH', $test)) {
		    subtest "\%{$test}" => sub {
		      plan tests => 2;
		      cmp_ok($page_type->{size},  '>=', 0, "$test"."->{size}");
		      cmp_ok($page_type->{count}, '>=', 0, "$test"."->{count}");
		    };
		  } else {
		    fail($test);
		  }
		}
	      };

	    } else {
	      pass('Sys::Hwloc::Obj->memory->{page_types}');
	    }

	  } else {
	    fail('@{Sys::Hwloc::Obj->memory->{page_types}}');
	  }

	};

      } else {
	fail('Sys::Hwloc::Obj->memory');
      }

    };

    # $o->attr
    #   Should be HASH
    #   Check contents depending on $o->type

    $test = sprintf("hwloc_get_obj_by_depth(%d,%d)->attr", $i, $j);
    $rc = $o->attr;
    if(isa_ok($rc, 'HASH', $test)) {

    SKIP: {

	skip '%{Sys::Hwloc::Obj->attr}', 1 unless defined $type;

      CASE: {
	  $type == HWLOC_OBJ_MACHINE && do {
	    subtest "\%{$test}" => sub {

	      if(! $apiVersion) {

		plan tests => 5;

		ok(exists $rc->{machine}->{dmi_board_vendor}, "$test"."->{machine}->{dmi_board_vendor}");
		ok(exists $rc->{machine}->{dmi_board_name},   "$test"."->{machine}->{dmi_board_name}");
		cmp_ok($rc->{machine}->{memory_kB},         '>=', 0, "$test"."->{machine}->{memory_kB}");
		cmp_ok($rc->{machine}->{huge_page_free},    '>=', 0, "$test"."->{machine}->{huge_page_free}");
		cmp_ok($rc->{machine}->{huge_page_size_kB}, '>=', 0, "$test"."->{machine}->{huge_page_size_kB}");

	      } elsif($apiVersion == 0x00010000) {

		plan tests => 2;

		ok(exists $rc->{machine}->{dmi_board_vendor}, "$test"."->{machine}->{dmi_board_vendor}");
		ok(exists $rc->{machine}->{dmi_board_name},   "$test"."->{machine}->{dmi_board_name}");

	      } else {

		plan tests => 1;

		is(scalar keys %{$rc}, 0, "scalar keys \%{$test}");

	      }

	    };
	    last CASE;
	  };

	  $type == HWLOC_OBJ_CACHE && do {
	    subtest "\%{$test}" => sub {

	      if(! $apiVersion) {

		plan tests => 2;

		cmp_ok($rc->{cache}->{memory_kB}, '>=', 0, "$test"."->{cache}->{memory_kB}");
		cmp_ok($rc->{cache}->{depth},     '>=', 0, "$test"."->{cache}->{depth}");

	      } elsif($apiVersion == 0x00010000) {

		plan tests => 2;

		cmp_ok($rc->{cache}->{size},      '>=', 0, "$test"."->{cache}->{size}");
		cmp_ok($rc->{cache}->{depth},     '>=', 0, "$test"."->{cache}->{depth}");

	      } else {

		plan tests => 3;

		cmp_ok($rc->{cache}->{size},      '>=', 0, "$test"."->{cache}->{size}");
		cmp_ok($rc->{cache}->{depth},     '>=', 0, "$test"."->{cache}->{depth}");
		cmp_ok($rc->{cache}->{linesize},  '>=', 0, "$test"."->{cache}->{linesize}");

	      }

	    };
	    last CASE;
	  };

	  $type == HWLOC_OBJ_MISC && do {
	    subtest "\%{$test}" => sub {

	      plan tests => 1;
	      if($apiVersion) {
		is(scalar keys %{$rc}, 0, "scalar keys \%{$test}");
	      } else {
		cmp_ok($rc->{misc}->{depth}, '>=', 0, "$test"."->{misc}->{depth}");
	      }

	    };
	    last CASE;
	  };

	  $type == HWLOC_OBJ_NODE && do {
	    subtest "\%{$test}" => sub {

	      plan tests => $apiVersion ? 1 : 2;
	      if($apiVersion) {
		is(scalar keys %{$rc}, 0, "scalar keys \%{$test}");
	      } else {
		cmp_ok($rc->{node}->{memory_kB},      '>=', 0, "$test"."->{node}->{memory_kB}");
		cmp_ok($rc->{node}->{huge_page_free}, '>=', 0, "$test"."->{node}->{huge_page_free}");
	      }

	    };
	    last CASE;
	  };

	  $apiVersion && $type == HWLOC_OBJ_GROUP() && do {
	    subtest "\%{$test}" => sub {
	      plan tests => 1;
	      cmp_ok($rc->{group}->{depth}, '>=', 0, "$test"."->{group}->{depth}");
	    };
	    last CASE;
	  };

	  is(scalar keys %{$rc}, 0, "scalar keys \%{$test}");

	}

      };

    } else {
      fail('Sys::Hwloc::Obj->attr');
    }

    # $o->depth
    #   Should be $depth

    $test = sprintf("hwloc_get_obj_by_depth(%d,%d)->depth", $i, $j);
    $rc = $o->depth;
    is($rc, $i, $test);

    # $o->logical_index
    #   Should be $logical_index

    $test = sprintf("hwloc_get_obj_by_depth(%d,%d)->logical_index", $i, $j);
    $rc = $o->logical_index;
    is($rc, $j, $test);

    # $o->os_level
    #   Should be defined

    $test = sprintf("hwloc_get_obj_by_depth(%d,%d)->os_level", $i, $j);
    $rc = $o->os_level;
    isnt($rc, undef, $test);

    # $o->parent
    #   Should be Sys::Hwloc::Obj, if $depth >  0
    #   Should be undef,      if $depth == 0
    #   parent->depth should be $depth - 1

    my $parent = undef;
    if($apiVersion) {
      $test = sprintf("hwloc_get_obj_by_depth(%d,%d)->parent", $i, $j);
      $parent = $o->parent;
    } else {
      $test = sprintf("hwloc_get_obj_by_depth(%d,%d)->father", $i, $j);
      $parent = $o->father;
    }
    if($i) {
      if(isa_ok($parent, 'Sys::Hwloc::Obj', $test)) {
	is($parent->depth, $i - 1, $test."->depth");
      } else {
	fail($test."->depth");
      }
    } else {
      if(is($parent, undef, $test)) {
	pass($test."->depth");
      } else {
	fail($test."->depth");
      }
    }

    # $o->prev_cousin
    #   Should be Sys::Hwloc::Obj if logical_index > 0

    $test = sprintf("hwloc_get_obj_by_depth(%d,%d)->prev_cousin", $i, $j);
    $rc = $o->prev_cousin;
    if($j) {
      if(isa_ok($rc, 'Sys::Hwloc::Obj', $test)) {
	subtest "\%{$test}" => sub {

	  plan tests => 2;

	  is($rc->depth,         $i,   $test."->depth");
	  is($rc->logical_index, $j-1, $test."->logical_index");

	};
      } else {
	fail("\%{$test}");
      }
    } else {
      if(is($rc, undef, $test)) {
	pass("\%{$test}");
      } else {
	fail("\%{$test}");
      }
    }

    # $o->next_cousin
    #   Should be Sys::Hwloc::Obj if logical_index < n

    $test = sprintf("hwloc_get_obj_by_depth(%d,%d)->next_cousin", $i, $j);
    $rc = $o->next_cousin;
    if($j < $n-1) {
      if(isa_ok($rc, 'Sys::Hwloc::Obj', $test)) {
	subtest "\%{$test}" => sub {

	  plan tests => 2;

	  is($rc->depth,         $i,   $test."->depth");
	  is($rc->logical_index, $j+1, $test."->logical_index");

	};
      } else {
	fail("\%{$test}");
      }
    } else {
      if(is($rc, undef, $test)) {
	pass("\%{$test}");
      } else {
	fail("\%{$test}");
      }
    }

    # $o->sibling_rank
    #   Should be unsigned, value will be checked when checking $o->children

    $test = sprintf("hwloc_get_obj_by_depth(%d,%d)->sibling_rank", $i, $j);
    $rc = $o->sibling_rank;
    cmp_ok($rc, '>=', 0, $test);

    # $o->arity
    #   Should be unsigned

    $test = sprintf("hwloc_get_obj_by_depth(%d,%d)->arity", $i, $j);
    my $arity = $o->arity;
    cmp_ok($arity, '>=', 0, $test) or
      $arity = undef;

    # $o->children
    #   Should return $o->arity Sys::Hwloc::Obj objects

    $test = sprintf("hwloc_get_obj_by_depth(%d,%d)->children", $i, $j);
    my @children = $o->children;
    is((scalar @children), $arity, $test);

    $test = sprintf("\@{hwloc_get_obj_by_depth(%d,%d)->children}", $i, $j);
    if(@children) {
      subtest $test => sub {

	plan tests => (scalar @children) * 2;

	for(my $k = 0; $k <= $#children; $k++) {
	  $test = sprintf("(hwloc_get_obj_by_depth(%d,%d)->children)[%d]", $i, $j, $k);
	  my $child = $children[$k];
	  if(isa_ok($child, 'Sys::Hwloc::Obj', $test)) {
	    subtest "\%{$test}" => sub {

	      plan tests => 8;

	      is($child->depth,        $i+1, $test."->depth");
	      is($child->sibling_rank, $k,   $test."->siblink_rank");

	      if($apiVersion) {
		if(isa_ok($child->parent, 'Sys::Hwloc::Obj', $test."->parent")) {
		  subtest "\%{$test"."->parent}" => sub {

		    plan tests => 2;

		    is($child->parent->depth,         $i, $test."->parent->depth");
		    is($child->parent->logical_index, $j, $test."->parent->logical_index");

		  };
		} else {
		  fail("\%{$test"."->parent}");
		}
	      } else {
		if(isa_ok($child->father, 'Sys::Hwloc::Obj', $test."->father")) {
		  subtest "\%{$test"."->father}" => sub {

		    plan tests => 2;

		    is($child->father->depth,         $i, $test."->father->depth");
		    is($child->father->logical_index, $j, $test."->father->logical_index");

		  };
		} else {
		  fail("\%{$test"."->father}");
		}
	      }

	      if($k) {
		if(isa_ok($child->prev_sibling, 'Sys::Hwloc::Obj', $test."->prev_sibling")) {
		  subtest "\%{$test"."->prev_sibling}" => sub {

		    plan tests => 2;

		    is($child->prev_sibling->depth,        $i+1, $test."->prev_sibling->depth");
		    is($child->prev_sibling->sibling_rank, $k-1, $test."->prev_sibling->sibling_rank");

		  };
		} else {
		  fail("\%{$test"."->prev_sibling}");
		}
	      } else {
		if(is($child->prev_sibling, undef, $test."->prev_sibling")) {
		  pass("\%{$test"."->prev_sibling}");
		} else {
		  fail("\%{$test"."->prev_sibling}");
		}
	      }

	      if($k < $#children) {
		if(isa_ok($child->next_sibling, 'Sys::Hwloc::Obj', $test."->next_sibling")) {
		  subtest "\%{$test"."->next_sibling}" => sub {

		    plan tests => 2;

		    is($child->next_sibling->depth,        $i+1, $test."->next_sibling->depth");
		    is($child->next_sibling->sibling_rank, $k+1, $test."->next_sibling->sibling_rank");

		  };
		} else {
		  fail("\%{$test"."->next_sibling}");
		}
	      } else {
		if(is($child->next_sibling, undef, $test."->prev_sibling")) {
		  pass("\%{$test"."->next_sibling}");
		} else {
		  fail("\%{$test"."->next_sibling}");
		}
	      }

	    };
	  } else {
	    fail("\%{$test}");
	  }
	}

      };
    } else {
      pass($test);
    }

    # $o->first_child
    #   Should return Sys::Hwloc::Obj if $o->arity

    $test = sprintf("hwloc_get_obj_by_depth(%d,%d)->first_child", $i, $j);
    $rc = $o->first_child;
    if($o->arity) {
      if(isa_ok($rc, 'Sys::Hwloc::Obj', $test)) {
	subtest "\%{$test}" => sub {

	  plan tests => 3;

	  is($rc->depth,        $i+1, $test."->depth");
	  is($rc->sibling_rank, 0,    $test."->sibling_rank");
	  if($apiVersion) {
	    isa_ok($rc->parent, 'Sys::Hwloc::Obj', $test."->parent");
	  } else {
	    isa_ok($rc->father, 'Sys::Hwloc::Obj', $test."->father");
	  }

	};
      } else {
	fail("\%{$test}");
      }
    } else {
      if(is($rc, undef, $test)) {
	pass("\%{$test}");
      } else {
	fail("\%{$test}");
      }
    }

    # $o->last_child
    #   Should return Sys::Hwloc::Obj if $o->arity

    $test = sprintf("hwloc_get_obj_by_depth(%d,%d)->last_child", $i, $j);
    $rc = $o->last_child;
    if($o->arity) {
      if(isa_ok($rc, 'Sys::Hwloc::Obj', $test)) {
	subtest "\%{$test}" => sub {

	  plan tests => 3;

	  is($rc->depth,        $i+1,       $test."->depth");
	  is($rc->sibling_rank, $arity - 1, $test."->sibling_rank");
	  if($apiVersion) {
	    isa_ok($rc->parent, 'Sys::Hwloc::Obj', $test."->parent");
	  } else {
	    isa_ok($rc->father, 'Sys::Hwloc::Obj', $test."->father");
	  }

	};
      } else {
	fail("\%{$test}");
      }
    } else {
      if(is($rc, undef, $test)) {
	pass("\%{$test}");
      } else {
	fail("\%{$test}");
      }
    }

    # $o->cpuset
    #   Should return Sys::Hwloc::Cpuset for hwloc < 1.1
    #   Should return Sys::Hwloc::Bitmap for hwloc >= 1.1

    $test = sprintf("hwloc_get_obj_by_depth(%d,%d)->cpuset", $i, $j);
    $rc = $o->cpuset;
    isa_ok($rc, ($apiVersion < 0x00010100) ? 'Sys::Hwloc::Cpuset' : 'Sys::Hwloc::Bitmap', $test);

  SKIP: {

      skip 'Sys::Hwloc::Obj->nodeset', 1 unless ($apiVersion >= 0x00010000);

      # $o->nodeset
      #   Should return undef if topology does not contain HWLOC_OBJ_NODE objects
      #   Otherwise:
      #     Should return Sys::Hwloc::Cpuset for hwloc < 1.1
      #     Should return Sys::Hwloc::Bitmap for hwloc >= 1.1

      $test = sprintf("hwloc_get_obj_by_depth(%d,%d)->nodeset", $i, $j);
      $rc = $o->nodeset;
      if($apiVersion < 0x00010100) {
	if($nnodes) {
	  isa_ok($rc, 'Sys::Hwloc::Cpuset', $test);
	} else {
	  is($rc, undef, $test);
	}
      } else {
	isa_ok($rc, 'Sys::Hwloc::Bitmap', $test);
      }

    };

  SKIP: {

      skip 'Sys::Hwloc::Obj->infos', 3 unless ($apiVersion >= 0x00010100);

      # $o->infos
      #   Should be HASH, not empty for HWLOC_OBJ_MACHINE

      $test = sprintf("hwloc_get_obj_by_depth(%d,%d)->infos", $i, $j);
      $rc = $o->infos;
      if(isa_ok($rc, 'HASH', $test)) {
	if($type == HWLOC_OBJ_MACHINE) {
	  cmp_ok(scalar keys %{$rc}, '>', 1, "\%{$test}");
	} else {
	  pass("\%{$test}");
	}
      } else {
	fail("\%{$test}");
      }

      # $o->info_by_name
      #   See if matches $o->infos

      $test = sprintf("hwloc_get_obj_by_depth(%d,%d)->info_by_name", $i, $j);
      if($rc && %{$rc}) {
	subtest $test => sub {
	  plan tests => scalar keys %{$rc};

	  while(my ($name, $value) = each %{$rc}) {
	    is($o->info_by_name($name), $value, $test."($name)");
	  }

	};
      } else {
	pass($test);
      }

    };

  }
}

# --
# Check if hwloc_get_type_depth and hwloc_get_nbobjs_by_type returns wanted numbers
# --

subtest 'hwloc_get_nbobjs_by_type()' => sub {

  plan tests => (scalar keys %obj_types) * 2;

  foreach my $type (sort { $a <=> $b } keys %obj_types) {
    if(%{$obj_types{$type}}) {
      if(scalar keys %{$obj_types{$type}} == 1) {
	my ($depth) = (keys %{$obj_types{$type}});
	is(hwloc_get_type_depth($t, $type),    $depth,                      "hwloc_get_type_depth($type)");
	is(hwloc_get_nbobjs_by_type($t,$type), $obj_types{$type}->{$depth}, "hwloc_get_nbobjs_by_type($type)");
      } else {
	is(hwloc_get_type_depth($t, $type),    HWLOC_TYPE_DEPTH_MULTIPLE,   "hwloc_get_type_depth($type)");
	is(hwloc_get_nbobjs_by_type($t,$type), -1,                          "hwloc_get_nbobjs_by_type($type)");
      }
    } else {
      is(hwloc_get_type_depth($t, $type),    HWLOC_TYPE_DEPTH_UNKNOWN,      "hwloc_get_type_depth($type)");
      is(hwloc_get_nbobjs_by_type($t,$type), 0,                             "hwloc_get_nbobjs_by_type($type)");
    }

  }

};

# --
# Destroy topology
# --

hwloc_topology_destroy($t);
