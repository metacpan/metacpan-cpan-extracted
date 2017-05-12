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
# Test the Sys::Hwloc::Cpuset API (hwloc-0.9 and 1.0)
#
# $Id: 07-cpuset.t,v 1.15 2011/01/11 10:49:40 bzbkalli Exp $
#
################################################################################

use Test::More 0.94;
use strict;
use Sys::Hwloc 0.08 qw(:DEFAULT :cpuset);

plan tests => 122;

my $apiVersion = HWLOC_XSAPI_VERSION();
my ($set, $set0, $set1, $rc);

SKIP: {

  skip 'Sys::Hwloc::Cpuset', 122 if ($apiVersion > 0x00010000);

  # --
  # Init cpuset, stop testing if this fails
  # --

  $set  = hwloc_cpuset_alloc();
  isa_ok($set, 'Sys::Hwloc::Cpuset', 'hwloc_cpuset_alloc()') or
    BAIL_OUT("Failed to initialize a cpuset via hwloc_cpuset_alloc()");

  # --
  # Should be empty
  # --

  $rc = hwloc_cpuset_to_ulong($set);
  is($rc, 0, 'hwloc_cpuset_to_ulong(<new>)');
  $rc = hwloc_cpuset_to_ith_ulong($set,0);
  is($rc, 0, 'hwloc_cpuset_to_ith_ulong(<new>,0)');
  $rc = hwloc_cpuset_sprintf($set);
  like($rc, $apiVersion ? qr/^0x0+$/ : qr/^0+$/, 'hwloc_cpuset_sprintf(<new>)');
  $rc = hwloc_cpuset_iszero($set);
  is($rc, 1, 'hwloc_cpuset_iszero(<new>)');
  $rc = hwloc_cpuset_isfull($set);
  is($rc, 0, 'hwloc_cpuset_isfull(<new>)');
  $rc = hwloc_cpuset_first($set);
  is($rc, -1, 'hwloc_cpuset_first(<new>)');
  $rc = hwloc_cpuset_last($set);
  is($rc, -1, 'hwloc_cpuset_last(<new>)');
  $rc = hwloc_cpuset_weight($set);
  is($rc, 0, 'hwloc_cpuset_weight(<new>)');

  # --
  # Fill set, check if full
  # --

  hwloc_cpuset_fill($set);
  $rc = hwloc_cpuset_iszero($set);
  is($rc, 0, 'hwloc_cpuset_fill() iszero');
  $rc = hwloc_cpuset_isfull($set);
  is($rc, 1, 'hwloc_cpuset_fill() isfull');
  $rc =  hwloc_cpuset_to_ulong($set);
  cmp_ok($rc, '>', 0, 'hwloc_cpuset_to_ulong(<full>)');
  $rc = hwloc_cpuset_sprintf($set);
  like($rc, $apiVersion ? qr/^0xf+(,0xf+(,.+|)|)$/i : qr/^f+(,f+(,.+|)|)$/i, 'hwloc_cpuset_sprintf(<full>)');
  $rc =  hwloc_cpuset_to_ith_ulong($set,0);
  cmp_ok($rc, '>', 0, 'hwloc_cpuset_to_ith_ulong(<full>,0)');
  $rc = hwloc_cpuset_weight($set);
  isnt($rc, 0, 'hwloc_cpuset_weight(<full>');

  # --
  # Zero out, check
  # --

  hwloc_cpuset_zero($set);
  $rc = hwloc_cpuset_iszero($set);
  is($rc, 1, 'hwloc_cpuset_zero(<full>) iszero');

  # --
  # Duplicate set, check if the same, set cpu0, check if set
  # --

  $set0 = hwloc_cpuset_dup($set);
  isa_ok($set0, 'Sys::Hwloc::Cpuset', 'hwloc_cpuset_dup()') or
    BAIL_OUT("Failed to dup a cpuset via hwloc_cpuset_dup()");
  if(! $apiVersion) {
    $rc = hwloc_cpuset_compar($set,$set0);
  } else {
    $rc = hwloc_cpuset_compare($set,$set0);
  }
  is($rc, 0, 'hwloc_cpuset_compare(<emptydup>,<empty>)');
  $rc = hwloc_cpuset_isequal($set,$set0);
  is($rc, 1, 'hwloc_cpuset_isequal(<emptydup>,<empty>)');

  hwloc_cpuset_cpu($set0,0);
  if(! $apiVersion) {
    $rc = hwloc_cpuset_compar($set,$set0);
  } else {
    $rc = hwloc_cpuset_compare($set,$set0);
  }
  is($rc, -1, 'hwloc_cpuset_compare(<empty>,<cpu0>)');
  $rc = hwloc_cpuset_isequal($set,$set0);
  is($rc, 0, 'hwloc_cpuset_isequal(<empty>,<cpu0>)');
  $rc = hwloc_cpuset_to_ulong($set0);
  is($rc, 1, 'hwloc_cpuset_to_ulong(<cpu0>)');
  $rc = hwloc_cpuset_sprintf($set0);
  like($rc, $apiVersion ? qr/^0x0+1$/ : qr/^0+1$/, 'hwloc_cpuset_sprintf(<cpu0>)');
  $rc = hwloc_cpuset_iszero($set0);
  is($rc, 0, 'hwloc_cpuset_iszero(<cpu0>)');
  $rc = hwloc_cpuset_isfull($set0);
  is($rc, 0, 'hwloc_cpuset_isfull(<cpu0>)');
  $rc = hwloc_cpuset_isset($set0,0);
  is($rc, 1, 'hwloc_cpuset_isset(<cpu0>,0)');
  $rc = hwloc_cpuset_first($set0);
  is($rc, 0, 'hwloc_cpuset_first(<cpu0>)');
  $rc = hwloc_cpuset_last($set0);
  is($rc, 0, 'hwloc_cpuset_last(<cpu0>)');
  $rc = hwloc_cpuset_weight($set0);
  is($rc, 1, 'hwloc_cpuset_weight(<cpu0>)');

  # --
  # Duplicate set, reinit from int to set cpu1, check if set
  # --

  $set1 = hwloc_cpuset_dup($set0);
  isa_ok($set, 'Sys::Hwloc::Cpuset', 'hwloc_cpuset_dup()') or
    BAIL_OUT("Failed to initialize a cpuset via hwloc_cpuset_dup()");

  hwloc_cpuset_from_ulong($set1,1 << 1);
  if(! $apiVersion) {
    $rc = hwloc_cpuset_compar($set1,$set0);
  } else {
    $rc = hwloc_cpuset_compare($set1,$set0);
  }
  is($rc, 1, 'hwloc_cpuset_compare(<cpu1>,<cpu0>)');
  $rc = hwloc_cpuset_to_ulong($set1);
  is($rc, 1 << 1, 'hwloc_cpuset_to_ulong(<cpu1>)');
  $rc = hwloc_cpuset_isset($set1,0);
  is($rc, 0, 'hwloc_cpuset_isset(<cpu1>,0)');
  $rc = hwloc_cpuset_isset($set1,1);
  is($rc, 1, 'hwloc_cpuset_isset(<cpu1>,1)');
  $rc = hwloc_cpuset_includes($set0,$set1);
  is($rc, 0, 'hwloc_cpuset_includes(<cpu0>,<cpu1>)');
  $rc = hwloc_cpuset_isincluded($set0,$set1);
  is($rc, 0, 'hwloc_cpuset_isincluded(<cpu0>,<cpu1>)');
  $rc = hwloc_cpuset_intersects($set0,$set1);
  is($rc, 0, 'hwloc_cpuset_intersects(<cpu0>,<cpu1>)');

  # --
  # Check logics
  #  cpu0 | cpu1         should be 3
  # (cpu0 | cpu1) & cpu0 should be 1
  #  cpu0 ^ cpu0         should be 0
  # !(cpu0 ^ cpu0)       should be full
  # cpu0 & ! full        should be 0
  # --

  if(! $apiVersion) {
    hwloc_cpuset_orset($set1,$set0);
    $rc = hwloc_cpuset_to_ulong($set1);
    is($rc, (1 << 0) | (1 << 1), 'hwloc_cpuset_to_ulong(<cpu0 | cpu1>)');
    hwloc_cpuset_andset($set1,$set0);
    $rc = hwloc_cpuset_to_ulong($set1);
    is($rc, ((1 << 0) | (1 << 1)) & (1 << 0), 'hwloc_cpuset_to_ulong(<cpu0 | cpu1> & <cpu0>)');
    hwloc_cpuset_xorset($set0,$set0);
    $rc = hwloc_cpuset_to_ulong($set0);
    is($rc, (1 << 0) ^ (1 << 0), 'hwloc_cpuset_to_ulong(<cpu0 ^ cpu0>)');
  } else {
    hwloc_cpuset_or($set,$set0,$set1);
    $rc = hwloc_cpuset_to_ulong($set);
    is($rc, (1 << 0) | (1 << 1), 'hwloc_cpuset_to_ulong(<cpu0 | cpu1>)');
    hwloc_cpuset_and($set1,$set,$set0);
    $rc = hwloc_cpuset_to_ulong($set1);
    is($rc, ((1 << 0) | (1 << 1)) & (1 << 0), 'hwloc_cpuset_to_ulong(<cpu0 | cpu1> & <cpu0>)');
    hwloc_cpuset_xor($set,$set0,$set0);
    $rc = hwloc_cpuset_to_ulong($set);
    is($rc, (1 << 0) ^ (1 << 0), 'hwloc_cpuset_to_ulong(<cpu0 ^ cpu0>)');
  }

 SKIP: {

    skip "hwloc_cpuset_not()", 1 unless $apiVersion;

    hwloc_cpuset_not($set1,$set);
    $rc = hwloc_cpuset_isfull($set1);
    is($rc, 1, 'hwloc_cpuset_isfull(! <cpu0 ^ cpu0>)');

  };

 SKIP: {

    skip "hwloc_cpuset_andnot()", 1 unless $apiVersion;

    hwloc_cpuset_andnot($set,$set0,$set1);
    $rc = hwloc_cpuset_iszero($set);
    is($rc, 1, 'hwloc_cpuset_iszero(<cpu0> & ! full)');

  };

  # --
  # Init set from stringified arithmetic expression
  # --

  if(! $apiVersion) {
    hwloc_cpuset_free($set);
    eval "\$set = hwloc_cpuset_from_string(1 | 2)";
    isa_ok($set, 'Sys::Hwloc::Cpuset', 'hwloc_cpuset_from_string()');
  } else {
    eval "\$rc = hwloc_cpuset_from_string(\$set, 1 | 2)";
    is($rc, 0, 'hwloc_cpuset_from_string(1 | 2)');
  }
  $rc = hwloc_cpuset_isset($set,0);
  is($rc, 1, 'hwloc_cpuset_isset(1 | 2,0)');
  $rc = hwloc_cpuset_isset($set,1);
  is($rc, 1, 'hwloc_cpuset_isset(1 | 2,1)');
  $rc = hwloc_cpuset_weight($set);
  is($rc, 2, 'hwloc_cpuset_weight(1 | 2)');

  # --
  # Add cpu2, check
  # --

  hwloc_cpuset_zero($set);
  hwloc_cpuset_set($set,2);
  $rc = hwloc_cpuset_to_ulong($set);
  is($rc, 1 << 2, 'hwloc_cpuset_to_ulong(<cpu2>)');

  # --
  # Add cpu3 and 4, check
  # --

  hwloc_cpuset_zero($set);
  hwloc_cpuset_set_range($set,3,4);
  $rc = hwloc_cpuset_to_ulong($set);
  is($rc, (1 << 3) | (1 << 4), 'hwloc_cpuset_to_ulong(<cpu3,cpu4>)');
  my @ids = hwloc_cpuset_ids($set);
  is(scalar @ids, 2, 'scalar hwloc_cpuset_ids(<cpu3,cpu4>)');
  is(join(',', @ids), join(',', 3, 4), 'hwloc_cpuset_ids(<cpu3,cpu4>)');

  # --
  # Remove cpu4, check
  # --

  hwloc_cpuset_clr($set,4);
  $rc = hwloc_cpuset_isset($set,4);
  is($rc, 0, 'hwloc_cpuset_isset(<cpu3>,4)');
  $rc = hwloc_cpuset_to_ulong($set);
  is($rc, 1 << 3, 'hwloc_cpuset_to_ulong(<cpu3>)');

  # --
  # Remove cpu2 and 3, check
  # --

 SKIP: {

    skip "hwloc_cpuset_clr_range()", 1 unless $apiVersion;

    hwloc_cpuset_clr_range($set,2,3);
    $rc = hwloc_cpuset_to_ulong($set);
    is($rc, 0, 'hwloc_cpuset_to_ulong(<empty>)');

  };

  # --
  # Init full without cpu0
  # --

  hwloc_cpuset_all_but_cpu($set,0);
  $rc = hwloc_cpuset_isset($set,0);
  is($rc, 0, 'hwloc_cpuset_isset(<full w/o cpu0>,0)');

  # --
  # Compare against full using lowest cpu idx
  # --

  hwloc_cpuset_fill($set1);
  if(! $apiVersion) {
    $rc = hwloc_cpuset_compar_first($set,$set1);
    is($rc, 1, 'hwloc_cpuset_compar_first(<full w/o cpu0>,<full>)');
    $rc = hwloc_cpuset_compar_first($set1,$set);
    is($rc, -1, 'hwloc_cpuset_compar_first(<full>,<full w/o cpu0>)');
    $rc = hwloc_cpuset_compar_first($set,$set);
    is($rc, 0, 'hwloc_cpuset_compar_first(<full w/o cpu0>,<full w/o cpu0>)');
  } else {
    $rc = hwloc_cpuset_compare_first($set,$set1);
    is($rc, 1, 'hwloc_cpuset_compare_first(<full w/o cpu0>,<full>)');
    $rc = hwloc_cpuset_compare_first($set1,$set);
    is($rc, -1, 'hwloc_cpuset_compare_first(<full>,<full w/o cpu0>)');
    $rc = hwloc_cpuset_compare_first($set,$set);
    is($rc, 0, 'hwloc_cpuset_compare_first(<full w/o cpu0>,<full w/o cpu0>)');
  }

  # --
  # Init with cpu2 .. 4, check next iterator
  # --

  hwloc_cpuset_zero($set);
  hwloc_cpuset_set_range($set,2,4);
  if(ok(hwloc_cpuset_isset($set,2) && hwloc_cpuset_isset($set,3) && hwloc_cpuset_isset($set,4), 'set 2 .. 4')) {

  SKIP: {

      skip "hwloc_cpuset_next()", 1 unless $apiVersion;

      subtest "hwloc_cpuset_next()" => sub {
	plan tests => 5;
	is(hwloc_cpuset_next($set,0), 2, "hwloc_cpuset_next(0)");
	is(hwloc_cpuset_next($set,1), 2, "hwloc_cpuset_next(1)");
	is(hwloc_cpuset_next($set,2), 3, "hwloc_cpuset_next(2)");
	is(hwloc_cpuset_next($set,3), 4, "hwloc_cpuset_next(3)");
	is(hwloc_cpuset_next($set,4), -1, "hwloc_cpuset_next(4)");
      };

    };
  } else {
    fail("hwloc_cpuset_next()");
  }

  # --
  # Check sprintf_list output and the reverse
  # --

 SKIP: {

    skip "hwloc_cpuset_liststrings", 2 unless $apiVersion;

    hwloc_cpuset_zero($set);
    hwloc_cpuset_set_range($set,0,7);
    hwloc_cpuset_set_range($set,16,17);
    hwloc_cpuset_set_range($set,24,27);
    my $str = hwloc_cpuset_list_sprintf($set);
    is($str, '0-7,16,17,24-27', 'hwloc_cpuset_list_sprintf(0-7,16,17,24-27)');

    hwloc_cpuset_from_liststring($set0,$str);
    $rc = hwloc_cpuset_isequal($set,$set0);
    is($rc, 1, "hwloc_cpuset_from_liststring($str) eq '0-7,16,17,24-27'");

  };

  # --
  # Free cpusets
  # --

  hwloc_cpuset_free($set);
  hwloc_cpuset_free($set0);
  hwloc_cpuset_free($set1);

  # ==
  # Now try OO
  # ==

  # --
  # Init cpuset, stop testing if this fails
  # --

  $set = Sys::Hwloc::Cpuset->new;
  isa_ok($set, 'Sys::Hwloc::Cpuset', 'Sys::Hwloc::Cpuset->new') or
    BAIL_OUT("Failed to initialize a cpuset via Sys::Hwloc::Cpuset->new");

  # --
  # Should be empty
  # --

  $rc = $set->to_ulong;
  is($rc, 0, 'newset->to_ulong');
  $rc = $set->to_ith_ulong(0);
  is($rc, 0, 'newset->to_ith_ulong(0)');
  $rc = $set->sprintf;
  like($rc, $apiVersion ? qr/^0x0+$/ : qr/^0+$/, 'newset->sprintf');
  $rc = $set->iszero;
  is($rc, 1, 'newset->iszero');
  $rc = $set->isfull;
  is($rc, 0, 'newset->isfull');
  $rc = $set->first;
  is($rc, -1, 'newset->first');
  $rc = $set->last;
  is($rc, -1, 'newset->last');
  $rc = $set->weight;
  is($rc, 0, 'newset->weight');

  # --
  # Fill set, check if full
  # --

  $set->fill;
  $rc = $set->iszero;
  is($rc, 0, 'set->fill iszero');
  $rc = $set->isfull;
  is($rc, 1, 'set->fill isfull');
  $rc = $set->to_ulong;
  cmp_ok($rc, '>', 0, 'fullset->to_ulong');
  $rc = $set->sprintf;
  like($rc, $apiVersion ? qr/^0xf+(,0xf+(,.+|)|)$/i : qr/^f+(,f+(,.+|)|)$/i, 'fullset->sprintf');
  $rc = $set->to_ith_ulong(0);
  cmp_ok($rc, '>', 0, 'fullset->to_ith_ulong(0)');
  $rc = $set->weight;
  isnt($rc, 0, 'fullset->weight');

  # --
  # Zero out, check
  # --

  $set->zero;
  $rc = $set->iszero;
  is($rc, 1, 'fullset->zero iszero');

  # --
  # Duplicate set, check if the same, set cpu0, check if set
  # --

  $set0 = $set->dup;
  isa_ok($set0, 'Sys::Hwloc::Cpuset', 'emptyset->dup') or
    BAIL_OUT("Failed to dup a cpuset via set->dup");
  if(! $apiVersion) {
    $rc = $set->compar($set0);
  } else {
    $rc = $set->compare($set0);
  }
  is($rc, 0, 'emptyset->compare(emptyset)');
  $rc = $set->isequal($set0);
  is($rc, 1, 'emptyset->isequal(emptyset)');

  $set0->cpu(0);
  if(! $apiVersion) {
    $rc = $set->compar($set0);
  } else {
    $rc = $set->compare($set0);
  }
  is($rc, -1, 'emptyset->compare(cpu0set)');
  $rc = $set->isequal($set0);
  is($rc, 0, 'emptyset->isequal(cpu0set)');
  $rc = $set0->to_ulong;
  is($rc, 1, 'cpu0set->to_ulong');
  $rc = $set0->sprintf;
  like($rc, $apiVersion ? qr/^0x0+1$/ : qr/^0+1$/, 'cpu0set->sprintf');
  $rc = $set0->iszero;
  is($rc, 0, 'cpu0set->iszero');
  $rc = $set0->isfull;
  is($rc, 0, 'cpu0set->isfull');
  $rc = $set0->isset(0);
  is($rc, 1, 'cpu0set->isset(0)');
  $rc = $set0->first;
  is($rc, 0, 'cpu0set->first');
  $rc = $set0->last;
  is($rc, 0, 'cpu0set->last');
  $rc = $set0->weight;
  is($rc, 1, 'cpu0set->weight');

  # --
  # Duplicate set, reinit from int to set cpu1, check if set
  # --

  $set1 = $set0->dup;
  isa_ok($set, 'Sys::Hwloc::Cpuset', 'set->dup') or
    BAIL_OUT("Failed to initialize a cpuset via set->dup");

  $set1->from_ulong(1 << 1);
  if(! $apiVersion) {
    $rc = $set1->compar($set0);
  } else {
    $rc = $set1->compare($set0);
  }
  is($rc, 1, 'cpu1set->compare(cpu0set)');
  $rc = $set1->to_ulong;
  is($rc, 1 << 1, 'cpu1set->to_ulong');
  $rc = $set1->isset(0);
  is($rc, 0, 'cpu1set->isset(0)');
  $rc = $set1->isset(1);
  is($rc, 1, 'cpu1set->isset(1)');
  $rc = $set0->includes($set1);
  is($rc, 0, 'cpu0set->includes(cpu1set)');
  $rc = $set0->isincluded($set1);
  is($rc, 0, 'cpu0set->isincluded(cpu1set)');
  $rc = $set0->intersects($set1);
  is($rc, 0, 'cpu0set->intersects(cpu1set)');

  # --
  # Check logics
  #  cpu0 | cpu1         should be 3
  # (cpu0 | cpu1) & cpu0 should be 1
  #  cpu0 ^ cpu0         should be 0
  # !(cpu0 ^ cpu0)       should be full
  # cpu0 & ! full        should be 0
  # --

  $set1->or($set0);
  $rc = $set1->to_ulong;
  is($rc, (1 << 0) | (1 << 1), 'cpu1set |= cpu0set');
  $set1->and($set0);
  $rc = $set1->to_ulong;
  is($rc, ((1 << 0) | (1 << 1)) & (1 << 0), 'cpu01set &= cpu0set');
  $set0->xor($set0);
  $rc = $set0->to_ulong;
  is($rc, (1 << 0) ^ (1 << 0), 'cpu0set ^= cpu0set');

 SKIP: {

    skip "cpuset->not", 1 unless $apiVersion;

    $set0->not;
    $rc = $set0->isfull;
    is($rc, 1, '! (cpu0set ^= cpu0set) isfull');

  };

 SKIP: {

    skip "cpuset->andnot", 1 unless $apiVersion;

    $set1->andnot($set0);
    $rc = $set1->iszero;
    is($rc, 1, '(cpu0set & ! fullset) iszero');

  };

  # --
  # Init set from stringified arithmetic expression
  # --

 SKIP: {

    skip "cpuset->from_string", 4 unless $apiVersion;

    $rc = $set->from_string(1 | 2);
    is($rc, 0, 'set->from_string(1 | 2)');
    $rc = $set->isset(0);
    is($rc, 1, '(1 | 2) -> isset(0)');
    $rc = $set->isset(1);
    is($rc, 1, '(1 | 2) -> isset(1)');
    $rc = $set->weight;
    is($rc, 2, '(1 | 2) -> weight');

  };

  # --
  # Add cpu2, check
  # --

  $set->zero;
  $set->set(2);
  $rc = $set->to_ulong;
  is($rc, 1 << 2, 'cpu2set->to_ulong');

  # --
  # Add cpu3 and 4, check
  # --

  $set->zero;
  $set->set_range(3,4);
  $rc = $set->to_ulong;
  is($rc, (1 << 3) | (1 << 4), 'cpu34set->to_ulong');
  @ids = $set->ids;
  is(scalar @ids, 2, 'scalar cpu34set->ids');
  is(join(',', @ids), join(',', 3, 4), 'cpu34set->ids');

  # --
  # Remove cpu4, check
  # --

  $set->clr(4);
  $rc = $set->isset(4);
  is($rc, 0, 'cpu3set->isset(4)');
  $rc = $set->to_ulong;
  is($rc, 1 << 3, 'cpu3set->to_ulong');

  # --
  # Remove cpu2 and 3, check
  # --

 SKIP: {

    skip "cpuset->clr_range", 1 unless $apiVersion;

    $set->clr_range(2,3);
    $rc = $set->to_ulong;
    is($rc, 0, 'emptyset->to_ulong');

  };

  # --
  # Init full without cpu0
  # --

  $set->all_but_cpu(0);
  $rc = $set->isset(0);
  is($rc, 0, 'full-wo-cpu0->isset(0)');

  # --
  # Compare against full using lowest cpu idx
  # --

  $set1->fill;
  if(! $apiVersion) {
    $rc = $set->compar_first($set1);
    is($rc, 1, 'hwloc_cpuset_compar_first(<full w/o cpu0>,<full>)');
    $rc = $set1->compar_first($set);
    is($rc, -1, 'hwloc_cpuset_compar_first(<full>,<full w/o cpu0>)');
    $rc = $set->compar_first($set);
    is($rc, 0, 'hwloc_cpuset_compar_first(<full w/o cpu0>,<full w/o cpu0>)');
  } else {
    $rc = $set->compare_first($set1);
    is($rc, 1, 'hwloc_cpuset_compare_first(<full w/o cpu0>,<full>)');
    $rc = $set1->compare_first($set);
    is($rc, -1, 'hwloc_cpuset_compare_first(<full>,<full w/o cpu0>)');
    $rc = $set->compare_first($set);
    is($rc, 0, 'hwloc_cpuset_compare_first(<full w/o cpu0>,<full w/o cpu0>)');
  }

  # --
  # Init with cpu2 .. 4, check next iterator
  # --

  $set->zero;
  $set->set_range(2,4);
  if(ok($set->isset(2) && $set->isset(3) && $set->isset(4), 'set 2 .. 4')) {

  SKIP: {

      skip "cpuset->next", 1 unless $apiVersion;

      subtest "set->next()" => sub {
	plan tests => 5;
	is($set->next(0), 2, "cpu234set->next(0)");
	is($set->next(1), 2, "cpu234set->next(1)");
	is($set->next(2), 3, "cpu234set->next(2)");
	is($set->next(3), 4, "cpu234set->next(3)");
	is($set->next(4), -1, "cpu234set->next(4)");
      };

    };
  } else {
    fail("set->next()");
  }

  # --
  # Check sprintf_list output and the reverse
  # --

SKIP: {

    skip "set->liststrings", 2 unless $apiVersion;

    $set->zero;
    $set->set_range(0,7);
    $set->set_range(16,17);
    $set->set_range(24,27);
    my $str = $set->sprintf_list;
    is($str, '0-7,16,17,24-27', 'set->sprintf_list');

    $set0->from_liststring($str);
    $rc = $set->isequal($set0);
    is($rc, 1, "set->from_liststring($str) eq '0-7,16,17,24-27'");

  };

  $set->free;
  $set0->free;
  $set1->destroy;

};
