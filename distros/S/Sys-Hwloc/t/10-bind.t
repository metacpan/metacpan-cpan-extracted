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
# Check binding functions
#
# $Id: 10-bind.t,v 1.7 2011/01/11 10:49:40 bzbkalli Exp $
#
################################################################################

use Test::More 0.94;
use strict;
use Sys::Hwloc 0.07 qw(:DEFAULT :binding :cpuset :bitmap);

plan tests => 12;

my $apiVersion = HWLOC_XSAPI_VERSION();
my $proc_t     = $apiVersion ? HWLOC_OBJ_PU() : HWLOC_OBJ_PROC();
my $cpuset_c   = $apiVersion <= 0x00010000 ? 'Sys::Hwloc::Cpuset' : 'Sys::Hwloc::Bitmap';
my ($t, $o, $rc, $root, $set, $testset, $support, $policy, $test);

# --
# Init and load topology, load root, stop testing if this fails
# --

$t = hwloc_topology_init();
BAIL_OUT("Failed to initialize topology context via hwloc_topology_init()") unless $t;
$rc = hwloc_topology_load($t);
BAIL_OUT("Failed to load topology context") if $rc;
$root = $apiVersion ? $t->root : $t->system;
BAIL_OUT("Failed to load root object") unless $root;
if($apiVersion) {
  $support = hwloc_topology_get_support($t);
  BAIL_OUT("Failed to load topology support") unless ($support && ref($support) eq 'HASH');
}

# --
# Bind to CPUs of root cpuset
# --

$test = "Bind to CPUs of root cpuset";
$set  = $root->cpuset;
if(isa_ok($set, $cpuset_c)) {

  $testset = $set->dup;
  BAIL_OUT("Failed to duplicate root cpuset") unless $testset;

  if($apiVersion) {

    subtest $test => sub {

      plan tests => 8;

      $test = "bind this process to cpuset";
      $rc = hwloc_set_cpubind($t, $set, 0);
      if($support->{cpubind}->{set_thisproc_cpubind} || $support->{cpubind}->{set_thisthread_cpubind}) {
	is($rc, 0, $test);
      } else {
	isnt($rc, 0, $test);
      }

      $test = "get this process's binding to cpuset";
      $rc = hwloc_get_cpubind($t, $testset, 0);
      if($support->{cpubind}->{get_thisproc_cpubind} || $support->{cpubind}->{get_thisthread_cpubind}) {
	subtest $test => sub {
	  plan tests => 2;
	  is($rc, 0, $test);
	  ok($set->isequal($testset), $test) or
	    diag(sprintf("expected cpuset %s, got cpuset %s", $set->sprintf, $testset->sprintf));
	};
      } else {
	isnt($rc, 0, $test);
      }

      $test = "bind this thread to cpuset";
      $rc = hwloc_set_cpubind($t, $set, HWLOC_CPUBIND_THREAD);
      if($support->{cpubind}->{set_thisthread_cpubind}) {
	is($rc, 0, $test);
      } else {
	isnt($rc, 0, $test);
      }

      $test = "get this thread's binding to cpuset";
      $rc = hwloc_get_cpubind($t, $testset, HWLOC_CPUBIND_THREAD);
      if($support->{cpubind}->{get_thisthread_cpubind}) {
	subtest $test => sub {
	  plan tests => 2;
	  is($rc, 0, $test);
	  ok($set->isequal($testset), $test) or
	    diag(sprintf("expected cpuset %s, got cpuset %s", $set->sprintf, $testset->sprintf));
	};
      } else {
	isnt($rc, 0, $test);
      }

      $test = "bind this whole process to cpuset";
      $rc = hwloc_set_cpubind($t, $set, HWLOC_CPUBIND_PROCESS);
      if($support->{cpubind}->{set_thisproc_cpubind}) {
	is($rc, 0, $test);
      } else {
	isnt($rc, 0, $test);
      }

      $test = "get this whole process's binding to cpuset";
      $rc = hwloc_get_cpubind($t, $testset, HWLOC_CPUBIND_PROCESS);
      if($support->{cpubind}->{get_thisproc_cpubind}) {
	subtest $test => sub {
	  plan tests => 2;
	  is($rc, 0, $test);
	  ok($set->isequal($testset), $test) or
	    diag(sprintf("expected cpuset %s, got cpuset %s", $set->sprintf, $testset->sprintf));
	};
      } else {
	isnt($rc, 0, $test);
      }

      $test = "bind whole process to cpuset";
      $rc = hwloc_set_proc_cpubind($t, $$, $set, 0);
      if($support->{cpubind}->{set_proc_cpubind}) {
	is($rc, 0, $test);
      } else {
	isnt($rc, 0, $test);
      }

      $test = "get whole process's binding to cpuset";
      $rc = hwloc_get_proc_cpubind($t, $$, $testset, 0);
      if($support->{cpubind}->{get_proc_cpubind}) {
	subtest $test => sub {
	  plan tests => 2;
	  is($rc, 0, $test);
	  ok($set->isequal($testset), $test) or
	    diag(sprintf("expected cpuset %s, got cpuset %s", $set->sprintf, $testset->sprintf));
	};
      } else {
	isnt($rc, 0, $test);
      }

    };

  } else {

    subtest $test => sub {

      plan tests => 4;

      $test = "bind this process to cpuset";
      $rc = hwloc_set_cpubind($t, $set, 0);
      is($rc, 0, $test);

      $test = "bind this thread to cpuset";
      $rc = hwloc_set_cpubind($t, $set, HWLOC_CPUBIND_THREAD);
      is($rc, 0, $test);

      $test = "bind this whole process to cpuset";
      $rc = hwloc_set_cpubind($t, $set, HWLOC_CPUBIND_PROCESS);
      is($rc, 0, $test);

      $test = "bind whole process to cpuset";
      $rc = hwloc_set_proc_cpubind($t, $$, $set, 0);
      is($rc, 0, $test);

    };

  }

  $testset->free if $testset;

} else {

  fail($test);

}

# --
# Bind to CPUs of root cpuset (STRICT)
# --

$test = "Bind to CPUs of root cpuset (STRICT)";
$set  = $root->cpuset;
if(isa_ok($set, $cpuset_c)) {

  $testset = $set->dup;
  BAIL_OUT("Failed to duplicate root cpuset") unless $testset;

  if($apiVersion) {

    subtest $test => sub {

      plan tests => 8;

      $test = "bind this process to cpuset (STRICT)";
      $rc = hwloc_set_cpubind($t, $set, HWLOC_CPUBIND_STRICT);
      if($support->{cpubind}->{set_thisproc_cpubind} || $support->{cpubind}->{set_thisthread_cpubind}) {
	is($rc, 0, $test);
      } else {
	isnt($rc, 0, $test);
      }

      $test = "get this process's binding to cpuset (STRICT)";
      $rc = hwloc_get_cpubind($t, $testset, HWLOC_CPUBIND_STRICT);
      if($support->{cpubind}->{get_thisproc_cpubind} || $support->{cpubind}->{get_thisthread_cpubind}) {
	subtest $test => sub {
	  plan tests => 2;
	  is($rc, 0, $test);
	  ok($set->isequal($testset), $test) or
	    diag(sprintf("expected cpuset %s, got cpuset %s", $set->sprintf, $testset->sprintf));
	};
      } else {
	isnt($rc, 0, $test);
      }

      $test = "bind this thread to cpuset (STRICT)";
      $rc = hwloc_set_cpubind($t, $set, HWLOC_CPUBIND_STRICT | HWLOC_CPUBIND_THREAD);
      if($support->{cpubind}->{set_thisthread_cpubind}) {
	is($rc, 0, $test);
      } else {
	isnt($rc, 0, $test);
      }

      $test = "get this thread's binding to cpuset (STRICT)";
      $rc = hwloc_get_cpubind($t, $testset, HWLOC_CPUBIND_STRICT | HWLOC_CPUBIND_THREAD);
      if($support->{cpubind}->{get_thisthread_cpubind}) {
	subtest $test => sub {
	  plan tests => 2;
	  is($rc, 0, $test);
	  ok($set->isequal($testset), $test) or
	    diag(sprintf("expected cpuset %s, got cpuset %s", $set->sprintf, $testset->sprintf));
	};
      } else {
	isnt($rc, 0, $test);
      }

      $test = "bind this whole process to cpuset (STRICT)";
      $rc = hwloc_set_cpubind($t, $set, HWLOC_CPUBIND_STRICT | HWLOC_CPUBIND_PROCESS);
      if($support->{cpubind}->{set_thisproc_cpubind}) {
	is($rc, 0, $test);
      } else {
	isnt($rc, 0, $test);
      }

      $test = "get this whole process's binding to cpuset (STRICT)";
      $rc = hwloc_get_cpubind($t, $testset, HWLOC_CPUBIND_STRICT | HWLOC_CPUBIND_PROCESS);
      if($support->{cpubind}->{get_thisproc_cpubind}) {
	subtest $test => sub {
	  plan tests => 2;
	  is($rc, 0, $test);
	  ok($set->isequal($testset), $test) or
	    diag(sprintf("expected cpuset %s, got cpuset %s", $set->sprintf, $testset->sprintf));
	};
      } else {
	isnt($rc, 0, $test);
      }

      $test = "bind whole process to cpuset (STRICT)";
      $rc = hwloc_set_proc_cpubind($t, $$, $set, HWLOC_CPUBIND_STRICT);
      if($support->{cpubind}->{set_proc_cpubind}) {
	is($rc, 0, $test);
      } else {
	isnt($rc, 0, $test);
      }

      $test = "get whole process's binding to cpuset (STRICT)";
      $rc = hwloc_get_proc_cpubind($t, $$, $testset, HWLOC_CPUBIND_STRICT);
      if($support->{cpubind}->{get_proc_cpubind}) {
	subtest $test => sub {
	  plan tests => 2;
	  is($rc, 0, $test);
	  ok($set->isequal($testset), $test) or
	    diag(sprintf("expected cpuset %s, got cpuset %s", $set->sprintf, $testset->sprintf));
	};
      } else {
	isnt($rc, 0, $test);
      }

    };

  } else {

    subtest $test => sub {

      plan tests => 4;

      $test = "bind this process to cpuset (STRICT)";
      $rc = hwloc_set_cpubind($t, $set, HWLOC_CPUBIND_STRICT);
      is($rc, 0, $test);

      $test = "bind this thread to cpuset (STRICT)";
      $rc = hwloc_set_cpubind($t, $set, HWLOC_CPUBIND_STRICT | HWLOC_CPUBIND_THREAD);
      is($rc, 0, $test);

      $test = "bind this whole process to cpuset (STRICT)";
      $rc = hwloc_set_cpubind($t, $set, HWLOC_CPUBIND_STRICT | HWLOC_CPUBIND_PROCESS);
      is($rc, 0, $test);

      $test = "bind whole process to cpuset (STRICT)";
      $rc = hwloc_set_proc_cpubind($t, $$, $set, HWLOC_CPUBIND_STRICT);
      is($rc, 0, $test);

    };

  }

  $testset->free if $testset;

} else {
  fail($test);
}

# --
# Bind to CPUs of a subset
# --

$test = "Bind to CPUs of a sub-cpuset";
$o    = $root;
while($set->isequal($o->cpuset)) {
  last unless $o->arity;
  $o = $o->first_child;
}
$set = $o->cpuset;
if(isa_ok($set, $cpuset_c)) {

  $testset = $set->dup;
  BAIL_OUT("Failed to duplicate cpuset") unless $testset;

  if($apiVersion) {

    subtest $test => sub {

      plan tests => 8;

      $test = "bind this process to cpuset";
      $rc = hwloc_set_cpubind($t, $set, 0);
      if($support->{cpubind}->{set_thisproc_cpubind} || $support->{cpubind}->{set_thisthread_cpubind}) {
	is($rc, 0, $test);
      } else {
	isnt($rc, 0, $test);
      }

      $test = "get this process's binding to cpuset";
      $rc = hwloc_get_cpubind($t, $testset, 0);
      if($support->{cpubind}->{get_thisproc_cpubind} || $support->{cpubind}->{get_thisthread_cpubind}) {
	subtest $test => sub {
	  plan tests => 2;
	  is($rc, 0, $test);
	  ok($set->isequal($testset), $test) or
	    diag(sprintf("expected cpuset %s, got cpuset %s", $set->sprintf, $testset->sprintf));
	};
      } else {
	isnt($rc, 0, $test);
      }

      $test = "bind this thread to cpuset";
      $rc = hwloc_set_cpubind($t, $set, HWLOC_CPUBIND_THREAD);
      if($support->{cpubind}->{set_thisthread_cpubind}) {
	is($rc, 0, $test);
      } else {
	isnt($rc, 0, $test);
      }

      $test = "get this thread's binding to cpuset";
      $rc = hwloc_get_cpubind($t, $testset, HWLOC_CPUBIND_THREAD);
      if($support->{cpubind}->{get_thisthread_cpubind}) {
	subtest $test => sub {
	  plan tests => 2;
	  is($rc, 0, $test);
	  ok($set->isequal($testset), $test) or
	    diag(sprintf("expected cpuset %s, got cpuset %s", $set->sprintf, $testset->sprintf));
	};
      } else {
	isnt($rc, 0, $test);
      }

      $test = "bind this whole process to cpuset";
      $rc = hwloc_set_cpubind($t, $set, HWLOC_CPUBIND_PROCESS);
      if($support->{cpubind}->{set_thisproc_cpubind}) {
	is($rc, 0, $test);
      } else {
	isnt($rc, 0, $test);
      }

      $test = "get this whole process's binding to cpuset";
      $rc = hwloc_get_cpubind($t, $testset, HWLOC_CPUBIND_PROCESS);
      if($support->{cpubind}->{get_thisproc_cpubind}) {
	subtest $test => sub {
	  plan tests => 2;
	  is($rc, 0, $test);
	  ok($set->isequal($testset), $test) or
	    diag(sprintf("expected cpuset %s, got cpuset %s", $set->sprintf, $testset->sprintf));
	};
      } else {
	isnt($rc, 0, $test);
      }

      $test = "bind whole process to cpuset";
      $rc = hwloc_set_proc_cpubind($t, $$, $set, 0);
      if($support->{cpubind}->{set_proc_cpubind}) {
	is($rc, 0, $test);
      } else {
	isnt($rc, 0, $test);
      }

      $test = "get whole process's binding to cpuset";
      $rc = hwloc_get_proc_cpubind($t, $$, $testset, 0);
      if($support->{cpubind}->{get_proc_cpubind}) {
	subtest $test => sub {
	  plan tests => 2;
	  is($rc, 0, $test);
	  ok($set->isequal($testset), $test) or
	    diag(sprintf("expected cpuset %s, got cpuset %s", $set->sprintf, $testset->sprintf));
	};
      } else {
	isnt($rc, 0, $test);
      }

    };

  } else {

    subtest $test => sub {

      plan tests => 4;

      $test = "bind this process to cpuset";
      $rc = hwloc_set_cpubind($t, $set, 0);
      is($rc, 0, $test);

      $test = "bind this thread to cpuset";
      $rc = hwloc_set_cpubind($t, $set, HWLOC_CPUBIND_THREAD);
      is($rc, 0, $test);

      $test = "bind this whole process to cpuset";
      $rc = hwloc_set_cpubind($t, $set, HWLOC_CPUBIND_PROCESS);
      is($rc, 0, $test);

      $test = "bind whole process to cpuset";
      $rc = hwloc_set_proc_cpubind($t, $$, $set, 0);
      is($rc, 0, $test);

    };

  }

  $testset->free if $testset;

} else {
  fail($test);
}

# --
# Bind to CPUs of a subset (STRICT)
# --

$test = "Bind to CPUs of a sub-cpuset (STRICT)";
$o    = $root;
while($set->isequal($o->cpuset)) {
  last unless $o->arity;
  $o = $o->first_child;
}
$set = $o->cpuset;
if(isa_ok($set, $cpuset_c)) {

  $testset = $set->dup;
  BAIL_OUT("Failed to duplicate cpuset") unless $testset;

  if($apiVersion) {

    subtest $test => sub {

      plan tests => 8;

      $test = "bind this process to cpuset (STRICT)";
      $rc = hwloc_set_cpubind($t, $set, HWLOC_CPUBIND_STRICT);
      if($support->{cpubind}->{set_thisproc_cpubind} || $support->{cpubind}->{set_thisthread_cpubind}) {
	is($rc, 0, $test);
      } else {
	isnt($rc, 0, $test);
      }

      $test = "get this process's binding to cpuset (STRICT)";
      $rc = hwloc_get_cpubind($t, $testset, HWLOC_CPUBIND_STRICT);
      if($support->{cpubind}->{get_thisproc_cpubind} || $support->{cpubind}->{get_thisthread_cpubind}) {
	subtest $test => sub {
	  plan tests => 2;
	  is($rc, 0, $test);
	  ok($set->isequal($testset), $test) or
	    diag(sprintf("expected cpuset %s, got cpuset %s", $set->sprintf, $testset->sprintf));
	};
      } else {
	isnt($rc, 0, $test);
      }

      $test = "bind this thread to cpuset (STRICT)";
      $rc = hwloc_set_cpubind($t, $set, HWLOC_CPUBIND_STRICT | HWLOC_CPUBIND_THREAD);
      if($support->{cpubind}->{set_thisthread_cpubind}) {
	is($rc, 0, $test);
      } else {
	isnt($rc, 0, $test);
      }

      $test = "get this thread's binding to cpuset (STRICT)";
      $rc = hwloc_get_cpubind($t, $testset, HWLOC_CPUBIND_STRICT | HWLOC_CPUBIND_THREAD);
      if($support->{cpubind}->{get_thisthread_cpubind}) {
	subtest $test => sub {
	  plan tests => 2;
	  is($rc, 0, $test);
	  ok($set->isequal($testset), $test) or
	    diag(sprintf("expected cpuset %s, got cpuset %s", $set->sprintf, $testset->sprintf));
	};
      } else {
	isnt($rc, 0, $test);
      }

      $test = "bind this whole process to cpuset (STRICT)";
      $rc = hwloc_set_cpubind($t, $set, HWLOC_CPUBIND_STRICT | HWLOC_CPUBIND_PROCESS);
      if($support->{cpubind}->{set_thisproc_cpubind}) {
	is($rc, 0, $test);
      } else {
	isnt($rc, 0, $test);
      }

      $test = "get this whole process's binding to cpuset (STRICT)";
      $rc = hwloc_get_cpubind($t, $testset, HWLOC_CPUBIND_STRICT | HWLOC_CPUBIND_PROCESS);
      if($support->{cpubind}->{get_thisproc_cpubind}) {
	subtest $test => sub {
	  plan tests => 2;
	  is($rc, 0, $test);
	  ok($set->isequal($testset), $test) or
	    diag(sprintf("expected cpuset %s, got cpuset %s", $set->sprintf, $testset->sprintf));
	};
      } else {
	isnt($rc, 0, $test);
      }

      $test = "bind whole process to cpuset (STRICT)";
      $rc = hwloc_set_proc_cpubind($t, $$, $set, HWLOC_CPUBIND_STRICT);
      if($support->{cpubind}->{set_proc_cpubind}) {
	is($rc, 0, $test);
      } else {
	isnt($rc, 0, $test);
      }

      $test = "get whole process's binding to cpuset (STRICT)";
      $rc = hwloc_get_proc_cpubind($t, $$, $testset, HWLOC_CPUBIND_STRICT);
      if($support->{cpubind}->{get_proc_cpubind}) {
	subtest $test => sub {
	  plan tests => 2;
	  is($rc, 0, $test);
	  ok($set->isequal($testset), $test) or
	    diag(sprintf("expected cpuset %s, got cpuset %s", $set->sprintf, $testset->sprintf));
	};
      } else {
	isnt($rc, 0, $test);
      }

    };

  } else {

    subtest $test => sub {

      plan tests => 4;

      $test = "bind this process to cpuset (STRICT)";
      $rc = hwloc_set_cpubind($t, $set, HWLOC_CPUBIND_STRICT);
      is($rc, 0, $test);

      $test = "bind this thread to cpuset (STRICT)";
      $rc = hwloc_set_cpubind($t, $set, HWLOC_CPUBIND_STRICT | HWLOC_CPUBIND_THREAD);
      is($rc, 0, $test);

      $test = "bind this whole process to cpuset (STRICT)";
      $rc = hwloc_set_cpubind($t, $set, HWLOC_CPUBIND_STRICT | HWLOC_CPUBIND_PROCESS);
      is($rc, 0, $test);

      $test = "bind whole process to cpuset (STRICT)";
      $rc = hwloc_set_proc_cpubind($t, $$, $set, HWLOC_CPUBIND_STRICT);
      is($rc, 0, $test);

    };

  }

  $testset->free if $testset;

} else {
  fail($test);
}


# --
# Bind to MEMs of root nodeset (DEFAULT)
# --

$test = "Bind to MEMs of root nodeset";

SKIP: {

  skip $test, 2 unless $apiVersion >= 0x00010100;

  $set  = $root->nodeset;
  if(isa_ok($set, $cpuset_c)) {

    $testset = $set->dup;
    BAIL_OUT("Failed to duplicate root nodeset") unless $testset;

    subtest $test => sub {

      plan tests => 8;

      $test = "bind this process to nodeset (DEFAULT)";
      $rc = hwloc_set_membind_nodeset($t, $set, HWLOC_MEMBIND_DEFAULT(), 0);
      if($support->{membind}->{set_thisproc_membind} || $support->{membind}->{set_thisthread_membind}) {
	is($rc, 0, $test);
      } else {
	isnt($rc, 0, $test);
      }

      $test = "get this process's binding to nodeset (DEFAULT)";
      $rc = hwloc_get_membind_nodeset($t, $testset, \$policy, 0);
      if($support->{membind}->{get_thisproc_membind} || $support->{membind}->{get_thisthread_membind}) {
	subtest $test => sub {
	  plan tests => 3;
	  is($rc, 0, $test);
	  ok($set->isequal($testset), $test) or
	    diag(sprintf("expected nodeset %s, got nodeset %s", $set->sprintf, $testset->sprintf));
	  isnt($policy, HWLOC_MEMBIND_DEFAULT(), $test) or
	    diag(sprintf("expected a policy other than HWLOC_MEMBIND_DEFAULT"));
	};
      } else {
	isnt($rc, 0, $test);
      }

      $test = "bind this thread to nodeset (DEFAULT)";
      $rc = hwloc_set_membind_nodeset($t, $set, HWLOC_MEMBIND_DEFAULT(), HWLOC_MEMBIND_THREAD());
      if($support->{membind}->{set_thisthread_membind}) {
	is($rc, 0, $test);
      } else {
	isnt($rc, 0, $test);
      }

      $test = "get this thread's binding to nodeset (DEFAULT)";
      $rc = hwloc_get_membind_nodeset($t, $testset, \$policy, HWLOC_MEMBIND_THREAD());
      if($support->{membind}->{get_thisthread_membind}) {
	subtest $test => sub {
	  plan tests => 3;
	  is($rc, 0, $test);
	  ok($set->isequal($testset), $test) or
	    diag(sprintf("expected nodeset %s, got nodeset %s", $set->sprintf, $testset->sprintf));
	  isnt($policy, HWLOC_MEMBIND_DEFAULT(), $test) or
	    diag(sprintf("expected a policy other than HWLOC_MEMBIND_DEFAULT"));
	};
      } else {
	isnt($rc, 0, $test);
      }

      $test = "bind this whole process to nodeset (DEFAULT)";
      $rc = hwloc_set_membind_nodeset($t, $set, HWLOC_MEMBIND_DEFAULT(), HWLOC_MEMBIND_PROCESS());
      if($support->{membind}->{set_thisproc_membind}) {
	is($rc, 0, $test);
      } else {
	isnt($rc, 0, $test);
      }

      $test = "get this whole process's binding to nodeset (DEFAULT)";
      $rc = hwloc_get_membind_nodeset($t, $testset, \$policy, HWLOC_MEMBIND_PROCESS());
      if($support->{membind}->{get_thisproc_membind}) {
	subtest $test => sub {
	  plan tests => 3;
	  is($rc, 0, $test);
	  ok($set->isequal($testset), $test) or
	    diag(sprintf("expected nodeset %s, got nodeset %s", $set->sprintf, $testset->sprintf));
	  isnt($policy, HWLOC_MEMBIND_DEFAULT(), $test) or
	    diag(sprintf("expected a policy other than HWLOC_MEMBIND_DEFAULT"));
	};
      } else {
	isnt($rc, 0, $test);
      }

      $test = "bind whole process to nodeset (DEFAULT)";
      $rc = hwloc_set_proc_membind_nodeset($t, $$, $set, HWLOC_MEMBIND_DEFAULT(), 0);
      if($support->{membind}->{set_proc_membind}) {
	is($rc, 0, $test);
      } else {
	isnt($rc, 0, $test);
      }

      $test = "get whole process's binding to nodeset (DEFAULT)";
      $rc = hwloc_get_proc_membind_nodeset($t, $$, $testset, \$policy, 0);
      if($support->{membind}->{get_proc_membind}) {
	subtest $test => sub {
	  plan tests => 3;
	  is($rc, 0, $test);
	  ok($set->isequal($testset), $test) or
	    diag(sprintf("expected nodeet %s, got nodeset %s", $set->sprintf, $testset->sprintf));
	  isnt($policy, HWLOC_MEMBIND_DEFAULT(), $test) or
	    diag(sprintf("expected a policy other than HWLOC_MEMBIND_DEFAULT"));
	};
      } else {
	isnt($rc, 0, $test);
      }

    };

    $testset->free;

  } else {

    fail($test);

  }

};

# --
# Bind to MEMs of first NODE nodeset (BIND, STRICT)
# --

$test = "Bind to MEMs of sub-nodeset";
$o    = hwloc_get_obj_by_type($t, HWLOC_OBJ_NODE, 0);

SKIP: {

  skip $test, 2 unless ($apiVersion >= 0x00010100 && $o);

  $set  = $o->nodeset;
  if(isa_ok($set, $cpuset_c)) {

    $testset = $set->dup;
    BAIL_OUT("Failed to duplicate root nodeset") unless $testset;

    subtest $test => sub {

      plan tests => 8;

      $test = "bind this process to nodeset (BIND, STRICT)";
      $rc = hwloc_set_membind_nodeset($t, $set, HWLOC_MEMBIND_BIND(), HWLOC_MEMBIND_STRICT());
      if(($support->{membind}->{set_thisproc_membind} || $support->{membind}->{set_thisthread_membind}) && $support->{membind}->{bind_membind}) {
	is($rc, 0, $test);
      } else {
	isnt($rc, 0, $test);
      }

      $test = "get this process's binding to nodeset (BIND, STRICT)";
      $rc = hwloc_get_membind_nodeset($t, $testset, \$policy, HWLOC_MEMBIND_STRICT());
      if($support->{membind}->{get_thisproc_membind} || $support->{membind}->{get_thisthread_membind}) {
	subtest $test => sub {
	  plan tests => 3;
	  is($rc, 0, $test);
	  ok($set->isequal($testset), $test) or
	    diag(sprintf("expected nodeset %s, got nodeset %s", $set->sprintf, $testset->sprintf));
	  is($policy, HWLOC_MEMBIND_BIND(), $test) or
	    diag(sprintf("expected policy HWLOC_MEMBIND_BIND"));
	};
      } else {
	isnt($rc, 0, $test);
      }

      $test = "bind this thread to nodeset (BIND, STRICT)";
      $rc = hwloc_set_membind_nodeset($t, $set, HWLOC_MEMBIND_BIND(), HWLOC_MEMBIND_THREAD() | HWLOC_MEMBIND_STRICT());
      if($support->{membind}->{set_thisthread_membind} && $support->{membind}->{bind_membind}) {
	is($rc, 0, $test);
      } else {
	isnt($rc, 0, $test);
      }

      $test = "get this thread's binding to nodeset (BIND, STRICT)";
      $rc = hwloc_get_membind_nodeset($t, $testset, \$policy, HWLOC_MEMBIND_THREAD() | HWLOC_MEMBIND_STRICT());
      if($support->{membind}->{get_thisthread_membind}) {
	subtest $test => sub {
	  plan tests => 3;
	  is($rc, 0, $test);
	  ok($set->isequal($testset), $test) or
	    diag(sprintf("expected nodeset %s, got nodeset %s", $set->sprintf, $testset->sprintf));
	  is($policy, HWLOC_MEMBIND_BIND(), $test) or
	    diag(sprintf("expected policy HWLOC_MEMBIND_BIND"));
	};
      } else {
	isnt($rc, 0, $test);
      }

      $test = "bind this whole process to nodeset (BIND, STRICT)";
      $rc = hwloc_set_membind_nodeset($t, $set, HWLOC_MEMBIND_BIND(), HWLOC_MEMBIND_PROCESS() | HWLOC_MEMBIND_STRICT());
      if($support->{membind}->{set_thisproc_membind} && $support->{membind}->{bind_membind}) {
	is($rc, 0, $test);
      } else {
	isnt($rc, 0, $test);
      }

      $test = "get this whole process's binding to nodeset (BIND, STRICT)";
      $rc = hwloc_get_membind_nodeset($t, $testset, \$policy, HWLOC_MEMBIND_PROCESS() | HWLOC_MEMBIND_STRICT());
      if($support->{membind}->{get_thisproc_membind}) {
	subtest $test => sub {
	  plan tests => 3;
	  is($rc, 0, $test);
	  ok($set->isequal($testset), $test) or
	    diag(sprintf("expected nodeset %s, got nodeset %s", $set->sprintf, $testset->sprintf));
	  is($policy, HWLOC_MEMBIND_BIND(), $test) or
	    diag(sprintf("expected policy HWLOC_MEMBIND_BIND"));
	};
      } else {
	isnt($rc, 0, $test);
      }

      $test = "bind whole process to nodeset (BIND, STRICT)";
      $rc = hwloc_set_proc_membind_nodeset($t, $$, $set, HWLOC_MEMBIND_BIND(), HWLOC_MEMBIND_STRICT());
      if($support->{membind}->{set_proc_membind}) {
	is($rc, 0, $test);
      } else {
	isnt($rc, 0, $test);
      }

      $test = "get whole process's binding to nodeset (BIND, STRICT)";
      $rc = hwloc_get_proc_membind_nodeset($t, $$, $testset, \$policy, HWLOC_MEMBIND_STRICT());
      if($support->{membind}->{get_proc_membind}) {
	subtest $test => sub {
	  plan tests => 3;
	  is($rc, 0, $test);
	  ok($set->isequal($testset), $test) or
	    diag(sprintf("expected nodeet %s, got nodeset %s", $set->sprintf, $testset->sprintf));
	  is($policy, HWLOC_MEMBIND_BIND(), $test) or
	    diag(sprintf("expected policy HWLOC_MEMBIND_BIND"));
	};
      } else {
	isnt($rc, 0, $test);
      }

    };

    $testset->free;

  } else {

    fail($test);

  }

};


