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
# Basic topology tests
#
# $Id: 02-topo.t,v 1.14 2011/01/11 10:49:40 bzbkalli Exp $
#
################################################################################

use Test::More 0.94;
use strict;
use Sys::Hwloc 0.04;

my $apiVersion = HWLOC_API_VERSION();
my $proc_t     = $apiVersion ? HWLOC_OBJ_PU() : HWLOC_OBJ_PROC();
my ($t, $rc, $ok);

plan tests => 40;

# --
# Init topology, stop testing if this fails
# --

$t = hwloc_topology_init();
isa_ok($t, 'Sys::Hwloc::Topology', 'hwloc_topology_init()') or
  BAIL_OUT("Failed to initialize topology context via hwloc_topology_init()");

# --
# Configure topology detection
# --

$rc = hwloc_topology_is_thissystem($t);
is($rc, 1, 'hwloc_topology_is_thissystem()');

$rc = hwloc_topology_ignore_type($t, HWLOC_OBJ_MISC);
is($rc, 0, 'hwloc_topology_ignore_type(HWLOC_OBJ_MISC)');

$rc = hwloc_topology_ignore_type($t, $proc_t);
is($rc, -1, "hwloc_topology_ignore_type($proc_t)");

$rc = hwloc_topology_ignore_type_keep_structure($t, HWLOC_OBJ_MISC);
is($rc, 0, 'hwloc_topology_ignore_type_keep_structure(HWLOC_OBJ_MISC)');

$rc = hwloc_topology_ignore_all_keep_structure($t);
is($rc, 0, 'hwloc_topology_ignore_all_keep_structure(HWLOC_OBJ_MISC)');

$rc = hwloc_topology_set_flags($t, HWLOC_TOPOLOGY_FLAG_WHOLE_SYSTEM);
is($rc, 0, 'hwloc_topology_set_flags(HWLOC_TOPOLOGY_FLAG_WHOLE_SYSTEM)');

$rc = hwloc_topology_set_fsroot($t, '/');
is($rc, 0, 'hwloc_topology_set_fsroot(/)');

$rc = hwloc_topology_set_fsroot($t, '/MurKs');
is($rc, -1, 'hwloc_topology_set_fsroot(/MurKs)');

SKIP: {

  skip 'hwloc_topology_set_pid()', 1 unless $apiVersion;

  $rc = hwloc_topology_set_pid($t, $$);
  is($rc, 0, 'hwloc_topology_set_pid($$)');

};

$rc = hwloc_topology_set_synthetic($t, '1');
is($rc, 0, 'hwloc_topology_set_synthetic(1)');

$rc = hwloc_topology_is_thissystem($t);
is($rc, 0, 'hwloc_topology_is_thissystem()');

$rc = hwloc_topology_set_xml($t, '/MurKs');
is($rc, -1, 'hwloc_topology_set_xml(/MurKs)');

# --
# Check topology support, n/a before hwloc 1.0
# --

SKIP: {

  skip 'Topology support', 2 unless $apiVersion;

  $rc = hwloc_topology_get_support($t);
  if(isa_ok($rc, 'HASH', 'hwloc_topology_get_support()')) {

    subtest 'Topology support data' => sub {

      plan tests => $apiVersion == 0x00010000 ? 3 : 4;

      isa_ok($rc->{discovery},     'HASH', 'hwloc_topology_support->{discovery}');
      isnt($rc->{discovery}->{pu}, undef,  'hwloc_topology_support->{discovery}->{pu}');
      isa_ok($rc->{cpubind},       'HASH', 'hwloc_topology_support->{cpubind}');

      if($apiVersion > 0x00010000) {
	isa_ok($rc->{membind}, 'HASH', 'hwloc_topology_support->{membind}');
      }

    };

  } else {
    fail('Topology support data');
  }

};

# --
# Load topology, stop testing if this fails
# --

$rc = hwloc_topology_load($t);
is($rc, 0, 'hwloc_topology_load()') or
  BAIL_OUT("Failed to load topology context");

# --
# Destroy topology
# --

hwloc_topology_destroy($t);

# --
# These should all croak
# --

$rc = undef;

eval "\$rc = hwloc_topology_ignore_type(\$t, HWLOC_OBJ_MISC)";
is($rc, undef, 'hwloc_topology_ignore_type(undef)');

eval "\$rc = hwloc_topology_ignore_type_keep_structure(\$t, HWLOC_OBJ_MISC)";
is($rc, undef, 'hwloc_topology_ignore_type_keep_structure(undef)');

eval "\$rc = hwloc_topology_ignore_all_keep_structure(\$t)";
is($rc, undef, 'hwloc_topology_ignore_all_keep_structure(undef)');

eval ("\$rc = hwloc_topology_set_flags(\$t, HWLOC_TOPOLOGY_FLAG_WHOLE_SYSTEM)");
is($rc, undef, 'hwloc_topology_set_flags(undef)');

eval ("\$rc = hwloc_topology_set_fsroot(\$t, '/')");
is($rc, undef, 'hwloc_topology_set_fsroot(undef)');

eval ("\$rc = hwloc_topology_load(\$t)");
is($rc, undef, 'hwloc_topology_load(undef)');

eval ("\$rc = hwloc_topology_destroy(\$t)");
is($rc, undef, 'hwloc_topology_destroy(undef)');

# --
# Now try OO
# --

$t = Sys::Hwloc::Topology->init;
isa_ok($t, 'Sys::Hwloc::Topology', 'Sys::Hwloc::Topology->init') or
  BAIL_OUT("Failed to initialize topology context via Sys::Hwloc::Topology->init");

$rc = $t->is_thissystem;
is($rc, 1, 't->is_thissystem()');

$rc = $t->ignore_type(HWLOC_OBJ_MISC);
is($rc, 0, 't->ignore_type(HWLOC_OBJ_MISC)');

$rc = $t->ignore_type($proc_t);
is($rc, -1, "t->ignore_type($proc_t)");

$rc = $t->ignore_type_keep_structure(HWLOC_OBJ_MISC);
is($rc, 0, 't->ignore_type_keep_structure(HWLOC_OBJ_MISC)');

$rc = $t->ignore_all_keep_structure();
is($rc, 0, 't->ignore_all_keep_structure(HWLOC_OBJ_MISC)');

$rc = $t->set_flags(HWLOC_TOPOLOGY_FLAG_WHOLE_SYSTEM);
is($rc, 0, 't->set_flags(HWLOC_TOPOLOGY_FLAG_WHOLE_SYSTEM)');

$rc = $t->set_fsroot('/');
is($rc, 0, 't->set_fsroot(/)');

$rc = $t->set_fsroot('/MurKs');
is($rc, -1, 't->set_fsroot(/MurKs)');

SKIP: {

  skip 't->set_pid()', 1 unless $apiVersion;

  $rc = $t->set_pid($$);
  is($rc, 0, "t->set_pid($$)");

};

$rc = $t->set_synthetic('1');
is($rc, 0, 't->set_synthetic(1)');

$rc = $t->is_thissystem;
is($rc, 0, 't->is_thissystem()');

$rc = $t->set_xml('/MurKs');
is($rc, -1, 't->set_xml(/MurKs)');

SKIP: {

  skip 'Topology support', 2 unless $apiVersion;

  $rc = $t->get_support;
  if(isa_ok($rc, 'HASH', 't->get_support')) {
    subtest 'Topology support data' => sub {

      plan tests => 2;

      isa_ok($rc->{discovery},     'HASH', 'hwloc_topology_support->{discovery}');
      isnt($rc->{discovery}->{pu}, undef,  'hwloc_topology_support->{discovery}->{pu}');

    };
  } else {
    fail('Topology support data');
  }

};

$rc = $t->load;
is($rc, 0, 't->load') or
  BAIL_OUT("Failed to load topology context");

# --
# Destroy topology
# --

$t->destroy;
$rc = undef;
eval ("\$rc = \$t->destroy; 1)");
is($rc, undef, 't->destroy');
